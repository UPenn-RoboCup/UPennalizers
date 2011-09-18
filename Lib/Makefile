# Master Makefile to compile all Lua/C++ libraries

CWD= $(shell pwd)

MODE ?= 32

NAODIR= Platform/Nao
NAOQIDIR= NaoQi
WEBOTSDIR= Platform/Webots
WEBOTSOPDIR= Platform/Webots_OP
LC2DIR= Platform/LC2
HPDIR= Platform/HP2
OPDIR= Platform/OP
IMAGEDIR= ImageProc
UTILDIR= Util
MATLABDIR= Matlab
COLORTABLEDIR= Colortable
VELODIR= Velocity

INSTDIR= ../Player/Lib
WEBOTSCONTDIR= ../WebotsController
PLAYERDIR= ../Player
NAODEPDIR= ../Install/dependencies
NAODEPLUA51DIR= $(NAODEPDIR)/usr/local/lib/lua/5.1

LUAEXT= lua
REGEX=-regex '.*\($(SHLIBEXT)\|$(LUAEXT)\)'

ifndef OSTYPE
  OSTYPE = $(shell uname -s|awk '{print tolower($$0)}')
  #export OSTYPE
endif
ifeq ($(OSTYPE),linux)
  SHLIBEXT= so
endif
ifeq ($(OSTYPE),darwin)
  SHLIBEXT= dylib
  REGEX=\( -regex '.*.$(LUAEXT)' -or -regex '.*.$(SHLIBEXT)' \)
endif

all: nao webots webots_op op lc2 hp image util

colortable:
	@echo "Compiling Colortable Mex Files...\n"
	@cd $(COLORTABLEDIR) && make && cd $(CWD)
	@echo "\n"

matlab:
	@echo "Compiling MATLAB Mex Files...\n"
	@cd $(MATLABDIR) && make && cd $(CWD)
	@echo "\n"

nao:
	@echo "Compiling Nao Lua/C++ Libraries...\n"
	@cd $(NAODIR) && make && cd $(CWD)
	@echo "\n"

naoqi:
	@echo "Compiling Custom Naoqi Modules...\n"
	@cd $(NAOQIDIR) && make && cd $(CWD)
	@echo "\n"

lc2:
	@echo "Compiling LC2 Lua/C++ Libraries...\n"
	@cd $(LC2DIR) && make && cd $(CWD)
	@echo "\n"

hp:
	@echo "Compiling HP Lua/C++ Libraries...\n"
	@cd $(HPDIR) && make && cd $(CWD)
	@echo "\n"

op:
	@echo "Compiling Darwin OP Lua/C++ Libraries...\n"
	@cd $(OPDIR) && make && cd $(CWD)
	@echo "\n"

webots:
	@echo "Compiling Webots Lua/C++ Libraries...\n"
	@cd $(WEBOTSDIR) && MODE=$(MODE) make && cd $(CWD)
	@echo "\n"

webots_op:
	@echo "Compiling Webots OP Lua/C++ Libraries...\n"
	@cd $(WEBOTSOPDIR) && MODE=$(MODE) make && cd $(CWD)
	@echo "\n"

image:
	@echo "Compiling Image Processing Lua/C++ Libraries...\n"
	@cd $(IMAGEDIR) && MODE=$(MODE) make && cd $(CWD)
	@echo "\n"

util::
	@echo "Mode: $(MODE)"
	@echo "Compiling Utility Lua/C++ Libraries...\n"
	@cd $(UTILDIR) && MODE=$(MODE) make && cd $(CWD)
	@echo "\n"

velocity:
	@echo "Compiling Velocity Code...\n"
	@cd $(VELODIR) && MODE=$(MODE) make && cd $(CWD)
	@echo "\n"
	
setup_nao: nao setup_util setup_image
	@echo "Setting up Nao Lua/C++ Libraries...\n"
	mkdir -p $(INSTDIR)
	find $(NAODIR) -regex '.*\($(SHLIBEXT)\|$(LUAEXT)\)' -exec cp -v {} $(INSTDIR) \;
	cd $(PLAYERDIR)/Config && rm Config.lua && ln -s Config_Nao.lua Config.lua && cd $(CWD)
	@echo "\n"

setup_webots: webots setup_util setup_image
	@echo "Setting up Webots Lua/C++ Libraries...\n"
	mkdir -p $(INSTDIR)
	find $(WEBOTSDIR) $(REGEX) -exec cp -v {} $(INSTDIR) \;
	cd $(PLAYERDIR)/Config && rm Config.lua && ln -s Config_Webots.lua Config.lua && cd $(CWD)
	cd $(WEBOTSCONTDIR) && MODE=$(MODE) make && cd $(CWD)
	@echo "\n"

#setup_webots_op: webots_op setup_util setup_image setup_velocity
setup_webots_op: webots_op setup_util setup_image 
	@echo "Setting up Webots Lua/C++ Libraries...\n"
	mkdir -p $(INSTDIR)
	find $(WEBOTSOPDIR) $(REGEX) -exec cp -v {} $(INSTDIR) \;
	cd $(PLAYERDIR)/Config && rm Config.lua && ln -s Config_Webots_OP.lua Config.lua && cd $(CWD)
	cd $(WEBOTSCONTDIR) && MODE=$(MODE) make && cd $(CWD)
	cd $(WEBOTSCONTDIR) && touch Player && cd $(CWD)  
	cd $(WEBOTSCONTDIR) && rm Player && ln -s ../Player Player && cd $(CWD)
	@echo "\n"

setup_lc2: lc2 setup_util setup_image
	@echo "Setting up LC2 Lua/C++ Libraries...\n"
	mkdir -p $(INSTDIR)
	find $(LC2DIR) -regex '.*\($(SHLIBEXT)\|$(LUAEXT)\)' -exec cp -v {} $(INSTDIR) \;
	touch $(PLAYERDIR)/Config/Config.lua
	cd $(PLAYERDIR)/Config && rm Config.lua && ln -s Config_LC2.lua Config.lua && cd $(CWD)
	cp $(INSTDIR)/unix.so $(PLAYERDIR)/
	@echo "\n"

setup_hp: hp setup_util setup_image
	@echo "Setting up HP Lua/C++ Libraries...\n"
	mkdir -p $(INSTDIR)
	find $(HPDIR) -regex '.*\($(SHLIBEXT)\|$(LUAEXT)\)' -exec cp -v {} $(INSTDIR) \;
	touch $(PLAYERDIR)/Config/Config.lua
	cd $(PLAYERDIR)/Config && rm Config.lua && ln -s Config_HP.lua Config.lua && cd $(CWD)
	cp $(INSTDIR)/unix.so $(PLAYERDIR)/
	@echo "\n"

#setup_op: op setup_util setup_image setup_velocity
setup_op: op setup_util setup_image 
	@echo "Setting up Darwin OP Lua/C++ Libraries...\n"
	mkdir -p $(INSTDIR)
	find $(OPDIR) -regex '.*\($(SHLIBEXT)\|$(LUAEXT)\)' -exec cp -v {} $(INSTDIR) \;
	touch $(PLAYERDIR)/Config/Config.lua
	cd $(PLAYERDIR)/Config && rm Config.lua && ln -s Config_OP.lua Config.lua && cd $(CWD)
	cp $(INSTDIR)/unix.so $(PLAYERDIR)/
	cp $(INSTDIR)/unix.so $(PLAYERDIR)/Vision/
	@echo "\n"

setup_image: image
	@echo "Setting up Image Processing Lua/C++ Libraries...\n"
	mkdir -p $(INSTDIR)
	find $(IMAGEDIR) $(REGEX) -exec cp -v {} $(INSTDIR) \;
	@echo "\n"

setup_util: util
	@echo "Setting up Utility Lua/C++ Libraries...\n"
	mkdir -p $(INSTDIR)
	find $(UTILDIR) $(REGEX) -exec cp -v {} $(INSTDIR) \;
	find $(UTILDIR) $(REGEX) -exec cp -v {} $(WEBOTSCONTDIR) \;
	find $(UTILDIR) $(REGEX) -exec cp -v {} $(NAODEPLUA51DIR) \;
	@echo "\n"

setup_velocity: velocity
	@echo "Setting up Velocity Lua/C++ Libraries...\n"
	mkdir -p $(INSTDIR)
	find $(VELODIR) $(REGEX) -exec cp -v {} $(INSTDIR) \;
	find $(VELODIR) $(REGEX) -exec cp -v {} $(WEBOTSCONTDIR) \;
	find $(VELODIR) $(REGEX) -exec cp -v {} $(NAODEPLUA51DIR) \;
#	cp $(VELODIR)/testmodel.xml $(INSTDIR)/../Vision/
	@echo "\n"

setup_naoqi: naoqi setup_util
	@echo "Setting up NaoQi module...\n"
	mkdir -p $(INSTDIR)
	rsync -avr --exclude=".*" $(NAOQIDIR)/build/sdk/lib/naoqi/* ../Install/naoqi/lib/naoqi/
	@echo "\n"

clean: 
	cd $(IMAGEDIR) && make clean && cd $(CWD)
	cd $(UTILDIR) && make clean && cd $(CWD)
#	cd $(VELODIR) && make clean && cd $(CWD)
	cd $(NAODIR) && make clean && cd $(CWD)
	cd $(NAOQIDIR) && make clean && cd $(CWD)
#	cd $(LC2DIR) && make clean && cd $(CWD)
	cd $(WEBOTSDIR) && make clean && cd $(CWD)
	cd $(WEBOTSOPDIR) && make clean && cd $(CWD)
	cd $(WEBOTSCONTDIR) && make clean && cd $(CWD)
#	cd $(HPDIR) && make clean && cd $(CWD)
	cd $(OPDIR) && make clean && cd $(CWD)
