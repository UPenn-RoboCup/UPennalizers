# Makefile used to build Webots files

TARGETS = all clean
.PHONY: $(TARGETS)

CXX=g++
CC=gcc
LD=ld
STRIP=strip
CXXFLAGS= -O2 -fpic

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
endif
ifeq ($(OSTYPE),darwin)
  SHLIBEXT= dylib
  LIBOPTS= -bundle -undefined dynamic_lookup
ifeq ($(MODE),32)
  CC=gcc -arch i386
  CXX=g++ -arch i386
  LD=g++ -arch i386
endif
  CXXFLAGS= -O2
  LIBRT=
endif

BOOST_HOME = /usr/local/boost

INCLUDES = -I/usr/local/include -I/usr/include/lua5.1
LIB_DIR = /usr/local/lib

all: unix stty getch

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $@ -c $<
%.o: %.c
	$(CC) $(CXXFLAGS) $(INCLUDES) -o $@ -c $<

unix: luaunix.o
	$(CC) -o $@.$(SHLIBEXT) $(LIBOPTS) $^

stty: luastty.o
	$(CXX) -o $@.$(SHLIBEXT) $(LIBOPTS) $^

getch: getch.o
	$(CXX) -o $@.$(SHLIBEXT) $(LIBOPTS) $^

serial: luaserial.o
	$(CC) -o $@.$(SHLIBEXT) $(LIBOPTS) $^

clean:
	rm -f *.o *.$(SHLIBEXT)
