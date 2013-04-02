# Makefile Includes (http://owen.sj.ca.us/~rk/howto/slides/make/slides/makerecurs.html)
TARGETS = all clean
.PHONY: $(TARGETS)

## Path Definition

NAODIR= Platform/Nao
NAOV4DIR = Platform/NaoV4
WEBOTSNAODIR= Platform/WebotsNao
WEBOTSOPDIR= Platform/WebotsOP
HPDIR= Platform/HP2
OPDIR= Platform/OP
MODULEDIR = Modules
NAOQIDIR= NaoQi_v1.12
WEBOTSDIR = $(MODULEDIR)/Webots
IMAGEDIR= $(MODULEDIR)/ImageProc
COMMDIR= $(MODULEDIR)/Comm
UTILDIR= $(MODULEDIR)/Util
MATLABDIR= ../Tools/Matlab
COLORTABLEDIR= $(MATLABDIR)/Colortable
VELODIR= $(MODULEDIR)/Velocity
PLATFORMS = nao naov4 op webots_nao webots_op
INSTDIR= ../Player/Lib
WEBOTSCONTDIR= ../WebotsController
PLAYERDIR= ../Player
NAODEPDIR= ../Install/dependencies
NAODEPLUA51DIR= $(NAODEPDIR)/usr/local/lib/lua/5.1


## Compiler Definition
MODE=$(shell getconf LONG_BIT)
CXX=g++
CC=gcc
#LD=ld
LD=g++
LDFLAGS=
STRIP=strip
CXXFLAGS= -O2 -fpic

MEXEXT=mexglx
SHLIBEXT= so
LIBOPTS= -shared -fpic
LIBRT= -lrt

#This does not work 
#INCLUDES= -I/usr/local/include -I../include/lua5.1.4
INCLUDES= -I/usr/local/include -I/usr/include/lua -I/usr/include/lua5.1 -I/usr/local/include/lua5.1 -I/usr/local/include/lua -I/usr/local/include/luajit-2.0
LIB_DIR= -L/usr/local/lib -L/usr/lib
WEBOTS_HOME = /usr/local/webots

ifndef OSTYPE
  OSTYPE = $(shell uname -s|awk '{print tolower($$0)}')
endif

ifndef ARCH
  ARCH= $(shell uname -m)
endif

ifndef USER
  USER=$(shell whoami)
endif

ifeq ($(OSTYPE),linux)
  SHLIBEXT= so
  LIBOPTS= -shared -fpic
  LIBRT= -lrt
ifeq ($(USER),darwin)
  CXXFLAGS= -O3 -fomit-frame-pointer -mtune=native -march=native -pipe -funroll-loops
endif
endif

ifeq ($(OSTYPE),darwin)
  ifeq ($(wildcard /Applications/Webots),)
    ifeq ($(wildcard ~/Applications/Webots),)
      $(error Could not find Webots!)
    else
      WEBOTS_HOME= $(wildcard ~/Applications/Webots)
    endif
  else
    WEBOTS_HOME= /Applications/Webots
  endif
  #  SHLIBEXT= dylib
  SHLIBEXT= so
  LIBOPTS= -bundle -undefined dynamic_lookup
  # -march=native is not supported, so tune as your system demand
  CXXFLAGS= -O2 -fomit-frame-pointer -mtune=native
  LIBRT=
# The -arch option is only available on Mac systems to create universal binaries
ifeq ($(MODE),64)
  CC=gcc -arch x86_64
  CXX=g++ -arch x86_64
  LD=g++ -arch x86_64
  MEXEXT=mexmaci64
else
  CC=gcc -arch i386
  CXX=g++ -arch i386
  LD=g++ -arch i386
  MEXEXT=mexmaci
endif
endif



# For Intel Atom Z530 on the Darwin-OP
# http://jim-dev.blogspot.com/2010/04/gentoo-linux-on-dell-mini-1012.html
#CFLAGS="-O2 -march=core2 -mtune=generic -mssse3 -mfpmath=sse -pipe -fomit-frame-pointer"
#CXXFLAGS="${CFLAGS}"
# From Gentoo wiki (http://en.gentoo-wiki.com/wiki/Intel_D945GCLF2)
#CHOST="i686-pc-linux-gnu"
#CFLAGS="-O2 -march=core2 -mtune=generic -fomit-frame-pointer -pipe -mssse3 -mfpmath=sse"
# Possible?
#CXXFLAGS= -O3 -funroll-loops -fpic
#-mtune=atom
# ANother guide: http://linuxreviews.org/howtos/compiling/#toc1
# -march=native could help...?
#  Look at the warning here: http://en.gentoo-wiki.com/wiki/Safe_Cflags/Intel
#  http://tombarta.wordpress.com/2008/05/25/gcc-flags/
#  Should be using arch...? http://www.implbits.com/About/Blog/tabid/78/post/building-with-gcc-4-6-on-osx/Default.aspx
# http://stackoverflow.com/questions/1754460/apples-gcc-whats-the-difference-between-arch-i386-and-m32
#  Really, should use native unless on the Nao
# OSX Specific: http://programmers.stackexchange.com/questions/51670/why-do-programmers-use-or-recommend-mac-os-x
