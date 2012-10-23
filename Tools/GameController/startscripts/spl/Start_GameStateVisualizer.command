#!/bin/bash
cd `dirname $0`

set -eu

echo Starting SPL GameStateVisualizer

java -jar GameStateVisualizer.jar -spl -fullscreen &
