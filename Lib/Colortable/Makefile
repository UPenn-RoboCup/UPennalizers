# Makefile used to build mex files

TARGETS = all clean
.PHONY: $(TARGETS)

ifndef OSTYPE
  OSTYPE = $(shell uname -s|awk '{print tolower($$0)}')
  #export OSTYPE
endif

ifeq ($(OSTYPE),linux)
  MEXSUFFIX = mexglx
endif
ifeq ($(OSTYPE),darwin)
  MEXSUFFIX = mexmaci
endif

MEX = mex
CXXFLAGS = -O
BOOST = -lrt -I/usr/local/boost/

all: rgbselect.$(MEXSUFFIX) 

%.$(MEXSUFFIX): %.cc
	$(MEX) $(CXXFLAGS) $<

%.$(MEXSUFFIX): %.c
	$(MEX) $(CXXFLAGS) $<

rgbselect.$(MEXSUFFIX): rgbselect.cc 
	$(MEX) $(CXXFLAGS) $^ $(BOOST)

clean:
	rm -f *.$(MEXSUFFIX) *.o
