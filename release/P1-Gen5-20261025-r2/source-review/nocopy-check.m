#define XE_OFFLINE_AUDIT 1
#include "../vendor/iris-xe/macos/src/libxedrv.m"
#include <assert.h>
#include <sys/mman.h>

static unsigned liveCopies;
@interface CopyTexture:NSObject
@property(nonatomic,retain) NSData *pixels;
@property(nonatomic) NSUInteger pixelBytes;
@property(nonatomic) BOOL throwUpload;
@end
@implementation CopyTexture
- (id)init { if((self=[super init]))liveCopies++;return self; }
- (void)replaceRegion:(MTLRegion)r mipmapLevel:(NSUInteger)m withBytes:(void*)p bytesPerRow:(NSUInteger)b {
  if(self.throwUpload)@throw [NSException exceptionWithName:@"Upload" reason:@"upload failure" userInfo:nil];
  self.pixels=[NSData dataWithBytes:p length:(r.size.height-1)*b+r.size.width*self.pixelBytes];
}
- (void)dealloc { liveCopies--;[_pixels release];[super dealloc]; }
@end
@interface FakeDevice:NSObject
@property(nonatomic) BOOL failCopy;
@property(nonatomic) unsigned failCopies;
@property(nonatomic) BOOL throwCopy;
@property(nonatomic) BOOL throwUpload;
@property(nonatomic) unsigned copyCalls;
@end
@implementation FakeDevice
- (id)newTextureWithDescriptor:(MTLTextureDescriptor*)d {
  self.copyCalls++;
  assert(d.storageMode==MTLStorageModeManaged);
  if(self.throwCopy)@throw [NSException exceptionWithName:@"Copy" reason:@"allocation failure" userInfo:nil];
  if(self.failCopy)return nil;
  if(self.failCopies){self.failCopies--;return nil;}
  CopyTexture*t=[CopyTexture new];t.pixelBytes=nc_pixel_size(d.pixelFormat);t.throwUpload=self.throwUpload;return t;
}
@end
static BOOL failNative,callbackNow,throwNative;
static unsigned nativeCalls;
static void (^lateCallback)(void*,NSUInteger);
static id native4(id s,SEL c,void*p,NSUInteger len,id releaseBlock,id d,NSUInteger off,NSUInteger bpr) {
  nativeCalls++;[lateCallback release];lateCallback=[releaseBlock copy];
  if(callbackNow&&releaseBlock)((void(^)(void*,NSUInteger))releaseBlock)(p,len);
  if(throwNative)@throw [NSException exceptionWithName:@"Native" reason:@"native failure" userInfo:nil];
  if(failNative)return nil;
  CopyTexture*t=[CopyTexture new];
  if(releaseBlock){XeDeallocV15*h=[[XeDeallocV15 alloc]initWithBlock:releaseBlock ptr:p len:len];objc_setAssociatedObject(t,kNcDealloc,h,OBJC_ASSOCIATION_RETAIN);[h release];}
  return t;
}
static id native3(id s,SEL c,void*p,NSUInteger len,id d,NSUInteger off,NSUInteger bpr) {
  nativeCalls++;return failNative?nil:[CopyTexture new];
}
int main(){@autoreleasepool{
  FakeDevice*dev=[FakeDevice new];g_nc4=(IMP)native4;g_nc3=(IMP)native3;
  MTLTextureDescriptor*d=[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatA8Unorm width:32 height:127 mipmapped:NO];
  d.usage=MTLTextureUsageShaderRead;d.storageMode=MTLStorageModeShared;
  uint8_t*bytes=mmap(NULL,8192,PROT_READ|PROT_WRITE,MAP_ANON|MAP_PRIVATE,-1,0);
  assert(bytes!=MAP_FAILED&&mprotect(bytes+4096,4096,PROT_NONE)==0);memset(bytes,0x7f,4096);
  __block unsigned released=0;
  void(^cleanup)(void*,NSUInteger)=^(void*p,NSUInteger n){assert(p==bytes&&n==4096);released++;mprotect(bytes,4096,PROT_NONE);};
  // Native is valid but has no pixels in the mock: proactive upload must bypass it.
  for(unsigned off=0;off<=32;off+=32){
    nativeCalls=0;released=0;failNative=NO;callbackNow=NO;
    CopyTexture*t=w_nc4(dev,NULL,bytes,4096,cleanup,d,off,32);
    assert(t&&nativeCalls==0&&released==0&&t.pixels.length==4064);
    assert(((const uint8_t*)t.pixels.bytes)[0]==0x7f);
    bytes[off]=0x55;assert(((const uint8_t*)t.pixels.bytes)[0]==0x7f); // Explicit snapshot semantics.
    [t release];assert(released==1);mprotect(bytes,4096,PROT_READ|PROT_WRITE);memset(bytes,0x7f,4096);
  }
  nativeCalls=0;CopyTexture*t=w_nc3(dev,NULL,bytes,4096,d,0,32);
  assert(t&&nativeCalls==0&&t.pixels.length==4064);[t release];
  // Known GPU-writable and render-target resources must preserve the native path.
  for(NSUInteger usage=MTLTextureUsageShaderWrite;usage<=MTLTextureUsageRenderTarget;usage<<=1){
    d.usage=usage;nativeCalls=0;unsigned copies=dev.copyCalls;released=0;
    t=w_nc4(dev,NULL,bytes,4096,cleanup,d,0,32);
    assert(t&&nativeCalls==1&&dev.copyCalls==copies&&t.pixels==nil);[t release];assert(released==1);
    mprotect(bytes,4096,PROT_READ|PROT_WRITE);
    nativeCalls=0;t=w_nc3(dev,NULL,bytes,4096,d,0,32);assert(t&&nativeCalls==1&&dev.copyCalls==copies);[t release];
  }
  d.usage=MTLTextureUsageShaderRead;
  // Copy unavailable: retain valid native objects and their callback semantics.
  dev.failCopy=YES;nativeCalls=0;released=0;
  t=w_nc4(dev,NULL,bytes,4096,cleanup,d,0,32);
  assert(t&&nativeCalls==1&&t.pixels==nil&&released==0);[t release];assert(released==1);
  mprotect(bytes,4096,PROT_READ|PROT_WRITE);
  failNative=YES;callbackNow=YES;released=0;
  assert(!w_nc4(dev,NULL,bytes,4096,cleanup,d,0,32)&&released==1);
  lateCallback(bytes,4096);assert(released==1);
  mprotect(bytes,4096,PROT_READ|PROT_WRITE);
  callbackNow=NO;released=0;
  assert(!w_nc4(dev,NULL,bytes,4096,cleanup,d,0,32)&&released==0);
  // First allocation fails, native then fails and requests release synchronously;
  // the second managed allocation recovers without reading freed source memory.
  dev.failCopy=NO;dev.failCopies=1;callbackNow=YES;released=0;
  t=w_nc4(dev,NULL,bytes,4096,cleanup,d,0,32);assert(t&&released==0&&t.pixels.length==4064);
  [t release];assert(released==1);lateCallback(bytes,4096);assert(released==1);
  mprotect(bytes,4096,PROT_READ|PROT_WRITE);
  // A native exception after a failed proactive allocation releases exactly once.
  dev.failCopy=YES;throwNative=YES;released=0;BOOL caught=NO;
  @try{w_nc4(dev,NULL,bytes,4096,cleanup,d,0,32);}@catch(id error){caught=YES;}
  assert(caught&&released==1);throwNative=NO;dev.failCopy=NO;
  mprotect(bytes,4096,PROT_READ|PROT_WRITE);
  // Exceptions before ownership transfer leave the caller's buffer intact.
  for(unsigned upload=0;upload<2;upload++){
    released=0;caught=NO;dev.throwCopy=!upload;dev.throwUpload=upload;unsigned before=liveCopies;
    @try{w_nc4(dev,NULL,bytes,4096,cleanup,d,0,32);}@catch(id error){caught=YES;}
    assert(caught&&released==0&&liveCopies==before);
    dev.throwCopy=NO;dev.throwUpload=NO;
  }
  assert(!nc_copia(dev,bytes,4096,d,33,32)); // End of image would cross guard page.
  assert(!nc_copia(dev,bytes,4096,d,0,31)); // Row pitch too short.
  d.pixelFormat=MTLPixelFormatBC1_RGBA;assert(!nc_copia(dev,bytes,4096,d,0,32));
  [lateCallback release];lateCallback=nil;munmap(bytes,8192);[dev release];assert(liveCopies==0);
  puts("PASS: proactive managed image upload at zero/aligned/unaligned offsets; both NoCopy signatures; writable/native fallback; bounds, callbacks and exceptions. CPU only; no visual Dock validation.");
}}
