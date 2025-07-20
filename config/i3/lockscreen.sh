#!/bin/bash

# Run i3lock-color with blur and custom style (no wallpaper)
i3lock-color --blur 5 \
  --clock --indicator \
  --inside-color=373445ff --ring-color=ffffffff \
  --line-uses-ring --ring-width=6 --radius=120 \
  --keyhl-color=d23c3dff --bshl-color=d23c3dff \
  --separator-color=00000000 --time-color=ffffffff \
  --date-color=aaaaaaff --verif-text="Verifying..." \
  --wrong-text="Wrong" --noinput-text="No Input"
