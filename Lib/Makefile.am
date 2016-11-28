# Makefile Includes
# http://owen.sj.ca.us/~rk/howto/slides/make/slides/makerecurs.html
TOP := $(dir $(lastword $(MAKEFILE_LIST)))
TARGETS = all clean
.PHONY: $(TARGETS)

# Find the Operating system
ifndef OSTYPE
  OSTYPE=$(shell uname -s|awk '{print tolower($$0)}')
endif
ifndef ARCH
  ARCH=$(shell uname -m)
endif
# Cross compiling
ifeq ($(CROSS),true)
  CTCDIR = $(NaoqiCTC)
else
  CTCDIR = 
endif
export CTCDIR

######################
## Path Definitions ##
######################
NAODIR= Platform/Nao
NAOV4DIR = Platform/NaoV4
WEBOTSNAODIR= Platform/WebotsNao
WEBOTSOPDIR= Platform/WebotsOP
OPDIR= Platform/OP
XOSDIR= Platform/XOS
CHARLIDIR = Platform/Charli
MODULEDIR = Modules
NAOQIDIRV5 = $(NAOV4DIR)/NaoQiV5
NAOQIDIR= $(NAOV4DIR)/NaoQi
WEBOTSDIR = $(MODULEDIR)/Webots
IMAGEDIR= $(MODULEDIR)/ImageProc
COMMDIR= $(MODULEDIR)/Comm
OCCMAPDIR = $(MODULEDIR)/OccMap
UTILDIR= $(MODULEDIR)/Util
MATLABDIR= ../Tools/Matlab
COLORTABLEDIR= $(MATLABDIR)/Colortable
PLATFORMS = nao naov4 op xos webots_nao webots_op webots_generic webots_hubo visiontest
INSTDIR= ../Player/Lib
WEBOTSCONTDIR= ../WebotsController
PLAYERDIR= ../Player
NAODEPDIR= ../Install/dependencies
NAODEPLUA51DIR= $(NAODEPDIR)/usr/local/lib/lua/5.1

##########################
## Compiler Definitions ##
##########################
# Defaults to Linux
CXX=g++
CC=gcc
LD=g++
LDFLAGS=-shared -fpic
STRIP=strip
CXXFLAGS=-fPIC -O2
#CXXFLAGS=-fPIC -O3 -mtune=native -march=native
CFLAGS=$(CXXFLAGS)
LIBOPTS=
LIBRT=-lrt
SHLIBEXT=so
INCLUDES=-I/usr/include/lua5.1 -I/usr/local/include
LIB_DIR=-L/usr/local/lib
USE_TORCH=1
# OS Specific overrides
ifeq ($(OSTYPE),darwin)
  LIBRT=
  CC=cc
  CXX=c++
  #LD=ld -macosx_version_min 10.7
  CXXFLAGS=-fPIC -O3
  INCLUDES= -I/usr/local/lib -I/usr/local/include
  LDFLAGS=-lstdc++ -bundle -undefined dynamic_lookup
endif

##########################
## Makefile Definitions ##
##########################
# Verbose mode
VERBOSE?=no
V=@
ifeq ($(VERBOSE),yes)
V=
endif
# General Targets
%.o: %.cpp
	@echo "\t" CXX $@
	$(V)$(CXX) $(CXXFLAGS) $(INCLUDES) -o $@ -c $<
%.o: %.cc
	@echo "\t" CXX $@
	$(V)$(CXX) $(CXXFLAGS) $(INCLUDES) -o $@ -c $<
%.o: %.c
	@echo "\t" CC $@
	$(V)$(CC) $(CFLAGS) $(INCLUDES) -o $@ -c $<
$(LIBNAME): lua_$(LIBNAME).o $(EXTRA_OBJ)
	@echo "\t" LINK $@
	$(V)$(LD) $(LDFLAGS) -o $@.$(SHLIBEXT) $^ $(LIB_DIR) $(LIBOPTS)
	@rm $^
	
###################
## Installation  ##
###################
LUAEXT=lua
ifeq ($(OSTYPE),darwin)
REGEX=\( -regex '.*.$(LUAEXT)' -or -regex '.*.$(SHLIBEXT)' -or -regex '.*.sh' \)
else
REGEX=-regex '.*\($(SHLIBEXT)\|$(LUAEXT)\|sh\)'
endif
