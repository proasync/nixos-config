#!/usr/bin/env bash
# Check lid state and disable eDP-1 if closed.
# Run on startup and on every hyprctl reload.

sleep 2  # wait for monitor config to apply after reload

LID_STATE=$(awk '{print $2}' /proc/acpi/button/lid/LID/state)

if [ "$LID_STATE" = "closed" ]; then
    hyprctl keyword monitor eDP-1,disabled
fi
