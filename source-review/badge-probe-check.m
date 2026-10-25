#define main probeEntryPoint
#include "../src/p1-badge-probe.m"
#undef main
int main(void){@autoreleasepool{
  CGImageRef image=rasterBadge();assert(image);
  CFDataRef bytes=CGDataProviderCopyData(CGImageGetDataProvider(image));assert(bytes);
  const uint8_t*p=CFDataGetBytePtr(bytes);size_t stride=CGImageGetBytesPerRow(image);unsigned white=0,red=0;
  for(unsigned y=0;y<96;y++)for(unsigned x=0;x<96;x++){
    const uint8_t*q=p+y*stride+x*4;
    if(q[0]>200&&q[1]>200&&q[2]>200&&q[3]>200)white++;
    if(q[0]>180&&q[1]<80&&q[2]<80&&q[3]>180)red++;
  }
  assert(white>100&&red>1000);
  NSBitmapImageRep*rep=[[NSBitmapImageRep alloc]initWithCGImage:image];
  [[rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}]writeToFile:@"reports/dock-investigation/cpu-reference.png" atomically:YES];
  printf("PASS: independent CPU badge control contains white digits (%u white pixels, %u red pixels). No GPU access.\n",white,red);
  CFRelease(bytes);CGImageRelease(image);return 0;
}}
