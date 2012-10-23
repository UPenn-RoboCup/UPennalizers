# Master Makefile to compile all Lua/C++ libraries

CWD= $(shell pwd)
include $(CWD)/Makefile.inc


LUAEXT= lua
ifeq ($(OSTYPE),darwin)
REGEX=\( -regex '.*.$(LUAEXT)' -or -regex '.*.$(SHLIBEXT)' -or -regex '.*.sh' \)
else
REGEX=-regex '.*\($(SHLIBEXT)\|$(LUAEXT)\|sh\)'
endif

CROSS= false

ifndef OSTYPE
  OSTYPE = $(shell uname -s|awk '{print tolower($$0)}')
endif

ifndef ARCH
  ARCH= $(shell uname -m)
endif

ifeq ($(CROSS),true)
  CTCDIR = $(NaoqiCTC)
else
  CTCDIR = 
endif

ifeq ($(CTCDIR),)
  ifeq ($(OSTYPE),linux)
    SHLIBEXT= so
  endif

  #ifeq ($(OSTYPE),darwin)
  #  SHLIBEXT= dylib
  #  REGEX=\( -regex '.*.$(LUAEXT)' -or -regex '.*.$(SHLIBEXT)' -or -regex '.*.sh' \)
  #endif
  else
    SHLIBEXT= so
  #ifeq ($(OSTYPE),darwin)
  #  REGEX=\( -regex '.*.$(LUAEXT)' -or -regex '.*.$(SHLIBEXT)' -or -regex '.*.sh' \)
  #endif
endif

export CTCDIR

all none:
	@echo "Please do:"
	@echo "\tmake setup_PLATFORM"
	@echo "where PLATFORM is one of following:"
	@echo "\t$(PLATFORMS)"

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

naov4:
	@echo $(CTCDIR)
	@echo "Compiling Nao V4 Lua/C++ Libraries...\n"
	@cd $(NAOV4DIR) && make && cd $(CWD)
	@echo "\n"

naoqi:
	@echo "Compiling Custom Naoqi Modules...\n"
	@cd $(NAOQIDIR) && make && cd $(CWD)
	@echo "\n"

hp:
	@echo "Compiling HP Lua/C++ Libraries...\n"
	@cd $(HPDIR) && make && cd $(CWD)
	@echo "\n"

op:
	@echo "Compiling Darwin OP Lua/C++ Libraries...\n"
	@cd $(OPDIR) && make && cd $(CWD)
	@echo "\n"

webots_nao:
	@echo "Compiling Webots Lua/C++ Libraries...\n"
	@cd $(WEBOTSNAODIR) && make && cd $(CWD)
	@echo "\n"

webots_op:
	@echo "Compiling Webots OP Lua/C++ Libraries...\n"
	@cd $(WEBOTSOPDIR) && make && cd $(CWD)
	@echo "\n"

webot:
	@echo "Compiling Webots Lua/C++ Libraries...\n"
	@cd $(WEBOTSDIR) && make && cd $(CWD)
	@echo "\n"

image:
	@echo "Compiling Image Processing Lua/C++ Libraries...\n"
	@cd $(IMAGEDIR) && make && cd $(CWD)
	@echo "\n"

comm::
	@echo "Compiling Communication Lua/C++ Libraries...\n"
	@cd $(COMMDIR) && make && cd $(CWD)
	@echo "\n"

util::
	@echo "Compiling Utility Lua/C++ Libraries...\n"
	@cd $(UTILDIR) && make && cd $(CWD)
	@echo "\n"

velocity::
	@echo "Compiling Velocity Code...\n"
	@cd $(VELODIR) && make && cd $(CWD)
	@echo "\n"

setup_nao: nao setup_util setup_image setup_comm
	@echo "Setting up Nao Lua/C++ Libraries...\n"
	mkdir -p $(INSTDIR)
	find $(NAODIR) $(REGEX) -exec cp -v {} $(INSTDIR) \;
	rm -f $(PLAYERDIR)/Config/Config.lua
	cd $(PLAYERDIR)/Config && ln -s Config_Nao.lua Config.lua && cd $(CWD)
	find $(UTILDIR) $(REGEX) -exec cp -v {} $(NAODEPLUA51DIR) \;
	rm -f $(NAODEPLUA51DIR)/*;
	@echo "\n"

setup_naov4: naov4 setup_util setup_image setup_comm
	@echo "Setting up Nao V4 Lua/C++ Libraries...\n"
	mkdir -p $(INSTDIR)
	find $(NAOV4DIR) $(REGEX) -exec cp -v {} $(INSTDIR) \;
	rm -f $(PLAYERDIR)/Config/Config.lua
	cd $(PLAYERDIR)/Config && ln -s Config_NaoV4.lua Config.lua && cd $(CWD)
#	find $(UTILDIR) $(REGEX) -exec cp -v {} $(NAODEPLUA51DIR) \;
	rm -f $(NAODEPLUA51DIR)/*;
	@echo "\n"

setup_webots_nao: webots_nao setup_util setup_image setup_webots
	@echo "Setting up Webots Lua/C++ Libraries...\n"
	mkdir -p $(INSTDIR)
	find $(WEBOTSNAODIR) $(REGEX) -exec cp -v {} $(INSTDIR) \;
	rm -f $(PLAYERDIR)/Config/Config.lua
	cd $(PLAYERDIR)/Config && ln -s Config_WebotsNao.lua Config.lua && cd $(CWD)
	@echo "\n"

setup_webots_op: webots_op setup_util setup_image setup_webots
	@echo "Setting up Webots Lua/C++ Libraries...\n"
	mkdir -p $(INSTDIR)
	find $(WEBOTSOPDIR) $(REGEX) -exec cp -v {} $(INSTDIR) \;
	rm -f $(PLAYERDIR)/Config/Config.lua
	cd $(PLAYERDIR)/Config && ln -s Config_WebotsOP.lua Config.lua && cd $(CWD)
	@echo "\n"

setup_op: op setup_util setup_image setup_comm
	@echo "Setting up Darwin OP Lua/C++ Libraries...\n"
	mkdir -p $(INSTDIR)
	find $(OPDIR) $(REGEX) -exec cp -v {} $(INSTDIR) \;
	rm -f $(PLAYERDIR)/Config/Config.lua
	cd $(PLAYERDIR)/Config && ln -s Config_OP.lua Config.lua && cd $(CWD)
	@echo "\n"

setup_webots_cont: webot
	@echo "Setting up WebotsController Lua/C++ Libraries...\n"
	mkdir -p $(WEBOTSCONTDIR)
	find $(WEBOTSDIR)/Controller $(REGEX) -exec cp -v {} $(WEBOTSCONTDIR) \;
	cd $(WEBOTSCONTDIR) && ln -sf $(PLAYERDIR) Player && cd $(CWD)
	cd $(WEBOTSCONTDIR) && ln -sf lua_set.sh nao_team_0 && cd $(CWD)
	cd $(WEBOTSCONTDIR) && ln -sf lua_set.sh nao_team_1 && cd $(CWD)
	cd $(WEBOTSCONTDIR) && ln -sf lua_set.sh darwin-op_team_0 && cd $(CWD)
	cd $(WEBOTSCONTDIR) && ln -sf lua_set.sh darwin-op_team_1 && cd $(CWD)
	@echo "\n"

setup_webots: setup_webots_cont
	@echo "Setting up Webots Lua/C++ Libraries...\n"
	mkdir -p $(INSTDIR)
	find $(WEBOTSDIR) $(REGEX) -exec cp -v {} $(INSTDIR) \;
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

	@echo "\n"

setup_comm: comm
	@echo "Setting up Communication Lua/C++ Libraries...\n"
	mkdir -p $(INSTDIR)
	find $(COMMDIR) $(REGEX) -exec cp -v {} $(INSTDIR) \;
	@echo "\n"

setup_velocity: velocity
	@echo "Setting up Velocity Lua/C++ Libraries...\n"
	mkdir -p $(INSTDIR)
	find $(VELODIR) $(REGEX) -exec cp -v {} $(INSTDIR) \;
	find $(VELODIR) $(REGEX) -exec cp -v {} $(WEBOTSCONTDIR) \;
#	cp $(VELODIR)/testmodel.xml $(INSTDIR)/../Vision/
	@echo "\n"

setup_naoqi: naoqi setup_util
	@echo "Setting up NaoQi module...\n"
	mkdir -p $(INSTDIR)
	rsync -avr --exclude=".*" $(NAOQIDIR)/build/sdk/lib/naoqi/* ../Install/naoqi/lib/naoqi/
	@echo "\n"

clean:
	cd $(IMAGEDIR) && make clean && cd $(CWD)
	cd $(COMMDIR) && make clean && cd $(CWD)
	cd $(UTILDIR) && make clean && cd $(CWD)
	cd $(WEBOTSDIR) && make clean && cd $(CWD)
#	cd $(VELODIR) && make clean && cd $(CWD)
	cd $(NAODIR) && make clean && cd $(CWD)
	cd $(NAOV4DIR) && make clean && cd $(CWD)
	cd $(NAOQIDIR) && make clean && cd $(CWD)
	cd $(WEBOTSNAODIR) && make clean && cd $(CWD)
	cd $(WEBOTSOPDIR) && make clean && cd $(CWD)
#	cd $(WEBOTSCONTDIR) && make clean && cd $(CWD)
	rm -rf $(WEBOTSCONTDIR) 
	cd $(OPDIR) && make clean && cd $(CWD)
	cd $(PLAYERDIR)/Config && rm -f Config.lua && cd $(CWD)
	cd $(PLAYERDIR) && rm -rf Lib && cd $(CWD)
