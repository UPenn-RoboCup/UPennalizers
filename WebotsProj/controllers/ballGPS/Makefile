###
### Standard Makefile for Webots controllers
### 
### Platform: Windows, Mac OS X, Linux
### Language: C, C++ and Java
### 
### Authors: Olivier Michel - www.cyberbotics.com
### Revised: Yvan Bourquin - September 30th, 2009.
###
### Uncomment the variables to customize the Makefile

### -----C Sources-----
###
### if your controller uses several C sources files:
C_SOURCES = ballGPS.c

### -----C++ Sources-----
###
### if your controller uses several C++ sources files:
# CPP_SOURCES = my_controller.cpp my_clever_algo.cpp my_gui.cpp
###     or
# CC_SOURCES = my_controller.cc my_clever_algo.cc my_gui.cc

### -----C/C++ Options-----
###
### if special CFLAGS are necessary, for example to set optimization level or
### to find include files:
# CFLAGS=-O3 -I/my_library_path/include
###
### if your controller needs additional libraries:
# LIBRARIES=-L/path/to/my/library -lmy_library -lmy_other_library
###
### if you want to use the C API in your C++ program add:
# USE_C_API=1

### -----Java Options-----
###
### if your Java controller needs additional libraries, you should define
### the CLASSPATH environment variable as explained in the Webots User Guide
# CLASSPATH=relative/mylib.jar

### Do not modify: this includes Webots global Makefile.include
space :=
space +=
#TODO: fix makefile
#WEBOTS_HOME=/Applications/Webots
ifndef OSTYPE
	OSTYPE = $(shell uname -s|awk '{print tolower($$0)}')
endif
ifeq ($(OSTYPE),darwin)
	WEBOTS_HOME = /Applications/Webots
else
	WEBOTS_HOME = /usr/local/webots
endif
WEBOTS_HOME_PATH=$(subst $(space),\ ,$(strip $(subst \,/,$(WEBOTS_HOME))))
include $(WEBOTS_HOME_PATH)/resources/projects/default/controllers/Makefile.include
#include /usr/local/webots/resources/projects/default/controllers/Makefile.include
