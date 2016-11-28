# Makefile used to build Webots files
LIBNAME=shm
include ../../../Makefile.am
ifeq ($(OSTYPE),linux)
LIBOPTS=-lrt -lm $(LUA_LIB)
#hack to compile with DRC environment
INCLUDES+=-I/usr/local
endif
