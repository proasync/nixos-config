#!/usr/bin/env bash

# Rofi power menu for Hyprland
# Single keypress: s=Shutdown, r=Reboot, l=Logout, k=Lock, u=Suspend
# Or use arrow keys + Enter to select

rofi -dmenu -i \
    -p "Power" \
    -theme ~/.config/rofi/powermenu.rasi \
    -kb-custom-1 "s" \
    -kb-custom-2 "r" \
    -kb-custom-3 "l" \
    -kb-custom-4 "k" \
    -kb-custom-5 "u" \
    <<< "$(printf "[s] Shutdown\n[r] Reboot\n[l] Logout\n[k] Lock\n[u] Suspend")" \
    > /dev/null 2>&1

code=$?

case $code in
    10) systemctl poweroff ;;
    11) systemctl reboot ;;
    12) hyprctl dispatch exit ;;
    13) hyprlock ;;
    14) systemctl suspend ;;
esac
