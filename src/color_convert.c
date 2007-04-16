#include "color_convert.h"

#define CLIP(m)					\
  (m)<0?0:((m)>255?255:(m))

RGB888_t YUV444toRGB888(unsigned char Y, unsigned char U, unsigned char V) {
  // from http://en.wikipedia.org/wiki/YUV
  RGB888_t result;
  int C,D,E;

  C = Y - 16;
  D = U - 128;
  E = V - 128;

  result.R = CLIP(( 298 * C           + 409 * E + 128) >> 8);
  result.G = CLIP(( 298 * C - 100 * D - 208 * E + 128) >> 8);
  result.B = CLIP(( 298 * C + 516 * D           + 128) >> 8);
  
  return result;
}

void mono16_buf_to_mono8_buf(u_int16_t *mono16_buf, u_int8_t *mono8_buf, int len) {
  int i;
  u_int16_t *mono16_ptr;
  u_int8_t *mono8_ptr;
  
  mono16_ptr = mono16_buf;
  mono8_ptr = mono8_buf;
  for (i=0; i<len; i++) {
    *mono8_ptr = (*mono16_ptr) >> 4;
    mono8_ptr++;
    mono16_ptr++;
  }
}
