# Makefile used to build libraries

TARGETS = all clean
.PHONY: $(TARGETS)

CXX=g++
CC=gcc
LD=g++
STRIP=strip
#CXXFLAGS= -O2 -fpic
CXXFLAGS= -O1 -fpic
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

INCLUDE_DIRS = -I/usr/local/include -I/usr/include/lua5.1
LIB_DIR = /usr/local/lib

LIBNAME= NaoCam

all: camera

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDE_DIRS) $(BOOST) -o $@ -c $<
%.o: %.cc
	$(CXX) $(CXXFLAGS) $(INCLUDE_DIRS) $(BOOST) -o $@ -c $<
%.o: %.c
	$(CC) $(CXXFLAGS) $(INCLUDE_DIRS) -o $@ -c $<

camera: naoCam.o naoCamThread.o timeScalar.o i2cBus.o
	$(LD) $(LDFLAGS) $(BOOST) -o $(LIBNAME).$(SHLIBEXT) $(LIBOPTS) $^ -L$(LIB_DIR) -lm 

clean:
	rm -f *.$(SHLIBEXT) *.o
