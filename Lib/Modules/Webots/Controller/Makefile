# Makefile used to build Webots files
EXTRA_OBJ=lua_controller.o
LIBNAME=controller
include ../../../Makefile.am

lua_controller.c: lua_controller.i
	@echo "\t" SWIG $@
	$(V)swig -lua -o $@ -I$(WEBOTS_HOME)/include/controller/c lua_controller.i

WEBOTS_HOME=/home/sagar/Documents/webots
ifeq ($(OSTYPE),darwin)
WEBOTS_HOME=/Applications/Webots
endif
INCLUDES+=-I$(WEBOTS_HOME)/include/controller/c
LIB_DIR+=-L$(WEBOTS_HOME)/lib
LIBOPTS+=-lController
ifeq ($(VERBOSE),no)
CXXFLAGS+=-Wno-deprecated-declarations
CFLAGS+=-Wno-deprecated-declarations
endif

clean:
	rm -f $(LIBNAME).$(SHLIBEXT) *.o *.so lua_controller.c
