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
endif

ifeq ($(OSTYPE),linux)
	MODE ?= 32
  SHLIBEXT= so
  LIBOPTS= -shared -fpic
  SYS_INC= 
endif
ifeq ($(OSTYPE),darwin)
	MODE ?= 64
  WEBOTS_HOME= /Applications/Webots
  SHLIBEXT= dylib
  LIBOPTS= -bundle -undefined dynamic_lookup
  SYS_INC= -I/usr/include/sys
ifeq ($(MODE),32)
  CC=gcc -arch i386
  CXX=g++ -arch i386
  LD= ld -arch i386
endif
  CXXFLAGS= -O2
endif

WEBOTS_INC= -I$(WEBOTS_HOME)/include
WEBOTS_C_INC= -I$(WEBOTS_HOME)/include/controller/c

LUA_INC= -I/usr/local/include -I/usr/include/lua5.1

LIB_DIR= $(WEBOTS_HOME)/lib

all: controller

%.o: %.cc
	$(CXX) $(CXXFLAGS) $(LUAINCLUDE) $(WEBOTS_INC) $(SYS_INC) -o $@ -c $<
%.o: %.c
	$(CC) $(CXXFLAGS) $(LUA_INC) $(WEBOTS_INC) $(WEBOTS_C_INC) $(SYS_INC) -o $@ -c $<

controller_wrap.c: controller.i
	swig -lua $(WEBOTS_C_INC) controller.i

controller: controller_wrap.o
	$(LD) -o $@.$(SHLIBEXT) $(LIBOPTS) $^ -L$(LIB_DIR) -lController /usr/lib/crt1.o
ifeq ($(OSTYPE),darwin)
	ln -s -f controller.dylib controller.so
	ln -s -f unix.dylib unix.so
endif

# Old handwritten controller code:
webotsController: webotsController.o
	$(LD) -o $@.$(SHLIBEXT) $(LIBOPTS) $^ -L$(LIB_DIR) -lController

clean:
	rm -f controller.$(SHLIBEXT) controller_wrap.c *.o *.so *.dylib 
