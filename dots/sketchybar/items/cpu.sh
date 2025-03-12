#!/usr/bin/env sh

sketchybar --add item cpu right \
  --set cpu update_freq=2 \
  icon=􀫥 \
  script="$PLUGIN_DIR/cpu.sh"
