#emacs, this is -*-Python-*- mode
# cython: language_level=2
"""manipulate image codings"""
cimport cython
cimport numpy as np
import numpy
import numpy as np
import warnings
cimport c_python
cimport c_numpy

cdef extern from "color_convert.h":
    ctypedef unsigned short u_int16_t
    ctypedef unsigned char u_int8_t
    ctypedef struct RGB888_t:
        unsigned char R
        unsigned char G
        unsigned char B
    ctypedef struct YUV444_t:
        unsigned char Y
        unsigned char U
        unsigned char V
    cdef RGB888_t YUV444toRGB888(unsigned char Y, unsigned char U, unsigned char V) nogil
    cdef YUV444_t RGB888toYUV444(unsigned char r, unsigned char g, unsigned char b) nogil
    cdef void mono16_buf_to_mono8_buf(u_int16_t *mono16_buf,
                                      u_int8_t *mono8_buf,
                                      int len) nogil

# for PyArrayInterface
cdef int CONTIGUOUS
cdef int FORTRAN
cdef int ALIGNED
cdef int NOTSWAPPED
cdef int WRITEABLE

CONTIGUOUS= 0x01
FORTRAN= 0x02
ALIGNED= 0x100
NOTSWAPPED= 0x200
WRITEABLE= 0x400

ctypedef struct PyArrayInterface:
    int version                   # contains the integer 2 as a sanity check
    int nd                        # number of dimensions
    char typekind                 # kind in array --- character code of typestr
    int itemsize                  # size of each element
    int flags                     # flags indicating how the data should be interpreted
    c_python.Py_intptr_t *shape   # A length-nd array of shape information
    c_python.Py_intptr_t *strides # A length-nd array of stride information
    void *data                    # A pointer to the first element of the array

def rgb8_to_rgb8(arr,skip_check=False):
    rgb8 = numpy.asarray(arr) # view of data (if possible)
    s = rgb8.shape
    if len(s) == 2:
      height = s[0]
      width = s[1]//3
      rgb8.shape = ( height, width, 3)
      return rgb8
    else: return rgb8

def rgb32f_to_rgb8(arr,skip_check=False):
    rgb8f = numpy.array(arr)
    rgb8 = rgb8f.astype(np.uint8)
    s = rgb8.shape
    if len(s) == 2:
      height = s[0]
      width = s[1]//3
      rgb8.shape = ( height, width, 3)
      return rgb8
    else: return rgb8

def argb8_to_rgb8(arr,skip_check=False):
    argb8 = numpy.asarray(arr) # view of data (if possible)
    height,datawidth=arr.shape
    width=datawidth//4
    argb8.shape = ( height, width, 4)
    rgb8 = numpy.array(argb8[:,:,1:],copy=True) # make contiguous
    return rgb8

@cython.boundscheck(False)
def mono8_to_rgb8(const np.uint8_t[:, :] arr,skip_check=False):
    # convert to rgb8 by repeating each grayscale value for R,G,B
    cdef size_t i,j,k,height,width
    cdef int do_check

    do_check = not skip_check

    if do_check:
        if arr.ndim != 2:
            raise ValueError("only 2D arrays are accepted (currently) mono8")

    height = arr.shape[0]
    width = arr.shape[1]

    rgb8_np = np.zeros((height,width,3), dtype=np.uint8)
    cdef np.uint8_t[:, :,:] rgb8 = rgb8_np

    with nogil:
        for i in range(height):
            for j in range(width):
                for k in range(3):
                    rgb8[i,j,k] = arr[i,j]
    return rgb8_np

def mono8_bayer_bggr_to_rgb8( arr ):
    # This is a super-crappy conversion I just hacked together.
    cdef int i,j,k,height,width
    cdef char *rgb8_data_ptr
    cdef char *mono8_data_ptr
    cdef char *mono8_row_ptr
    cdef char cur_red, cur_green, cur_blue
    cdef c_numpy.ndarray rgb8
    cdef int do_check

    height, width = arr.shape
    rgb8 = numpy.zeros(( height, width, 3), numpy.uint8)

    r_rows = np.arange(1,height,2)
    r_cols = np.arange(1,width,2)
    R_rows,R_cols = np.meshgrid(r_rows,r_cols)
    bggr_r_pattern = R_rows.ravel(), R_cols.ravel()

    g0_rows = np.arange(0,height,2)
    g0_cols = np.arange(1,width,2)
    G0_rows,G0_cols = np.meshgrid(g0_rows,g0_cols)
    bggr_g0_pattern = G0_rows.ravel(), G0_cols.ravel()

    g1_rows = np.arange(1,height,2)
    g1_cols = np.arange(0,width,2)
    G1_rows,G1_cols = np.meshgrid(g1_rows,g1_cols)
    bggr_g1_pattern = G1_rows.ravel(), G1_cols.ravel()

    b_rows = np.arange(0,height,2)
    b_cols = np.arange(0,width,2)
    B_rows,B_cols = np.meshgrid(b_rows,b_cols)
    bggr_b_pattern = B_rows.ravel(), B_cols.ravel()

    transposed_shape = width//2,height//2 # integer division
    r_data = arr[bggr_r_pattern]
    r_data.shape = transposed_shape
    r_data = r_data.T
    g0_data = arr[bggr_g0_pattern]
    g0_data.shape = transposed_shape
    g0_data = g0_data.T
    g1_data = arr[bggr_g1_pattern]
    g1_data.shape = transposed_shape
    g1_data = g1_data.T
    b_data = arr[bggr_b_pattern]
    b_data.shape = transposed_shape
    b_data = b_data.T

    rgb8[:,:,2] = r_data.repeat(2,axis=0).repeat(2,axis=1)
    rgb8[0::2,:,1] = g0_data.repeat(2,axis=1)
    rgb8[1::2,:,1] = g1_data.repeat(2,axis=1)
    rgb8[:,:,0] = b_data.repeat(2,axis=0).repeat(2,axis=1)

    return rgb8

def mono32f_bayer_bggr_to_rgb8( arr ):
    # convert to uint8 and convert
    arr = np.array(arr).astype(np.uint8)
    return mono8_bayer_bggr_to_rgb8( arr )

def mono32f_to_mono8( arr ):
    # convert to uint8
    arr = np.array(arr).astype(np.uint8)
    return arr

def mono16_to_mono8_middle8bits(c_numpy.ndarray mono16):
    cdef int height, width, width_in_bytes
    cdef int pixpair
    cdef c_numpy.ndarray mono8

    depth=16 # MONO16
    bytes_per_pixel = depth/8.0
    if not (c_numpy.PyArray_ISCONTIGUOUS(mono16) and c_numpy.PyArray_ISALIGNED(mono16)):
        raise ValueError("input to mono16_to_mono8_middle8bits must be contiguous, aligned, and not byteswapped")
    if not len(mono16.shape)==2:
        raise ValueError("input to mono16_to_mono8_middle8bits must be 2D array")
    height, width_in_bytes = mono16.shape
    width = int(width_in_bytes/bytes_per_pixel)
    mono8 = numpy.zeros(( height, width), numpy.uint8)

    with nogil:
        mono16_buf_to_mono8_buf( <u_int16_t *>mono16.data, <u_int8_t *>mono8.data, height*width )

    return mono8

def yuv422_to_mono8(c_numpy.ndarray yuv422):
    cdef unsigned char u, v, y1, y2
    cdef unsigned char *baseptr
    cdef int pixpair
    cdef int height, width, width_in_bytes
    cdef c_numpy.ndarray mono8

    depth=16 # YUV422
    bytes_per_pixel = depth/8.0

    if not (c_numpy.PyArray_ISCONTIGUOUS(yuv422) and c_numpy.PyArray_ISALIGNED(yuv422)):
        raise ValueError("input to yuv422_to_rgb8 must be contiguous, aligned, and not byteswapped")
    if not len(yuv422.shape)==2:
        raise ValueError("input to yuv422_to_mono8 must be 2D array")
    if yuv422.dtype == np.uint8:
        height, width_in_bytes = yuv422.shape
    elif yuv422.dtype == np.uint16:
        height = yuv422.shape[0]
        width_in_bytes = yuv422.shape[1]*2
    else:
        raise ValueError('unsupported dtype for image')
    width = int(width_in_bytes/bytes_per_pixel)

    mono8 = numpy.zeros(( height, width), numpy.uint8)

    with nogil:
        for pixpair from 0 <= pixpair < height*width_in_bytes//4:
            baseptr = <unsigned char*>(yuv422.data + pixpair*4)
            u = baseptr[0]
            y1 = baseptr[1]
            v = baseptr[2]
            y2 = baseptr[3]

            baseptr = <unsigned char*>(mono8.data + pixpair*2)

            baseptr[0] = y1
            baseptr[1] = y2

    return mono8

def yuv422_to_rgb8(c_numpy.ndarray yuv422):
    cdef unsigned char u, v, y1, y2
    cdef unsigned char *baseptr
    cdef int pixpair
    cdef int height, width, width_in_bytes
    cdef c_numpy.ndarray rgb8
    cdef RGB888_t tmp_rgb1, tmp_rgb2

    depth=16 # YUV422
    bytes_per_pixel = depth/8.0

    if not (c_numpy.PyArray_ISCONTIGUOUS(yuv422) and c_numpy.PyArray_ISALIGNED(yuv422)):
        raise ValueError("input to yuv422_to_rgb8 must be contiguous, aligned, and not byteswapped")
    if not len(yuv422.shape)==2:
        raise ValueError("input to yuv422_to_rgb8 must be 2D array")
    if yuv422.dtype == np.uint8:
        height, width_in_bytes = yuv422.shape
    elif yuv422.dtype == np.uint16:
        height = yuv422.shape[0]
        width_in_bytes = yuv422.shape[1]*2
    else:
        raise ValueError('unsupported dtype for image')
    width = int(width_in_bytes/bytes_per_pixel)

    rgb8 = numpy.zeros(( height, width, 3), numpy.uint8)

    with nogil:
        for pixpair from 0 <= pixpair < height*width_in_bytes//4:
            baseptr = <unsigned char*>(yuv422.data + pixpair*4)
            u = baseptr[0]
            y1 = baseptr[1]
            v = baseptr[2]
            y2 = baseptr[3]

            tmp_rgb1 = YUV444toRGB888(y1,u,v)
            tmp_rgb2 = YUV444toRGB888(y2,u,v)

            baseptr = <unsigned char*>(rgb8.data + pixpair*6)

            baseptr[0] = tmp_rgb1.R
            baseptr[1] = tmp_rgb1.G
            baseptr[2] = tmp_rgb1.B

            baseptr[3] = tmp_rgb2.R
            baseptr[4] = tmp_rgb2.G
            baseptr[5] = tmp_rgb2.B

    return rgb8

def yuv411_to_rgb8(c_numpy.ndarray yuv411):
    cdef unsigned char u, v, y1, y2, y3, y4
    cdef unsigned char *baseptr
    cdef int pixpair
    cdef int height, width, width_in_bytes
    cdef c_numpy.ndarray rgb8
    cdef RGB888_t tmp_rgb1, tmp_rgb2, tmp_rgb3, tmp_rgb4

    depth=12 # YUV411
    bytes_per_pixel = depth/8.0

    if not (c_numpy.PyArray_ISCONTIGUOUS(yuv411) and c_numpy.PyArray_ISALIGNED(yuv411)):
        raise ValueError("input to yuv411_to_rgb8 must be contiguous, aligned, and not byteswapped")
    if not len(yuv411.shape)==2:
        raise ValueError("input to yuv411_to_rgb8 must be 2D array")
    height, width_in_bytes = yuv411.shape
    width = int(width_in_bytes/bytes_per_pixel)
    rgb8 = numpy.zeros(( height, width, 3), numpy.uint8)
    if width!=640:
        raise RuntimeError('expected width 640')

    with nogil:
        for pixpair from 0 <= pixpair < height*width_in_bytes//6:
            baseptr = <unsigned char*>(yuv411.data + pixpair*6)
            u = baseptr[0]
            y1 = baseptr[1]
            y2 = baseptr[2]
            v = baseptr[3]
            y3 = baseptr[4]
            y4 = baseptr[5]

            tmp_rgb1 = YUV444toRGB888(y1,u,v)
            tmp_rgb2 = YUV444toRGB888(y2,u,v)
            tmp_rgb3 = YUV444toRGB888(y3,u,v)
            tmp_rgb4 = YUV444toRGB888(y4,u,v)

            baseptr = <unsigned char*>(rgb8.data + pixpair*12)

            baseptr[0] = tmp_rgb1.R
            baseptr[1] = tmp_rgb1.G
            baseptr[2] = tmp_rgb1.B

            baseptr[3] = tmp_rgb2.R
            baseptr[4] = tmp_rgb2.G
            baseptr[5] = tmp_rgb2.B

            baseptr[6] = tmp_rgb3.R
            baseptr[7] = tmp_rgb3.G
            baseptr[8] = tmp_rgb3.B

            baseptr[9] = tmp_rgb4.R
            baseptr[10] = tmp_rgb4.G
            baseptr[11] = tmp_rgb4.B

    return rgb8

def to_rgb8(format,image):
    """convert image to RGB8 encoding

    Arguments

    format : string
      a string specifying the input format (e.g. 'MONO8','YUV422', etc.)
    image : array-like
      the raw image data in the format specified

    Returns

    rgb8 : array-like
      the image data in RGB8 encoding
    """
    image = numpy.array(image) # cast as numpy
    if format == 'RGB8':
        rgb8 = rgb8_to_rgb8( image )
    elif format == 'ARGB8':
        rgb8 = argb8_to_rgb8( image )
    elif format == 'YUV411':
        rgb8 = yuv411_to_rgb8( image )
    elif format == 'YUV422':
        rgb8 = yuv422_to_rgb8( image )
    elif format == 'MONO8':
        rgb8 = mono8_to_rgb8( image )
    elif format == 'MONO16':
        mono8 = mono16_to_mono8_middle8bits( image )
        rgb8 = mono8_to_rgb8( mono8 )
    elif format == 'MONO8:BGGR' or format == 'RAW8:BGGR':
        rgb8 = mono8_bayer_bggr_to_rgb8( image )
    elif format == 'MONO32f:BGGR':
        rgb8 = mono32f_bayer_bggr_to_rgb8( image )
    elif format.startswith('MONO8:') or format.startswith('RAW8:'):
        warnings.warn('converting Bayer mosaic to grayscale')
        rgb8 = mono8_to_rgb8( image )
    elif format == 'RGB32f':
        rgb8 = rgb32f_to_rgb8( image )
    elif format == 'MONO32f':
        mono8 = mono32f_to_mono8( image )
        rgb8 = mono8_to_rgb8( mono8 )
    else:
        raise ValueError('unsupported conversion from format "%s" to RGB8'%format)
    return rgb8

def to_mono8(format,image,fast_but_inaccurate=False):
    """convert image to MONO8 encoding

    Arguments

    format : string
      a string specifying the input format (e.g. 'MONO8','YUV422', etc.)
    image : array-like
      the raw image data in the format specified

    Returns

    mono8 : array-like
      the image data in MONO8 encoding
    """
    image = numpy.array(image) # cast as numpy
    if format == 'MONO8':
        mono8 = image
    elif format.startswith('MONO8:') or format.startswith('RAW8:'):
        if fast_but_inaccurate:
            warnings.warn('converting Bayer mosaic to grayscale')
            mono8 = image
        else:
            rgb8 = to_rgb8(format,image)
            mono8 = np.mean(rgb8,axis=2).astype(np.uint8)
    elif format == 'MONO16':
        mono8 = mono16_to_mono8_middle8bits( image )
    elif format == 'YUV422':
         mono8 = yuv422_to_mono8(image)
    elif format == 'MONO32f':
        mono8 = mono32f_to_mono8( image )
    else:
        raise ValueError('unsupported conversion from format "%s" to MONO8'%format)
    return mono8

def is_coding_color(coding):
    """return whether a coding represents a color image"""
    if (coding.startswith('MONO8:') or
        coding.startswith('RAW8:') or
        coding.startswith('YUV') or
        coding.startswith('RGB')):
        return True
    else:
        return False

def auto_convert(format, image):
    """return a 2d array if image is monochrome, a 3d array if color"""
    if is_coding_color(format):
        return to_rgb8(format,image)
    else:
        return to_mono8(format,image)
