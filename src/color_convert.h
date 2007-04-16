typedef struct 
{
  unsigned char R;
  unsigned char G;
  unsigned char B;
}
RGB888_t;

extern RGB888_t YUV444toRGB888(unsigned char Y, unsigned char U, unsigned char V);



#ifdef _WIN32
#define u_int8_t unsigned char
#define u_int16_t unsigned short
#else
#include <sys/types.h>
#endif

extern void mono16_buf_to_mono8_buf(u_int16_t *mono16_buf, u_int8_t *mono8_buf, int len);
