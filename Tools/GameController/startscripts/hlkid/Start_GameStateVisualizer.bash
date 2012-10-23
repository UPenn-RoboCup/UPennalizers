#!/bin/bash

cd `dirname $0`
set -eu
echo Starting HL-Kid GameStateVisualizer

java -jar GameStateVisualizer.jar -hlkid
