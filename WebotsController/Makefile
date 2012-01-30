# Makefile used to build Webots files

TARGETS = all clean
.PHONY: $(TARGETS)

CXX=g++
CC=gcc
LD=ld
STRIP=strip
CXXFLAGS= -O2 -fpic

WEBOTS_HOME= /usr/local/webots
SHLIBEXT= so
LIBOPTS= -shared -fpic

ifndef OSTYPE
  OSTYPE = $(shell uname -s|awk '{print tolower($$0)}')
  #export OSTYPE
endif

ifeq ($(OSTYPE),linux)
  SHLIBEXT= so
  LIBOPTS= -shared -fpic
endif
ifeq ($(OSTYPE),darwin)
  WEBOTS_HOME= /Applications/Webots
  SHLIBEXT= dylib
  LIBOPTS= -bundle -undefined dynamic_lookup
ifeq ($(MODE),32)
  CC=gcc -arch i386
  CXX=g++ -arch i386
  LD= ld -arch i386
endif
  CXXFLAGS= -O2

endif

INCLUDE_DIR = $(WEBOTS_HOME)/include
LUAINCLUDE = -I/usr/local/include -I/usr/include/lua5.1
LIB_DIR = $(WEBOTS_HOME)/lib

all: controller

%.o: %.cc
	$(CXX) $(CXXFLAGS) $(LUAINCLUDE) -I$(INCLUDE_DIR) -o $@ -c $<
%.o: %.c
	$(CC) $(CXXFLAGS) $(LUAINCLUDE) -I$(INCLUDE_DIR) -I$(INCLUDE_DIR)/controller/c -o $@ -c $<

controller_wrap.c: controller.i
	swig -lua -I$(WEBOTS_HOME)/include/controller/c controller.i

controller: controller_wrap.o
	$(LD) -o $@.$(SHLIBEXT) $(LIBOPTS) $^ -L$(LIB_DIR) -lController
ifeq ($(OSTYPE),darwin)
	ln -s controller.dylib controller.so
	ln -s unix.dylib unix.so
endif

# Old handwritten controller code:
webotsController: webotsController.o
	$(LD) -o $@.$(SHLIBEXT) $(LIBOPTS) $^ -L$(LIB_DIR) -lController

clean:
	rm -f controller.$(SHLIBEXT) *.o *.so *.dylib 
