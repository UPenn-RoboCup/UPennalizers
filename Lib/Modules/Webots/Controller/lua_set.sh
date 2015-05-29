#!/bin/sh
EXT_TERM=0
JIT=`which luajit`
if [ "$JIT" == "/usr/local/bin/luajit" ] 
then
	LUA=luajit
	echo "use LUAJIT"
else
	LUA=lua
	echo "use LUA"
fi
COMPUTER=`uname`
#if [ "$COMPUTER" == "Darwin" ]
#  then
#  echo "Mac Specific path helper"
#	eval `/usr/libexec/path_helper -s`
#fi

# Is "export" needed?
TERM=`which xterm`
PLATFORM=webots

# Need to export
export PLAYER_ID=$1
export TEAM_ID=$2
export USEGPS=$3

echo "===Environment Variables==="
echo Path: $PATH
echo Terminal: $TERM
echo Computer: $COMPUTER
echo Player: $PLAYER_ID
echo Team: $TEAM_ID
echo Platform: $PLATFORM
echo "==========================="

if [ "$EXT_TERM" -gt "0" ]
	then
	# In separate xterms
	exec $TERM -l -e "$LUA start.lua"
	#exec luajit -l controller start.lua
else
	# In webots console
	exec $LUA start.lua
fi

# Debugging tools
#exec xterm -l -e "/usr/bin/gdb --args lua start.lua"
#exec xterm -l -e "valgrind --tool=memcheck --leak-check=yes --dsymutil=yes luajit start.lua"
