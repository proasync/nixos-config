#!/usr/bin/env bash
# Cycle through workspaces 1-9 with wrap-around
CURRENT=$(hyprctl activeworkspace -j | jq '.id')
MAX=9

if [ "$1" = "next" ]; then
    NEXT=$(( (CURRENT % MAX) + 1 ))
else
    NEXT=$(( ((CURRENT - 2 + MAX) % MAX) + 1 ))
fi

hyprctl dispatch workspace "$NEXT"
