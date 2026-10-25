// Isolated sampling and CoreAnimation text probe. Does not install a driver.
#import <AppKit/AppKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>
#import <objc/message.h>
#import <IOSurface/IOSurface.h>
#import <dlfcn.h>
#import <sys/mman.h>

static BOOL timedOut;
static BOOL finish(id<MTLCommandBuffer> command) {
    [command commit];
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:8];
    while(command.status<MTLCommandBufferStatusCompleted&&deadline.timeIntervalSinceNow>0)
        [NSThread sleepForTimeInterval:0.01];
    if(command.status<MTLCommandBufferStatusCompleted)timedOut=YES;
    return command.status==MTLCommandBufferStatusCompleted;
}
static NSArray *sample(id<MTLDevice>device,id<MTLCommandQueue>queue,id<MTLComputePipelineState>pipeline,id<MTLTexture>texture) {
    if(!texture||timedOut)return @[];
    id<MTLBuffer>out=[device newBufferWithLength:32*32*4 options:MTLResourceStorageModeShared];
    if(!out)return @[];memset(out.contents,0,32*32*4);
    id<MTLCommandBuffer>command=[queue commandBuffer];
    id<MTLComputeCommandEncoder>encoder=[command computeCommandEncoder];
    if(!command||!encoder)return @[];
    [encoder setComputePipelineState:pipeline];[encoder setTexture:texture atIndex:0];[encoder setBuffer:out offset:0 atIndex:0];
    [encoder dispatchThreads:MTLSizeMake(32,32,1) threadsPerThreadgroup:MTLSizeMake(8,8,1)];[encoder endEncoding];
    if(!finish(command))return @[];
    uint8_t*p=out.contents;NSMutableArray*points=[NSMutableArray array];
    for(unsigned index=0;index<3;index++){
        unsigned pixel=index==0?0:index==1?16*32+16:1023;
        [points addObject:@[@(p[4*pixel]),@(p[4*pixel+1]),@(p[4*pixel+2]),@(p[4*pixel+3])]];
    }
    return points;
}
static NSDictionary *textureResult(NSString*name,id<MTLDevice>device,id<MTLCommandQueue>queue,id<MTLComputePipelineState>read,id<MTLComputePipelineState>samplePS,id<MTLTexture>texture) {
    return @{ @"case":name,@"created":@(texture!=nil),@"read":sample(device,queue,read,texture),@"sample":sample(device,queue,samplePS,texture) };
}
static NSArray *surfaceProbe(id<MTLDevice>device,id<MTLCommandQueue>queue,id<MTLComputePipelineState>read,id<MTLComputePipelineState>samplePS) {
    NSMutableArray*results=[NSMutableArray array];
    const uint32_t codes[]={0x41303038,0x4c303038,0x4c413038,0x42475241};
    const MTLPixelFormat formats[]={MTLPixelFormatA8Unorm,MTLPixelFormatR8Unorm,MTLPixelFormatRG8Unorm,MTLPixelFormatBGRA8Unorm};
    for(unsigned f=0;f<4&&!timedOut;f++){
        unsigned bpp=f<2?1:f==2?2:4;
        IOSurfaceRef surface=IOSurfaceCreate((__bridge CFDictionaryRef)@{(id)kIOSurfaceWidth:@32,(id)kIOSurfaceHeight:@32,(id)kIOSurfaceBytesPerElement:@(bpp),(id)kIOSurfaceBytesPerRow:@128,(id)kIOSurfacePixelFormat:@(codes[f])});
        if(!surface){[results addObject:@{ @"case":[NSString stringWithFormat:@"IOSurface fmt=%lu",(unsigned long)formats[f]],@"error":@"IOSurfaceCreate failed" }];continue;}
        if(IOSurfaceLock(surface,0,NULL)!=kIOReturnSuccess){CFRelease(surface);continue;}
        uint8_t*p=IOSurfaceGetBaseAddress(surface);size_t pitch=IOSurfaceGetBytesPerRow(surface),length=IOSurfaceGetAllocSize(surface);
        if(!p||pitch<32*bpp||length<pitch*32){IOSurfaceUnlock(surface,0,NULL);CFRelease(surface);continue;}
        memset(p,0,length);
        for(unsigned y=0;y<32;y++)for(unsigned x=0;x<32;x++){
            uint8_t a=64+(x+y)%128;uint8_t*q=p+y*pitch+x*bpp;
            if(bpp==1)q[0]=a;else if(bpp==2){q[0]=255;q[1]=a;}else{q[0]=q[1]=q[2]=255;q[3]=a;}
        }
        IOSurfaceUnlock(surface,0,NULL);
        MTLTextureDescriptor*d=[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:formats[f] width:32 height:32 mipmapped:NO];d.storageMode=MTLStorageModeManaged;d.usage=MTLTextureUsageShaderRead;
        id<MTLTexture>native=[device newTextureWithDescriptor:d iosurface:surface plane:0];
        [results addObject:textureResult([NSString stringWithFormat:@"IOSurface fmt=%lu",(unsigned long)formats[f]],device,queue,read,samplePS,native)];
        // Same bytes via a buffer-backed linear texture isolates IOSurface cache/pageon.
        NSUInteger alignment=[device minimumLinearTextureAlignmentForPixelFormat:formats[f]];
        if(!timedOut&&alignment&&pitch%alignment==0&&length%4096==0&&((uintptr_t)p%4096)==0){
            id<MTLBuffer>buffer=[device newBufferWithBytesNoCopy:p length:length options:MTLResourceStorageModeShared deallocator:nil];
            d.storageMode=MTLStorageModeShared;
            id<MTLTexture>linear=buffer?[buffer newTextureWithDescriptor:d offset:0 bytesPerRow:pitch]:nil;
            [results addObject:textureResult([NSString stringWithFormat:@"IOSurface linear-buffer fmt=%lu",(unsigned long)formats[f]],device,queue,read,samplePS,linear)];
        }
        CFRelease(surface);
    }
    return results;
}
static CGImageRef rasterBadge(void) {
    CGColorSpaceRef cs=CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGContextRef c=CGBitmapContextCreate(NULL,96,96,8,96*4,cs,kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);CGColorSpaceRelease(cs);
    if(!c)return NULL;
    CGContextSetRGBFillColor(c,1,0,0,1);CGContextFillEllipseInRect(c,CGRectMake(8,8,80,80));
    CTFontRef font=CTFontCreateWithName(CFSTR("Helvetica-Bold"),32,NULL);CGColorRef white=CGColorCreateGenericRGB(1,1,1,1);
    NSAttributedString*string=[[NSAttributedString alloc]initWithString:@"12" attributes:@{(__bridge id)kCTFontAttributeName:(__bridge id)font,(__bridge id)kCTForegroundColorAttributeName:(__bridge id)white}];
    CTLineRef line=CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)string);
    CGContextSetTextPosition(c,28,34);CTLineDraw(line,c);
    CGImageRef image=CGBitmapContextCreateImage(c);CFRelease(line);CFRelease(font);CGColorRelease(white);CGContextRelease(c);return image;
}
static void unmapGlyph(void*info,const void*data,size_t size){munmap((void*)data,(size_t)info);}
static CGImageRef dockGlyphImage(void){
    const size_t width=52,height=40,pitch=256,length=12288;
    void*data=mmap(NULL,length,PROT_READ|PROT_WRITE,MAP_ANON|MAP_PRIVATE,-1,0);if(data==MAP_FAILED)return NULL;
    CGColorSpaceRef cs=CGColorSpaceCreateDeviceRGB();
    CGContextRef c=CGBitmapContextCreate(data,width,height,8,pitch,cs,0x2002);
    if(!c){CGColorSpaceRelease(cs);munmap(data,length);return NULL;}
    CTFontRef font=CTFontCreateWithName(CFSTR("Helvetica-Bold"),30,NULL);CGColorRef color=CGColorCreateGenericGray(1,1);
    NSAttributedString*string=[[NSAttributedString alloc]initWithString:@"12" attributes:@{(__bridge id)kCTFontAttributeName:(__bridge id)font,(__bridge id)kCTForegroundColorAttributeName:(__bridge id)color}];
    CTLineRef line=CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)string);CGContextSetTextPosition(c,8,8);CTLineDraw(line,c);
    CFRelease(line);CFRelease(font);CGColorRelease(color);CGContextRelease(c);
    mprotect(data,length,PROT_READ);CGDataProviderRef provider=CGDataProviderCreateWithData((void*)length,data,pitch*height,unmapGlyph);
    CGImageRef image=provider?CGImageCreate(width,height,8,32,pitch,cs,0x2002,provider,NULL,true,kCGRenderingIntentDefault):NULL;
    if(provider)CGDataProviderRelease(provider);else munmap(data,length);CGColorSpaceRelease(cs);return image;
}
static NSDictionary *caProbe(id<MTLDevice>device,id<MTLCommandQueue>queue,NSString*png) {
    MTLTextureDescriptor*d=[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:384 height:96 mipmapped:NO];
    d.storageMode=MTLStorageModeManaged;d.usage=MTLTextureUsageRenderTarget|MTLTextureUsageShaderRead;
    id<MTLTexture>target=[device newTextureWithDescriptor:d];if(!target)return @{ @"error":@"CA target creation failed" };
    CGColorSpaceRef cs=CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CARenderer*renderer=[CARenderer rendererWithMTLTexture:target options:@{kCARendererColorSpace:(__bridge id)cs,kCARendererMetalCommandQueue:queue}];CGColorSpaceRelease(cs);
    if(!renderer)return @{ @"error":@"CARenderer creation failed" };
    CALayer*root=[CALayer layer];root.frame=CGRectMake(0,0,384,96);
    CGImageRef image=rasterBadge();CALayer*reference=[CALayer layer];reference.frame=CGRectMake(0,0,96,96);reference.contents=(__bridge id)image;if(image)CGImageRelease(image);[root addSublayer:reference];
    CALayer*badge=[CALayer layer];badge.frame=CGRectMake(104,8,80,80);badge.cornerRadius=40;badge.backgroundColor=CGColorGetConstantColor(kCGColorWhite);
    CGColorRef red=CGColorCreateGenericRGB(1,0,0,1);badge.backgroundColor=red;CGColorRelease(red);[root addSublayer:badge];
    CATextLayer*text=[CATextLayer layer];text.frame=CGRectMake(96,23,96,48);text.string=@"12";text.font=(__bridge CFTypeRef)@"Helvetica-Bold";text.fontSize=32;text.alignmentMode=kCAAlignmentCenter;text.foregroundColor=CGColorGetConstantColor(kCGColorWhite);text.contentsScale=1;[root addSublayer:text];
    // Dock's _renderBadgeImage uses CTLineDraw into 8-bit DeviceRGB BGRA,
    // wraps read-only mmap data in CGImage, then sets a trilinear image layer.
    CGImageRef glyphImage=dockGlyphImage();
    for(unsigned cell=2;cell<4;cell++){
        CALayer*disk=[CALayer layer];disk.frame=CGRectMake(cell*96+8,8,80,80);disk.cornerRadius=40;
        CGColorRef color=CGColorCreateGenericRGB(1,0,0,1);disk.backgroundColor=color;CGColorRelease(color);[root addSublayer:disk];
        CALayer*glyph=[CALayer layer];glyph.frame=CGRectMake(cell*96+35,36,26,20);glyph.contents=(__bridge id)glyphImage;glyph.contentsGravity=kCAGravityResizeAspect;glyph.contentsScale=2;
        glyph.minificationFilter=cell==2?kCAFilterLinear:kCAFilterTrilinear;glyph.minificationFilterBias=-0.5;[root addSublayer:glyph];
    }
    if(glyphImage)CGImageRelease(glyphImage);
    renderer.layer=root;renderer.bounds=root.frame;[CATransaction flush];
    [renderer beginFrameAtTime:CACurrentMediaTime() timeStamp:NULL];[renderer addUpdateRect:root.frame];[renderer render];[renderer endFrame];
    id<MTLCommandBuffer>command=[queue commandBuffer];id<MTLBlitCommandEncoder>blit=[command blitCommandEncoder];[blit synchronizeResource:target];[blit endEncoding];
    if(!finish(command))return @{ @"error":@"CA readback command failed or timed out" };
    NSMutableData*data=[NSMutableData dataWithLength:384*96*4];[target getBytes:data.mutableBytes bytesPerRow:384*4 fromRegion:MTLRegionMake2D(0,0,384,96) mipmapLevel:0];
    uint8_t*p=data.mutableBytes;unsigned white[4]={0},redCount[4]={0};
    for(unsigned y=0;y<96;y++)for(unsigned x=0;x<384;x++){
        uint8_t*q=p+(y*384+x)*4;unsigned cell=x/96;
        if(q[0]>200&&q[1]>200&&q[2]>200&&q[3]>200)white[cell]++;
        if(q[2]>180&&q[1]<80&&q[0]<80&&q[3]>180)redCount[cell]++;
    }
    NSBitmapImageRep*rep=[[NSBitmapImageRep alloc]initWithBitmapDataPlanes:NULL pixelsWide:384 pixelsHigh:96 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:384*4 bitsPerPixel:32];
    for(unsigned i=0;i<384*96;i++){rep.bitmapData[4*i]=p[4*i+2];rep.bitmapData[4*i+1]=p[4*i+1];rep.bitmapData[4*i+2]=p[4*i];rep.bitmapData[4*i+3]=p[4*i+3];}
    BOOL saved=[[rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}]writeToFile:png atomically:YES];
    return @{ @"CPU_raster_then_CA":@{ @"white_pixels":@(white[0]),@"red_pixels":@(redCount[0]) },@"CATextLayer":@{ @"white_pixels":@(white[1]),@"red_pixels":@(redCount[1]) },@"Dock_BGRA_linear":@{ @"white_pixels":@(white[2]),@"red_pixels":@(redCount[2]) },@"Dock_BGRA_trilinear":@{ @"white_pixels":@(white[3]),@"red_pixels":@(redCount[3]) },@"png":saved?png:@"not saved" };
}
int main(int argc,const char**argv){@autoreleasepool{
    NSString*output=argc>1?@(argv[1]):[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/gen5_igpu_driver/reports/dock-investigation/probe-user.json"];
    [[NSFileManager defaultManager]createDirectoryAtPath:output.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil];
    NSMutableDictionary*report=[@{ @"purpose":@"Isolated alpha sampling and CoreAnimation number rendering; not a driver installation",@"date":[NSDate.date description],@"pid":@(getpid()),@"probe_version":@3 } mutableCopy];
    id<MTLDevice>device=MTLCreateSystemDefaultDevice();report[@"device"]=device.name?:@"none accessible";
    if(device){
        NSString*observer=[NSHomeDirectory()stringByAppendingPathComponent:@"Documents/gen5_igpu_driver/build/p1-badge-observer.dylib"];
        void*trace=dlopen(observer.fileSystemRepresentation,RTLD_NOW|RTLD_LOCAL);report[@"nocopy_metadata_trace_loaded"]=@(trace!=NULL);
        id<MTLCommandQueue>queue=[device newCommandQueue];NSError*error=nil;
        NSString*source=@"#include <metal_stdlib>\nusing namespace metal;\n"
        "kernel void probe_read(texture2d<half,access::read> t[[texture(0)]],device uchar4*o[[buffer(0)]],uint2 g[[thread_position_in_grid]]){o[g.y*32+g.x]=uchar4(t.read(g)*255.0h+0.5h);}\n"
        "kernel void probe_sample(texture2d<half> t[[texture(0)]],device uchar4*o[[buffer(0)]],uint2 g[[thread_position_in_grid]]){constexpr sampler s(coord::normalized,address::clamp_to_edge,filter::nearest);o[g.y*32+g.x]=uchar4(t.sample(s,(float2(g)+0.5)/32.0)*255.0h+0.5h);}";
        id<MTLLibrary>library=[device newLibraryWithSource:source options:nil error:&error];
        id<MTLComputePipelineState>read=library?[device newComputePipelineStateWithFunction:[library newFunctionWithName:@"probe_read"] error:&error]:nil;
        id<MTLComputePipelineState>samplePS=library?[device newComputePipelineStateWithFunction:[library newFunctionWithName:@"probe_sample"] error:&error]:nil;
        if(!read||!samplePS)report[@"shader_error"]=error.localizedDescription?:@"pipeline unavailable";
        else{
            NSMutableArray*results=[NSMutableArray array];NSMutableArray*views=[NSMutableArray array];MTLPixelFormat formats[]={MTLPixelFormatA8Unorm,MTLPixelFormatR8Unorm,MTLPixelFormatRG8Unorm,MTLPixelFormatRGBA8Unorm,MTLPixelFormatBGRA8Unorm};
            for(unsigned f=0;f<5&&!timedOut;f++){
                unsigned bpp=f<2?1:f==2?2:4;NSMutableData*bytes=[NSMutableData dataWithLength:4096];uint8_t*p=bytes.mutableBytes;
                for(unsigned y=0;y<32;y++)for(unsigned x=0;x<32;x++){
                    uint8_t a=64+(x+y)%128;uint8_t*q=p+y*128+x*bpp;
                    if(bpp==1)q[0]=a;else if(bpp==2){q[0]=255;q[1]=a;}else{q[0]=q[1]=q[2]=255;q[3]=a;}
                }
                MTLTextureDescriptor*d=[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:formats[f] width:32 height:32 mipmapped:NO];d.storageMode=MTLStorageModeManaged;d.usage=MTLTextureUsageShaderRead|MTLTextureUsagePixelFormatView;
                id<MTLTexture>t=[device newTextureWithDescriptor:d];if(t)[t replaceRegion:MTLRegionMake2D(0,0,32,32) mipmapLevel:0 withBytes:p bytesPerRow:128];
                [results addObject:@{ @"format":@(formats[f]),@"created":@(t!=nil),@"read":sample(device,queue,read,t),@"sample":sample(device,queue,samplePS,t),@"input_alpha_or_channel":@[@64,@96,@126] }];
                if(t&&!timedOut){
                    MTLTextureSwizzle channel=f==0?MTLTextureSwizzleAlpha:f==2?MTLTextureSwizzleGreen:MTLTextureSwizzleRed;
                    MTLTextureSwizzleChannels sw=MTLTextureSwizzleChannelsMake(channel,channel,channel,channel);
                    id<MTLTexture>view=[t newTextureViewWithPixelFormat:formats[f] textureType:MTLTextureType2D levels:NSMakeRange(0,1) slices:NSMakeRange(0,1) swizzle:sw];
                    [views addObject:textureResult([NSString stringWithFormat:@"view fmt=%lu repeat-channel=%u",(unsigned long)formats[f],channel],device,queue,read,samplePS,view)];
                    d.swizzle=sw;
                    id<MTLTexture>direct=[device newTextureWithDescriptor:d];if(direct)[direct replaceRegion:MTLRegionMake2D(0,0,32,32) mipmapLevel:0 withBytes:p bytesPerRow:128];
                    [views addObject:textureResult([NSString stringWithFormat:@"descriptor-swizzle fmt=%lu repeat-channel=%u",(unsigned long)formats[f],channel],device,queue,read,samplePS,direct)];
                }
            }
            report[@"sampling"]=results;report[@"views"]=views;
            if(!timedOut)report[@"iosurface"]=surfaceProbe(device,queue,read,samplePS);
            if(!timedOut)report[@"core_animation"]=caProbe(device,queue,[[output stringByDeletingPathExtension]stringByAppendingPathExtension:@"png"]);
        }
        report[@"gpu_timed_out"]=@(timedOut);
    }else report[@"next_action"]=@"Run scripts/probe-dock.command in your ordinary Terminal login session to access the GPU.";
    NSData*json=[NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted error:nil];BOOL saved=[json writeToFile:output atomically:YES];
    fwrite(json.bytes,1,json.length,stdout);puts("");printf("Report: %s\n",output.fileSystemRepresentation);
    return saved&&device&&!timedOut?0:3;
}}
