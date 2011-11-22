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

INCLUDE_DIRS = -I/usr/local/include -I/usr/include -I/usr/include/lua -I/usr/include/lua5.1
LIB_DIR = /usr/local/lib -L/usr/lib

all: comm commwired monitorcomm monitorcommwired

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDE_DIRS) -o $@ -c $<
%.o: %.cc
	$(CXX) $(CXXFLAGS) $(INCLUDE_DIRS) -o $@ -c $<
%.o: %.c
	$(CC) $(CXXFLAGS) $(INCLUDE_DIRS) -o $@ -c $<

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
