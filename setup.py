import sys, os
from setuptools import setup, Extension, find_packages
from Cython.Build import cythonize
from os import path
from io import open

import numpy

# read the contents of README.md
this_directory = path.abspath(path.dirname(__file__))
with open(path.join(this_directory, "README.md"), encoding="utf-8") as f:
    long_description = f.read()

setup(
    name="motmot.imops",
    description="image format conversion (e.g. between MONO8, YUV422, and RGB)",
    long_description=long_description,
    long_description_content_type="text/markdown",
    version="0.5.10",
    license="BSD",
    maintainer="Andrew Straw",
    maintainer_email="strawman@astraw.com",
    url="http://code.astraw.com/projects/motmot/imops.html",
    packages=["motmot", "motmot.imops"],
    namespace_packages=["motmot"],
    ext_modules=cythonize(
        [
            Extension(
                name="motmot.imops.imops",
                sources=["src/imops.pyx", "src/color_convert.c",],
                include_dirs=[numpy.get_include()],
            ),
        ]
    ),
)
