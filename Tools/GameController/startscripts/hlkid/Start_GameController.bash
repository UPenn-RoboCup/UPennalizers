#!/bin/bash

cd `dirname $0`
set -eu

read -p 'Enter team number for blue (default is 0): ' readBlue
read -p 'Enter team number for red (default is 0): ' readRed

declare -i blue=readBlue
declare -i red=readRed
declare broadcast=""

echo "Starting HL-Kid GameController, team ${blue} plays in blue and team ${red} plays in red"
if [ -n "${1:-""}" ]; then
  broadcast="-broadcast ${1}"
  echo "Broadcasting to subnet ${1}"
fi

java -jar GameController.jar -hlkid ${broadcast} ${blue} ${red} 
