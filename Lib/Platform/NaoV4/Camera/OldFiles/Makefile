ifeq ($(shell uname),Darwin)
all:
else
LIBNAME=NaoCam
EXTRA_OBJ=timeScalar.o nao_cam_mmap_thread.o cam_util.o
include ../../../Makefile.am
LIBOPTS+=-lm $(LIBRT)
endif
clean:
	rm -f *.$(SHLIBEXT) *.o
