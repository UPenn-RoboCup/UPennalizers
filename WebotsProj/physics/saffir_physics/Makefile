###
### Standard Makefile for Webots physics plugins
###
### Supported platforms: Windows, Mac OS X, Linux
### Supported languages: C, C++
### 
### Authors: Olivier Michel - www.cyberbotics.com
### Revised: Yvan Bourquin - September 30th, 2009.
###
### Uncomment the variables to customize the Makefile

### -----C Sources-----
###
### if your plugin uses several C source files:
# C_SOURCES = my_plugin.c my_clever_algo.c my_graphics.c

### -----C++ Sources-----
###
### if your plugin uses several C++ source files:
# CPP_SOURCES = my_plugin.cpp my_clever_algo.cpp my_graphics.cpp
###     or
# CC_SOURCES = my_plugin.cc my_clever_algo.cc my_graphics.cc

### -----Options-----
###
### if special CFLAGS are necessary, for example to set optimization level or
### to find include files:
# CFLAGS=-O3 -I/my_library_path/include
###
### if your plugin needs additional libraries:
# LIBRARIES=-L/path/to/my/library -lmy_library -lmy_other_library

### Do not modify: this includes Webots global Makefile.include
WEBOTS_HOME=/usr/local/webots

space :=
space +=
WEBOTS_HOME_PATH=$(subst $(space),\ ,$(strip $(subst \,/,$(WEBOTS_HOME))))
include $(WEBOTS_HOME_PATH)/resources/projects/default/plugins/physics/Makefile.include
