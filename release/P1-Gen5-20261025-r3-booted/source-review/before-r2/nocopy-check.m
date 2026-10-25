#define XE_OFFLINE_AUDIT 1
#include "../vendor/iris-xe/macos/src/libxedrv.m"
#include <assert.h>
#include <sys/mman.h>

@interface CopyTexture:NSObject
@property(nonatomic,retain) NSData *pixels;
@end
@implementation CopyTexture
- (void)replaceRegion:(MTLRegion)r mipmapLevel:(NSUInteger)m withBytes:(void*)p bytesPerRow:(NSUInteger)b {
  self.pixels=[NSData dataWithBytes:p length:(r.size.height-1)*b+r.size.width];
}
- (void)dealloc { [_pixels release];[super dealloc]; }
@end
@interface FakeDevice:NSObject
@property(nonatomic) BOOL failCopy;
@property(nonatomic) BOOL throwCopy;
@end
@implementation FakeDevice
- (id)newTextureWithDescriptor:(id)d {
  if(self.throwCopy) @throw [NSException exceptionWithName:@"AuditCopy" reason:@"copy failure" userInfo:nil];
  return self.failCopy?nil:[CopyTexture new];
}
@end
static BOOL failNative,callbackNow,throwNative;
static unsigned nativeCalls;
static void (^lateCallback)(void*,NSUInteger);
static id native4(id s,SEL c,void*p,NSUInteger len,id releaseBlock,id d,NSUInteger off,NSUInteger bpr) {
  nativeCalls++;
  [lateCallback release];lateCallback=[releaseBlock copy];
  if(callbackNow&&releaseBlock) ((void(^)(void*,NSUInteger))releaseBlock)(p,len);
  if(throwNative) @throw [NSException exceptionWithName:@"Audit" reason:@"native failure" userInfo:nil];
  if(failNative)return nil;
  CopyTexture*t=[CopyTexture new];
  if(releaseBlock) {
    XeDeallocV15*h=[[XeDeallocV15 alloc]initWithBlock:releaseBlock ptr:p len:len];
    objc_setAssociatedObject(t,kNcDealloc,h,OBJC_ASSOCIATION_RETAIN);[h release];
  }
  return t;
}
static id native3(id s,SEL c,void*p,NSUInteger len,id d,NSUInteger off,NSUInteger bpr) {
  return failNative?nil:[CopyTexture new];
}
int main(){@autoreleasepool{
  FakeDevice*dev=[FakeDevice new];
  MTLTextureDescriptor*d=[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatA8Unorm width:32 height:127 mipmapped:NO];
  d.usage=MTLTextureUsageShaderRead;d.storageMode=MTLStorageModeShared;
  uint8_t*bytes=mmap(NULL,8192,PROT_READ|PROT_WRITE,MAP_ANON|MAP_PRIVATE,-1,0);
  assert(bytes!=MAP_FAILED&&mprotect(bytes+4096,4096,PROT_NONE)==0);
  memset(bytes,0x7f,4096);
  __block unsigned released=0;
  void(^cleanup)(void*,NSUInteger)=^(void*p,NSUInteger n){released++;mprotect(bytes,4096,PROT_NONE);};
  g_nc4=(IMP)native4;
  // Successful offset-zero native texture must not become a private snapshot.
  failNative=NO;callbackNow=NO;
  id native=w_nc4(dev,NULL,bytes,4096,cleanup,d,0,32);
  assert(native&&nativeCalls==1&&released==0&&[(CopyTexture*)native pixels]==nil);
  [native release];assert(released==1);
  mprotect(bytes,4096,PROT_READ|PROT_WRITE);
  // A synchronous native failure callback must not free bytes before fallback copies them.
  failNative=YES;callbackNow=YES;released=0;
  CopyTexture*t=w_nc4(dev,NULL,bytes,4096,cleanup,d,0,32);
  assert(t&&t.pixels.length==4064&&released==0);
  [t release];assert(released==1);
  lateCallback(bytes,4096);assert(released==1); // No double deallocation.
  mprotect(bytes,4096,PROT_READ|PROT_WRITE);
  dev.failCopy=YES;released=0;
  assert(!w_nc4(dev,NULL,bytes,4096,cleanup,d,0,32)&&released==1);
  mprotect(bytes,4096,PROT_READ|PROT_WRITE);
  callbackNow=NO;released=0;
  assert(!w_nc4(dev,NULL,bytes,4096,cleanup,d,0,32)&&released==0); // Caller still owns failure input.
  dev.failCopy=NO;
  assert(!w_nc4(dev,NULL,bytes,4096,cleanup,d,0,32)&&released==0); // Unknown native ownership: do not guess.
  dev.failCopy=NO;nativeCalls=0;
  t=w_nc4(dev,NULL,bytes,4096,cleanup,d,32,32);
  assert(t&&nativeCalls==0&&released==0);[t release];assert(released==1);
  [lateCallback release];lateCallback=nil;
  mprotect(bytes,4096,PROT_READ|PROT_WRITE);
  released=0;callbackNow=YES;throwNative=YES;
  BOOL caught=NO;
  @try { w_nc4(dev,NULL,bytes,4096,cleanup,d,0,32); }
  @catch(id error) { caught=YES; }
  assert(caught&&released==1);
  throwNative=NO;mprotect(bytes,4096,PROT_READ|PROT_WRITE);
  released=0;dev.throwCopy=YES;caught=NO;
  @try { w_nc4(dev,NULL,bytes,4096,cleanup,d,0,32); }
  @catch(id error) { caught=YES; }
  assert(caught&&released==1);
  dev.throwCopy=NO;mprotect(bytes,4096,PROT_READ|PROT_WRITE);
  g_nc3=(IMP)native3;failNative=YES;
  t=w_nc3(dev,NULL,bytes,4096,d,0,32);assert(t&&t.pixels.length==4064);[t release];
  failNative=NO;t=w_nc3(dev,NULL,bytes,4096,d,0,32);assert(t&&t.pixels==nil);[t release];
  [lateCallback release];lateCallback=nil;
  munmap(bytes,8192);[dev release];
  puts("PASS: both NoCopy signatures, aligned native preservation, offset-zero failure recovery, callbacks, ownership, exceptions and legacy unaligned copy; CPU only.");
}}
