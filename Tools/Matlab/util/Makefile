TARGETS = all clean
.PHONY: $(TARGETS)
MATMEX=mex
BOOST_INCLUDE_DIRS=-I/opt/boost/include
INCLUDES=

ifndef OSTYPE
  OSTYPE = $(shell uname -s|awk '{print tolower($$0)}')
endif

ifeq ($(OSTYPE),linux)
  SHLIBEXT=so
  LIBRT=-lrt
endif
ifeq ($(OSTYPE),darwin)
  SHLIBEXT=dylib
  INCLUDES=-I/usr/include -I/usr/local/include
endif

MEXEXT=$(shell mexext)

all: time mexshm getch udpcomm

14a: MATMEX=/Applications/MATLAB_R2014a.app/bin/mex
14a: all

14b: MATMEX=/Applications/MATLAB_R2014b.app/bin/mex
14b: all

15a: MATMEX=/Applications/MATLAB_R2015a.app/bin/mex
15a: all

15b: MATMEX=/Applications/MATLAB_R2015b.app/bin/mex
15b: all


time: time.cc timeScalar.cc
	$(MATMEX) -O $^ $(BOOST_INCLUDE_DIRS) $(INCLUDES) $(LIBRT)

mexshm: mexshm.cpp
	$(MATMEX) -O $^ $(BOOST_INCLUDE_DIRS) $(INCLUDES) $(LIBRT)

getch: getch.c
	$(MATMEX) -O $^ $(BOOST_INCLUDE_DIRS) $(INCLUDES) $(LIBRT)

udpcomm: UDPComm.cc
	$(MATMEX) -O $^ $(BOOST_INCLUDE_DIRS) $(INCLUDES) $(LIBRT)


clean:
	rm -f *.o *.$(SHLIBEXT) *.$(MEXEXT)

