typedef struct 
{
  unsigned char R;
  unsigned char G;
  unsigned char B;
}
RGB888_t;

typedef struct 
{
  unsigned char Y;
  unsigned char U;
  unsigned char V;
}
YUV444_t;

extern RGB888_t YUV444toRGB888(unsigned char Y, unsigned char U, unsigned char V);
extern YUV444_t RGB888toYUV444(unsigned char r, unsigned char g, unsigned char b);


#ifdef _WIN32
#define u_int8_t unsigned char
#define u_int16_t unsigned short
#else
#include <sys/types.h>
#endif

extern void mono16_buf_to_mono8_buf(u_int16_t *mono16_buf, u_int8_t *mono8_buf, int len);
