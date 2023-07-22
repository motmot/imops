from setuptools import setup, Extension
from Cython.Build import cythonize
import numpy

######################################################################

setup(
    ext_modules=cythonize([Extension(
                name="motmot.imops.imops",
                sources=["src/imops.pyx", "src/color_convert.c",],
                include_dirs=[numpy.get_include()],
            ),]),
)
