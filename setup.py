import sys, os
from setuptools import setup, Extension, find_packages
from Cython.Build import cythonize

import numpy

setup(name="motmot.imops",
      description="image format conversion (e.g. between MONO8, YUV422, and RGB)",
      long_description = """
This is a subpackage of the motmot family of digital image utilities.
""",
      version="0.5.9",
      license="BSD",
      maintainer="Andrew Straw",
      maintainer_email="strawman@astraw.com",
      url="http://code.astraw.com/projects/motmot/imops.html",
      packages = ['motmot','motmot.imops'],
      namespace_packages = ['motmot'],
      ext_modules=cythonize([Extension(name="motmot.imops.imops",
                             sources=['src/imops.pyx','src/color_convert.c',],
                             include_dirs=[numpy.get_include()],
                             ),
                   ]),
      )
