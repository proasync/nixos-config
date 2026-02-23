#!/usr/bin/env bash
STATE_FILE="/tmp/hypr-touchpad-disabled"

if [ -f "$STATE_FILE" ]; then
    hyprctl keyword "device[asue1214:00-04f3:328b-touchpad]:enabled" true
    rm "$STATE_FILE"
    notify-send -t 2000 "Touchpad" "Enabled"
else
    hyprctl keyword "device[asue1214:00-04f3:328b-touchpad]:enabled" false
    touch "$STATE_FILE"
    notify-send -t 2000 "Touchpad" "Disabled"
fi
