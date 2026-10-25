// Metadata-only trace installed inside the isolated probe process, never Dock/WindowServer.
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <objc/runtime.h>
static IMP original3,original4;
static void trace(MTLTextureDescriptor*d,NSUInteger offset,NSUInteger pitch,NSUInteger length){
 fprintf(stderr,"P1_BADGE_NOCOPY fmt=%lu size=%lux%lu mips=%lu usage=0x%lx offset=%lu pitch=%lu length=%lu\n",(unsigned long)d.pixelFormat,(unsigned long)d.width,(unsigned long)d.height,(unsigned long)d.mipmapLevelCount,(unsigned long)d.usage,(unsigned long)offset,(unsigned long)pitch,(unsigned long)length);
}
static id wrap3(id s,SEL c,void*p,NSUInteger n,id d,NSUInteger o,NSUInteger b){trace(d,o,b,n);return ((id(*)(id,SEL,void*,NSUInteger,id,NSUInteger,NSUInteger))original3)(s,c,p,n,d,o,b);}
static id wrap4(id s,SEL c,void*p,NSUInteger n,id release,id d,NSUInteger o,NSUInteger b){trace(d,o,b,n);return ((id(*)(id,SEL,void*,NSUInteger,id,id,NSUInteger,NSUInteger))original4)(s,c,p,n,release,d,o,b);}
__attribute__((constructor))static void setup(void){
 Class cls=objc_getClass("MTLIOAccelDevice");Method a=class_getInstanceMethod(cls,sel_registerName("newTiledTextureWithBytesNoCopy:length:descriptor:offset:bytesPerRow:"));Method b=class_getInstanceMethod(cls,sel_registerName("newTiledTextureWithBytesNoCopy:length:deallocator:descriptor:offset:bytesPerRow:"));
 if(a)original3=method_setImplementation(a,(IMP)wrap3);if(b)original4=method_setImplementation(b,(IMP)wrap4);
}
