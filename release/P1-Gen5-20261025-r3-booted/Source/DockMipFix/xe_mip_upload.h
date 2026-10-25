// NoCopy image mip repair, following upstream libxedrv v19 / issue #10:
// https://github.com/JulioNectar/Hackintosh-XPS13Plus-IrisXe-Tahoe/commit/125f089fcc90520cd5565dee19f26c968f3d5c59
// CoreAnimation supplies only level 0 even when its image descriptor requests
// a full chain. Populate that chain before returning a managed snapshot.
static BOOL nc_mip_eligible(MTLTextureDescriptor *d) {
  if(!d||getenv("XE_MIP_NATIVO")||d.mipmapLevelCount<=1||
     d.textureType!=MTLTextureType2D||d.arrayLength!=1||d.depth!=1||d.sampleCount!=1||
     !d.width||!d.height||(d.usage&(MTLTextureUsageShaderWrite|MTLTextureUsageRenderTarget)))return NO;
  switch(d.pixelFormat) {
    case MTLPixelFormatA8Unorm:case MTLPixelFormatR8Unorm:case MTLPixelFormatRG8Unorm:
    case MTLPixelFormatRGBA8Unorm:case MTLPixelFormatRGBA8Unorm_sRGB:
    case MTLPixelFormatBGRA8Unorm:case MTLPixelFormatBGRA8Unorm_sRGB:break;
    default:return NO;
  }
  NSUInteger maximum=MAX(d.width,d.height),levels=1;
  while(maximum>1){maximum>>=1;levels++;}
  return d.mipmapLevelCount<=levels;
}
static const void *kXeMipQueue=&kXeMipQueue;
static pthread_mutex_t g_xe_mip_queue_lock=PTHREAD_MUTEX_INITIALIZER;
static long g_xe_mip_count;
static BOOL nc_generate_mips(id dev,id<MTLTexture>texture,MTLTextureDescriptor*d) {
  if(d.mipmapLevelCount<=1)return YES;
  if(!nc_mip_eligible(d)||!texture)return NO;
  pthread_mutex_lock(&g_xe_mip_queue_lock);
  id<MTLCommandQueue>queue=nil;
  @try {
    queue=objc_getAssociatedObject(dev,kXeMipQueue);
    if(!queue){
      queue=[dev newCommandQueue];
      if(queue){objc_setAssociatedObject(dev,kXeMipQueue,queue,OBJC_ASSOCIATION_RETAIN);[queue release];}
    }
  }@finally{pthread_mutex_unlock(&g_xe_mip_queue_lock);}
  id<MTLCommandBuffer>command=[queue commandBuffer];
  id<MTLBlitCommandEncoder>encoder=[command blitCommandEncoder];
  if(!command||!encoder)return NO;
  [encoder generateMipmapsForTexture:texture];[encoder endEncoding];[command commit];
  // A failed/hung command must not be returned as a repaired texture.
  NSTimeInterval deadline=[NSDate timeIntervalSinceReferenceDate]+8.0;
  while(command.status<MTLCommandBufferStatusCompleted&&[NSDate timeIntervalSinceReferenceDate]<deadline)usleep(1000);
  if(command.status!=MTLCommandBufferStatusCompleted){
    LOG("P1-MIP failed fmt=%lu %lux%lu levels=%lu status=%lu",(unsigned long)d.pixelFormat,
        (unsigned long)d.width,(unsigned long)d.height,(unsigned long)d.mipmapLevelCount,(unsigned long)command.status);
    return NO;
  }
  long n=__sync_add_and_fetch(&g_xe_mip_count,1);
  if(n<=8||(n&(n-1))==0)LOG("P1-MIP repaired fmt=%lu %lux%lu levels=%lu n=%ld",(unsigned long)d.pixelFormat,
      (unsigned long)d.width,(unsigned long)d.height,(unsigned long)d.mipmapLevelCount,n);
  return YES;
}
