LIBNAME=Sound
EXTRA_OBJ=sound_comm_thread.o alsa_util.o dtmf.o

include ../../../Makefile.am
LIBOPTS+=-lm -lasound $(LIBRT)

clean:
	rm -f *.$(SHLIBEXT) *.o
