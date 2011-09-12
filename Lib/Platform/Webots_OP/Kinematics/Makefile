# Makefile used to build libraries

TARGETS = all clean
.PHONY: $(TARGETS)

CXX=g++
CC=gcc
LD=g++
STRIP=strip
CXXFLAGS= -O2 -fpic
LDFLAGS=

SHLIBEXT= so
LIBOPTS= -shared

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
  CXXFLAGS= -O2
ifeq ($(MODE),32)
  CC=gcc -arch i386
  CXX=g++ -arch i386
  LD=g++ -arch i386
endif

endif

INCLUDE_DIR = /usr/local/include
LIB_DIR = /usr/local/lib

LIBNAME= DarwinOPKinematics

all:: kinematics

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -I$(INCLUDE_DIR) -o $@ -c $<
%.o: %.cc
	$(CXX) $(CXXFLAGS) -I$(INCLUDE_DIR) -o $@ -c $<
%.o: %.c
	$(CC) $(CXXFLAGS) -I$(INCLUDE_DIR) -o $@ -c $<

kinematics:: luaDarwinOPKinematics.o DarwinOPKinematics.o Transform.o
	$(LD) $(LDFLAGS) -o $(LIBNAME).$(SHLIBEXT) $(LIBOPTS) $^ -L$(LIB_DIR) -lm

clean:
	rm -f *.$(SHLIBEXT) *.o
