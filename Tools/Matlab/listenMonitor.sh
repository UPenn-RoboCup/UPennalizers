#!/bin/sh

cd ../../Player
export COMPUTER=`uname -s`
if [ $1 == "team" ]
	then 
		exec lua listen_team_monitor.lua
	else
		exec lua listen_monitor.lua
fi
