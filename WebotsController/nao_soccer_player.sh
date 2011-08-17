#!/bin/sh

# On Linux, need to verify that xterm is not setgid
# Otherwise, LD_LIBRARY_PATH gets unset in xterm

COMPUTER=`uname`
export COMPUTER

PLAYER_ID=$1
export PLAYER_ID
TEAM_ID=$2
export TEAM_ID

exec xterm -e "lua -l controller"
