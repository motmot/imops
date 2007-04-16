cdef extern from "numpy/arrayobject.h":
    ctypedef int* intp
    ctypedef class numpy.ndarray [object PyArrayObject]:
        cdef char *data
        cdef int nd
        cdef intp *dimensions
        cdef intp *strides
        cdef object base
        # descr not implemented yet here...
        cdef int flags
        cdef int itemsize
        cdef object weakreflist

    cdef void import_array()
    cdef int PyArray_ISCONTIGUOUS(ndarray)
    cdef int PyArray_ISWRITEABLE(ndarray)
    cdef int PyArray_ISALIGNED(ndarray)
