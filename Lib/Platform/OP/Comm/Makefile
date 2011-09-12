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
  CXXFLAGS= -O2 -arch i386
  LDFLAGS= -arch i386
endif

INCLUDE_DIR = /usr/local/include -I/usr/include -I/usr/include/lua
LIB_DIR = /usr/local/lib -L/usr/lib

all: comm commwired monitorcomm monitorcommwired

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -I$(INCLUDE_DIR) -o $@ -c $<
%.o: %.cc
	$(CXX) $(CXXFLAGS) -I$(INCLUDE_DIR) -o $@ -c $<
%.o: %.c
	$(CC) $(CXXFLAGS) -I$(INCLUDE_DIR) -o $@ -c $<

comm: luaNSLComm.o 
	$(LD) $(LDFLAGS) -o NSLComm.$(SHLIBEXT) $(LIBOPTS) $^ -L$(LIB_DIR) -lm

commwired: luaNSLCommWired.o 
	$(LD) $(LDFLAGS) -o NSLCommWired.$(SHLIBEXT) $(LIBOPTS) $^ -L$(LIB_DIR) -lm

monitorcommwired: luaNSLMonitorCommWired.o
	$(LD) $(LDFLAGS) -o NSLMonitorCommWired.$(SHLIBEXT) $(LIBOPTS) $^ -L$(LIB_DIR) -lm

monitorcomm: luaNSLMonitorComm.o
	$(LD) $(LDFLAGS) -o NSLMonitorComm.$(SHLIBEXT) $(LIBOPTS) $^ -L$(LIB_DIR) -lm

clean:
	rm -f *.$(SHLIBEXT) *.o
