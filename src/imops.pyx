#emacs, this is -*-Python-*- mode
import numpy
cimport c_python
cimport c_numpy

cdef extern from "color_convert.h":
    ctypedef unsigned short u_int16_t
    ctypedef unsigned char u_int8_t
    ctypedef struct RGB888_t:
        unsigned char R
        unsigned char G
        unsigned char B
    cdef RGB888_t YUV444toRGB888(unsigned char Y, unsigned char U, unsigned char V)
    cdef void mono16_buf_to_mono8_buf(u_int16_t *mono16_buf,
                                      u_int8_t *mono8_buf,
                                      int len)
    
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
    """use array interface to share data but possibly reshape array"""
    rgb8 = numpy.asarray(arr) # view of data (if possible)
    s = rgb8.shape
    if len(s) == 2:
      height = s[0]
      width = s[1]/3
      rgb8.shape = ( height, width, 3)
      return rgb8
    else: return rgb8

def argb8_to_rgb8(arr,skip_check=False):
    """use array interface to share data but possibly reshape array"""
    argb8 = numpy.asarray(arr) # view of data (if possible)
    height,datawidth=arr.shape
    width=datawidth/4
    argb8.shape = ( height, width, 4)
    rgb8 = numpy.array(argb8[:,:,1:],copy=True) # make contiguous
    return rgb8

def mono8_to_rgb8(arr,skip_check=False):
    cdef int i,j,k,height,width
    cdef char *rgb8_data_ptr, *mono8_data_ptr, *mono8_row_ptr
    cdef c_numpy.ndarray rgb8    
    cdef PyArrayInterface* inter
    cdef int do_check

    do_check = not skip_check

    attr = arr.__array_struct__
    if not c_python.PyCObject_Check(attr):
        raise ValueError("invalid __array_struct__")

    if do_check:
        inter = <PyArrayInterface*>c_python.PyCObject_AsVoidPtr(attr)
        if inter.version != 2:
            raise ValueError("invalid __array_struct__")

        # TODO: don't really know what these flags all mean, figure out if
        # this is OK:
        if (inter.flags & (ALIGNED | WRITEABLE)) != (ALIGNED | WRITEABLE):
            raise ValueError("cannot handle misaligned or not writeable arrays.")

        if inter.nd != 2:
            raise ValueError("only 2D arrays are accepted (currently) mono8")

        if not (inter.typekind == "u"[0] and inter.itemsize==1):
            raise TypeError("must be uint8 arrays")

    height = inter.shape[0]
    width = inter.shape[1]
    
    rgb8 = numpy.zeros(( height, width, 3), numpy.uint8)

    rgb8_data_ptr = rgb8.data # we know rgb8 is contiguous
    c_python.Py_BEGIN_ALLOW_THREADS
    for i from 0<=i<height:
        mono8_row_ptr = <char*>inter.data + i*inter.strides[0]
        mono8_data_ptr = mono8_row_ptr
        for j from 0<=j<width:
            for k from 0<=k<3:
                rgb8_data_ptr[0] = mono8_data_ptr[0]
                rgb8_data_ptr=rgb8_data_ptr+1
            mono8_data_ptr = mono8_data_ptr + inter.strides[1]
    c_python.Py_END_ALLOW_THREADS
                
    return rgb8

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

    c_python.Py_BEGIN_ALLOW_THREADS
    mono16_buf_to_mono8_buf( <u_int16_t *>mono16.data, <u_int8_t *>mono8.data, height*width )
    c_python.Py_END_ALLOW_THREADS
    
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
    height, width_in_bytes = yuv422.shape
    width = int(width_in_bytes/bytes_per_pixel)

    mono8 = numpy.zeros(( height, width), numpy.uint8)
    
    c_python.Py_BEGIN_ALLOW_THREADS
    for pixpair from 0 <= pixpair < height*width_in_bytes/4:
        baseptr = <unsigned char*>(yuv422.data + pixpair*4)
        u = baseptr[0]
        y1 = baseptr[1]
        v = baseptr[2]
        y2 = baseptr[3]

        baseptr = <unsigned char*>(mono8.data + pixpair*2)
        
        baseptr[0] = y1
        baseptr[1] = y2

    c_python.Py_END_ALLOW_THREADS
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
    height, width_in_bytes = yuv422.shape
    width = int(width_in_bytes/bytes_per_pixel)

    rgb8 = numpy.zeros(( height, width, 3), numpy.uint8)
    
    c_python.Py_BEGIN_ALLOW_THREADS
    for pixpair from 0 <= pixpair < height*width_in_bytes/4:
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
        
    c_python.Py_END_ALLOW_THREADS
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
    
    c_python.Py_BEGIN_ALLOW_THREADS
    for pixpair from 0 <= pixpair < height*width_in_bytes/6:
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
        
    c_python.Py_END_ALLOW_THREADS
    return rgb8

def to_rgb8(format,image):
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
    else:
        raise ValueError('unsupported conversion from format "%s" to RGB8'%format)
    return rgb8

def to_mono8(format,image):
    image = numpy.array(image) # cast as numpy
    if format == 'MONO8':
        mono8 = image
    elif format == 'MONO16':
        mono8 = mono16_to_mono8_middle8bits( image )
    elif format == 'YUV422':
         mono8 = yuv422_to_mono8(image)
    else:
        raise ValueError('unsupported conversion from format "%s" to RGB8'%format)
    return mono8
