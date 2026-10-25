#ifndef XE_IMAGE_SPAN_H
#define XE_IMAGE_SPAN_H
#include <stdint.h>

// Exact accessible pixel footprint, excluding optional padding after the last row.
// All arguments use bytes/pixels, never GGTT page counts.
static inline int xe_image_span(uint64_t width, uint64_t height, uint64_t bpp,
                                uint64_t stride, uint64_t offset, uint64_t length,
                                uint64_t *actual_stride, uint64_t *span) {
  if (!width || !height || !bpp || offset > length || width > UINT64_MAX / bpp)
    return 0;
  const uint64_t row = width * bpp;
  if (!stride) stride = row;
  if (stride < row || height - 1 > (UINT64_MAX - row) / stride)
    return 0;
  const uint64_t size = (height - 1) * stride + row;
  if (size > length - offset) return 0;
  if (actual_stride) *actual_stride = stride;
  if (span) *span = size;
  return 1;
}
#endif
