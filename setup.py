import sys
from setuptools import setup, Extension, find_packages

import numpy

setup(name="motmot.imops",
      description="image format conversion for the motmot camera packages",
      version="0.5.2",
      license="BSD",
      maintainer="Andrew Straw",
      maintainer_email="strawman@astraw.com",
      url="http://code.astraw.com/projects/motmot",
      packages = find_packages(),
      namespace_packages = ['motmot'],
      install_requires = ['numpy>=1.0.4'],
      ext_modules=[Extension(name="motmot.imops.imops",
                             sources=['src/imops.pyx','src/color_convert.c',],
                             include_dirs=[numpy.get_include()],
                             ),
                   ],
      zip_safe = True,
     )
