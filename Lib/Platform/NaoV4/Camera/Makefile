ifeq ($(shell uname),Darwin)
all:
else
LIBNAME=uvc
EXTRA_OBJ=v4l2.o timeScalar.o
include ../../../Makefile.am
CFLAGS+=-Wall -g
LIBOPTS+=-lm $(LIBRT)
endif
clean:
	rm -f *.$(SHLIBEXT) *.o

