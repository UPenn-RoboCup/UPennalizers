LIBNAME = cutil
include ../../../Makefile.am
ifdef USE_TORCH
	CXXFLAGS+=-DTORCH=1
	#LDFLAGS+=-ltorch
	LIBOPTS+=-ltorch
endif

clean:
	rm -rf *.so *.o
