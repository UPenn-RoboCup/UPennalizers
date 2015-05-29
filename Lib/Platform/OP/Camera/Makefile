ifeq ($(shell uname),Darwin)
all:
else
LIBNAME=OPCam
EXTRA_OBJ=timeScalar.o v4l2.o
include ../../../Makefile.am
LIBOPTS+=-lm $(LIBRT)
endif
clean:
	rm -f *.$(SHLIBEXT) *.o
