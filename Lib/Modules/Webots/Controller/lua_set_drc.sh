#!/bin/sh

##############################
##### USER ADJUSTABLE SETTINGS
##############################
EXT_TERM=0
# Go into the Player directory
#cd Player
cd Run

# Set up the right settings for a mac
COMPUTER=`uname`
export COMPUTER
if [ "$COMPUTER" = "Darwin" ]
then
  #export OSTYPE = $(shell uname -s|awk '{print tolower($$0)}')
	eval `/usr/libexec/path_helper -s`
fi

#LUA=lua
LUA=luajit
TERM=`which xterm`
#LPATH=`/usr/local/bin/lua -e 'print(package.path)'`

#echo pwd $PWD
#echo path $PATH
#echo os $OSTYPE
#echo lua $LUA
#echo lpath $LPATH
#echo term $TERM
#echo compute $COMPUTER

# On Linux, need to verify that xterm is not setgid
# Otherwise, LD_LIBRARY_PATH gets unset in xterm
export PLAYER_ID=$1
export TEAM_ID=$2
export PLATFORM=webots

#TESTFILE=state_wizard.lua
TESTFILE=webots_wizard.lua

# Spawn the right terminal
if [ "$EXT_TERM" -gt "0" ]
then
  # In separate xterms
  exec $TERM -l -e "$LUA $TESTFILE"
else
  # In webots console
  exec $LUA $TESTFILE
fi

#exec luajit -l controller start.lua
#exec xterm -l -e "/usr/bin/gdb --args lua start.lua"
#exec xterm -l -e "valgrind --tool=memcheck --leak-check=yes --dsymutil=yes luajit start.lua"
