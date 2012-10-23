#!/bin/sh

# On Linux, need to verify that xterm is not setgid
# Otherwise, LD_LIBRARY_PATH gets unset in xterm

COMPUTER=`uname`
export COMPUTER

export PLAYER_ID=$1
export TEAM_ID=$2

PLATFORM=webots
export PLATFORM

#exec xterm -e "lua -l controller"
#exec luajit -l controller start.lua
exec lua start.lua

