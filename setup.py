import sys
from setuptools import setup, Extension

import numpy

setup(name="imops",
      description="image format conversion for the motmot camera packages",
      version="0.5.1",
      license="BSD",
      maintainer="Andrew Straw",
      maintainer_email="strawman@astraw.com",
      url="http://code.astraw.com/projects/motmot",
      ext_modules=[Extension(name="imops",
                             sources=['src/imops.pyx','src/color_convert.c',],
                             include_dirs=[numpy.get_include()],
                             ),
                   ],
      zip_safe = True,
     )
