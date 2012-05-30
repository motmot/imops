import sys, os
from setuptools import setup, Extension, find_packages

import numpy

kws = {}

setup(name="motmot.imops",
      description="image format conversion (e.g. between MONO8, YUV422, and RGB)",
      long_description = """
This is a subpackage of the motmot family of digital image utilities.
""",
      version="0.5.7",
      license="BSD",
      maintainer="Andrew Straw",
      maintainer_email="strawman@astraw.com",
      url="http://code.astraw.com/projects/motmot/imops.html",
      packages = find_packages(),
      namespace_packages = ['motmot'],
      ext_modules=[Extension(name="motmot.imops.imops",
                             sources=['src/imops.c','src/color_convert.c',],
                             include_dirs=[numpy.get_include()],
                             ),
                   ],
      zip_safe = True,
      **kws)
