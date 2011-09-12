# Makefile used to build libraries

TARGETS = all clean
.PHONY: $(TARGETS)

CXX=g++
CC=gcc
LD=g++
STRIP=strip
CXXFLAGS= -O2 -fpic
#CXXFLAGS= -O3 -funroll-loops -fpic
#-mtune=atom
LDFLAGS=

SHLIBEXT= so
LIBOPTS= -shared
BOOST= -lrt -I/usr/local/include/boost

ifndef OSTYPE
  OSTYPE = $(shell uname -s|awk '{print tolower($$0)}')
  #export OSTYPE
endif

ifeq ($(OSTYPE),linux)
  SHLIBEXT= so
  LIBOPTS= -shared
endif
ifeq ($(OSTYPE),darwin)
  SHLIBEXT= dylib
  LIBOPTS= -bundle -undefined dynamic_lookup
  CXXFLAGS= -O2 -arch i386
  LDFLAGS= -arch i386
endif

INCLUDE_DIR = -I/usr/local/include -I/usr/include -I/usr/include/lua
LIB_DIR = /usr/local/lib -L/usr/lib

LIBNAME= darwinCam

ifeq ($(OSTYPE),darwin)
all:
endif

ifeq ($(OSTYPE),linux)
all: camera
endif


%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDE_DIR) -o $@ -c $<
%.o: %.cc
	$(CXX) $(CXXFLAGS) $(INCLUDE_DIR) -o $@ -c $<
%.o: %.c
	$(CC) $(CXXFLAGS) $(INCLUDE_DIR) -o $@ -c $<

camera: timeScalar.o darwinCam.o v4l2.o
	$(LD) $(LDFLAGS) -o $(LIBNAME).$(SHLIBEXT) $(LIBOPTS) $^ -L$(LIB_DIR) -lm $(BOOST)

clean:
	rm -f *.$(SHLIBEXT) *.o
