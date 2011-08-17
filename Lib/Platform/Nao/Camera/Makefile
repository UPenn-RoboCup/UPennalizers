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

INCLUDE_DIR = /usr/local/include 
LIB_DIR = /usr/local/lib

LIBNAME= NaoCam

all: camera

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -I$(INCLUDE_DIR) $(BOOST) -o $@ -c $<
%.o: %.cc
	$(CXX) $(CXXFLAGS) -I$(INCLUDE_DIR) $(BOOST) -o $@ -c $<
%.o: %.c
	$(CC) $(CXXFLAGS) -I$(INCLUDE_DIR) -o $@ -c $<

camera: naoCam.o naoCamThread.o timeScalar.o i2cBus.o
	$(LD) $(LDFLAGS) $(BOOST) -o $(LIBNAME).$(SHLIBEXT) $(LIBOPTS) $^ -L$(LIB_DIR) -lm 

clean:
	rm -f *.$(SHLIBEXT) *.o
