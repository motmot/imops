#include "color_convert.h"
#include <stdlib.h>

#define CLIP(m)					\
  (m)<0?0:((m)>255?255:(m))
#define min(x,y)				\
  (x)<(y)?x:y

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

YUV444_t RGB888toYUV444(unsigned char r, unsigned char g, unsigned char b) {
  // from http://en.wikipedia.org/wiki/YUV
  YUV444_t result;
  result.Y = min(abs(r * 2104 + g * 4130 + b * 802 + 4096 + 131072) >> 13, 235);
  result.U = min(abs(r * -1214 + g * -2384 + b * 3598 + 4096 + 1048576) >> 13, 240);
  result.V = min(abs(r * 3598 + g * -3013 + b * -585 + 4096 + 1048576) >> 13, 240) ;
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
