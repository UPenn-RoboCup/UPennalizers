# Makefile used to build Webots files
#include ../../Makefile.inc

TARGETS = all clean
.PHONY: $(TARGETS)

CXX=g++
CC=gcc
LD=ld
STRIP=strip
CXXFLAGS= -O1 -fpic

SHLIBEXT= so
LIBOPTS= -shared -fpic 

ifndef OSTYPE
  OSTYPE = $(shell uname -s|awk '{print tolower($$0)}')
  #export OSTYPE
endif

ifeq ($(OSTYPE),linux)
  SHLIBEXT= so
  LIBOPTS= -shared -fpic
  LIBRT= -lrt
  LIBLNK = -lboost_python
  LIBNAME= -Wl,-soname,"lib$@.$(SHLIBEXT)"
endif
ifeq ($(OSTYPE),darwin)
  SHLIBEXT= dylib
  LIBOPTS= -bundle -undefined dynamic_lookup
  LIBNAME= -Wl,-install_name,"lib$@.$(SHLIBEXT)"
  LIBLNK=-lboost_python-mt
  ifeq ($(MODE),32)
    CC=gcc -arch i386
    CXX=g++ -arch i386
    LD=g++ -arch i386
  endif
  CXXFLAGS= -O2
  LIBRT=
endif

# http://stackoverflow.com/questions/4933285/how-to-detemine-python-version-in-makefile
python_version_full := $(wordlist 2,4,$(subst ., ,$(shell python --version 2>&1)))
python_version_major := $(word 1,${python_version_full})
python_version_minor := $(word 2,${python_version_full})

PYTHON_INC=-I/usr/include/python${python_version_major}.${python_version_minor} -I/usr/local/include/python${python_version_major}.${python_version_minor}

BOOST_INCLUDE_DIRS = -I/usr/local/include/boost -I/usr/local/include/boost/python
INCLUDE_DIRS = -I/usr/local/include $(PYTHON_INC) $(BOOST_INCLUDE_DIRS)
LIB_DIRS = -L/usr/local/lib

all: pyshm 

%.o: %.cc
	$(CXX) $(CXXFLAGS) $(INCLUDE_DIRS) -o $@ -c $<
%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDE_DIRS) -o $@ -c $<
%.o: %.c
	$(CC) $(CXXFLAGS) $(INCLUDE_DIRS) -o $@ -c $<

pyshm: pyshm.o
	$(CXX) $(LIBNAME) $(LIBOPTS) $^ $(LIBRT) $(LIBLNK) -o $@.$(SHLIBEXT)

libMonitor.py: libMonitor.i
	swig -python libMonitor.i

clean:
	rm -f *.o *.$(SHLIBEXT) 
