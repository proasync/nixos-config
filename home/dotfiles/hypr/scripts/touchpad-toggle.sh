#!/usr/bin/env bash
# Toggle the touchpad under Hyprland. The device is looked up by name rather
# than hardcoded, so on desktops (no touchpad) this says so instead of
# pretending to toggle. niri has no runtime input toggle (set `touchpad { off }`
# in niri/config.kdl instead), but binds this script too, so handle that.
if [ -n "${NIRI_SOCKET:-}" ]; then
    notify-send -t 2000 "Touchpad" "Toggle not supported under niri"
    exit 1
fi

DEVICE=$(hyprctl devices -j | jq -r '.mice[].name | select(test("touchpad"; "i"))' | head -n1)
if [ -z "$DEVICE" ]; then
    notify-send -t 2000 "Touchpad" "No touchpad found"
    exit 1
fi

STATE_FILE="/tmp/hypr-touchpad-disabled"

if [ -f "$STATE_FILE" ]; then
    hyprctl keyword "device[$DEVICE]:enabled" true
    rm "$STATE_FILE"
    notify-send -t 2000 "Touchpad" "Enabled"
else
    hyprctl keyword "device[$DEVICE]:enabled" false
    touch "$STATE_FILE"
    notify-send -t 2000 "Touchpad" "Disabled"
fi
