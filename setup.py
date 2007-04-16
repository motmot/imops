import sys
from setuptools import setup, Extension

from motmot_utils import get_svnversion_persistent
version_str = '0.3.dev%(svnversion)s'
version = get_svnversion_persistent('imops_version.py',version_str)

import numpy

setup(name="imops",
      version=version,
      license="BSD",
      maintainer="Andrew Straw",
      maintainer_email="strawman@astraw.com",
      py_modules=['imops_version'],
      ext_modules=[Extension(name="imops",
                             sources=['src/imops.pyx','src/color_convert.c',],
                             include_dirs=[numpy.get_include()],
                             ),
                   ],
      zip_safe = True,
     )
