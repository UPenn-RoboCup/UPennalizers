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

INCLUDE_DIRS = -I/usr/local/include -I/usr/include -I/usr/include/lua -I/usr/include/lua5.1
LIB_DIR = /usr/local/lib -L/usr/lib

all: comm commwired monitorcomm monitorcommwired

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDE_DIRS) -o $@ -c $<
%.o: %.cc
	$(CXX) $(CXXFLAGS) $(INCLUDE_DIRS) -o $@ -c $<
%.o: %.c
	$(CC) $(CXXFLAGS) $(INCLUDE_DIRS) -o $@ -c $<

comm: luaOPComm.o 
	$(LD) $(LDFLAGS) -o OPComm.$(SHLIBEXT) $(LIBOPTS) $^ -L$(LIB_DIR) -lm

commwired: luaOPCommWired.o 
	$(LD) $(LDFLAGS) -o OPCommWired.$(SHLIBEXT) $(LIBOPTS) $^ -L$(LIB_DIR) -lm

monitorcommwired: luaOPMonitorCommWired.o
	$(LD) $(LDFLAGS) -o OPMonitorCommWired.$(SHLIBEXT) $(LIBOPTS) $^ -L$(LIB_DIR) -lm

monitorcomm: luaOPMonitorComm.o
	$(LD) $(LDFLAGS) -o OPMonitorComm.$(SHLIBEXT) $(LIBOPTS) $^ -L$(LIB_DIR) -lm

clean:
	rm -f *.$(SHLIBEXT) *.o
