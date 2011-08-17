from distutils.core import setup, Extension

module1 = Extension('vcm',
                    include_dirs = ['/usr/local/include/boost'],
                    libraries = ['rt'],
                    sources = ['vcm.cpp'])

setup (name = 'vcm',
       version = '1.0',
       description = 'This is a demo package',
       ext_modules = [module1])

