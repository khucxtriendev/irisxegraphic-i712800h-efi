// Small optional compute/readback check. Does not test all Metal or video paths.
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include <math.h>

int main(void) { @autoreleasepool {
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device) { fprintf(stderr, "No accessible Metal device in this session.\n"); return 3; }
    printf("Metal device: %s\n", device.name.UTF8String);
    NSError *error = nil;
    NSString *code = @"#include <metal_stdlib>\nusing namespace metal;\n"
        "kernel void twice(device float *v [[buffer(0)]], uint i [[thread_position_in_grid]]) { v[i] = v[i] * 2.0f; }";
    id<MTLLibrary> library = [device newLibraryWithSource:code options:nil error:&error];
    if (!library) { fprintf(stderr, "Shader compilation: %s\n", error.localizedDescription.UTF8String); return 1; }
    id<MTLFunction> function = [library newFunctionWithName:@"twice"];
    id<MTLComputePipelineState> pipeline = [device newComputePipelineStateWithFunction:function error:&error];
    id<MTLCommandQueue> queue = [device newCommandQueue];
    id<MTLBuffer> buffer = [device newBufferWithLength:256*sizeof(float) options:MTLResourceStorageModeShared];
    if (!pipeline || !queue || !buffer) { fputs("Cannot create Metal resources.\n", stderr); return 1; }
    float *values = buffer.contents;
    for (unsigned i=0; i<256; i++) values[i] = (float)i;
    id<MTLCommandBuffer> command = [queue commandBuffer];
    id<MTLComputeCommandEncoder> encoder = [command computeCommandEncoder];
    if (!command || !encoder) { fputs("Cannot create Metal encoder.\n", stderr); return 1; }
    [encoder setComputePipelineState:pipeline];
    [encoder setBuffer:buffer offset:0 atIndex:0];
    NSUInteger width = MIN((NSUInteger)64, pipeline.maxTotalThreadsPerThreadgroup);
    [encoder dispatchThreads:MTLSizeMake(256,1,1) threadsPerThreadgroup:MTLSizeMake(width,1,1)];
    [encoder endEncoding];
    [command commit];
    // Bounded userspace wait: a stuck experimental driver is reported rather than waited on forever.
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:10];
    while (command.status < MTLCommandBufferStatusCompleted && [deadline timeIntervalSinceNow] > 0)
        [NSThread sleepForTimeInterval:0.02];
    if (command.status != MTLCommandBufferStatusCompleted) {
        fprintf(stderr, "Metal did not complete successfully (status %lu).\n", (unsigned long)command.status); return 1;
    }
    for (unsigned i=0; i<256; i++) if (fabsf(values[i]-2.0f*i)>0.001f) {
        fprintf(stderr, "Readback mismatch at %u.\n", i); return 1;
    }
    puts("PASS: shader compile, compute dispatch and 256-value GPU readback.");
    return 0;
} }
