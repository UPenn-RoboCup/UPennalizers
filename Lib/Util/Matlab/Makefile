TARGETS = all clean
.PHONY: $(TARGETS)

#BOOST_INCLUDE_DIRS=-I/usr/local/boost_1_43_0 -I/opt/local/include -I/usr/local/include
BOOST_INCLUDE_DIRS=
INCLUDES=

ifndef OSTYPE
  OSTYPE = $(shell uname -s|awk '{print tolower($$0)}')
  #export OSTYPE
endif

ARCH= $(shell uname -m)
ifeq ($(OSTYPE),linux)
ifeq ($(ARCH),x86_64)
  MEXEXT=mexa64
else
  MEXEXT=mexglx
endif
  SHLIBEXT=so
  LIBRT=-lrt
endif
ifeq ($(OSTYPE),darwin)
  SHLIBEXT=dylib
  MEXEXT=mexmaci
  INCLUDES=-I/usr/include
endif

all: naoComm naoCommWired time mexshm

naoComm: naoComm.cc
	mex -O $^ $(INCLUDES)

naoCommWired: naoCommWired.cc
	mex -O $^ $(INCLUDES)

time: time.cc timeScalar.cc
	mex -O $^ $(BOOST_INCLUDE_DIRS) $(LIBRT)

mexshm: mexshm.cpp
	mex -O $^ $(BOOST_INCLUDE_DIRS) $(LIBRT)

clean:
	rm -f *.o *.$(SHLIBEXT) *.$(MEXEXT)

