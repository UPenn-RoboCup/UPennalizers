# Makefile used to build mex files

TARGETS = all clean
.PHONY: $(TARGETS)

ifndef OSTYPE
  OSTYPE = $(shell uname -s|awk '{print tolower($$0)}')
  #export OSTYPE
endif

MEX = mex
CXXFLAGS = -O

ifeq ($(OSTYPE),linux)
  MEXSUFFIX = mexglx
  LIBRT=
endif
ifeq ($(OSTYPE),darwin)
  MEXSUFFIX = mexmaci
  LIBRT=
endif

all: rgbselect.$(MEXSUFFIX) 

%.$(MEXSUFFIX): %.cc
	$(MEX) $(CXXFLAGS) $<

%.$(MEXSUFFIX): %.c
	$(MEX) $(CXXFLAGS) $<

rgbselect.$(MEXSUFFIX): rgbselect.cc 
	$(MEX) $(CXXFLAGS) $^ $(LIBRT)

clean:
	rm -f *.$(MEXSUFFIX) *.o
