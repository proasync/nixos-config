#!/usr/bin/env bash

# Rofi power menu for Awesome WM
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
    12) # Logout. SomeWM (Wayland) shares this config; it has its own IPC client.
        if [ "${XDG_CURRENT_DESKTOP:-}" = somewm ]; then somewm-client eval 'awesome.quit()'
        else awesome-client 'awesome.quit()'; fi ;;
    13) # Lock: SomeWM runs swaylock directly. On X11 this asks logind, and
        # nothing in the X11 session answers that yet, so it does not lock.
        if [ "${XDG_CURRENT_DESKTOP:-}" = somewm ]; then ~/.config/wm-scripts/lock.sh
        else loginctl lock-session; fi ;;
    14) systemctl suspend ;;
esac
