import sys, os
from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

cmdclass = {}
cmdclass['build_ext'] = build_ext

import numpy

setup(name="motmot.imops",
      description="image format conversion (e.g. between MONO8, YUV422, and RGB)",
      long_description = """
This is a subpackage of the motmot family of digital image utilities.
""",
      version="0.5.8",
      license="BSD",
      maintainer="Andrew Straw",
      maintainer_email="strawman@astraw.com",
      url="http://code.astraw.com/projects/motmot/imops.html",
      packages = ['motmot','motmot.imops'],
      namespace_packages = ['motmot'],
      ext_modules=[Extension(name="motmot.imops.imops",
                             sources=['src/imops.pyx','src/color_convert.c',],
                             include_dirs=[numpy.get_include()],
                             ),
                   ],
      cmdclass=cmdclass,
      )
