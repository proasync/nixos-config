#!/usr/bin/env bash

# Rofi power menu for the Wayland compositors (niri; Hyprland if it comes back)
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
    12) # Logout: this menu is shared by Hyprland and niri (Mod+X in both)
        if [ -n "${NIRI_SOCKET:-}" ]; then niri msg action quit --skip-confirmation
        else hyprctl dispatch exit; fi ;;
    13) # Lock: hyprlock under Hyprland (theme in ~/.config/hypr/hyprlock.conf), swaylock elsewhere
        if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then hyprlock
        else ~/.config/wm-scripts/lock.sh; fi ;;
    14) systemctl suspend ;;
esac
