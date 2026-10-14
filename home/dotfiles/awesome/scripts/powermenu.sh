#!/usr/bin/env bash

# Rofi power menu for Awesome WM
# Single keypress: s=Shutdown, r=Reboot, l=Logout, k=Lock, u=Suspend
# Or use arrow keys + Enter to select

# Awesome on X11 needs the laptop panel's big sizes; SomeWM (Wayland, which
# runs this script too) scales rofi itself. See ~/.config/rofi/launcher.rasi.
theme=powermenu-x11.rasi
[ -n "${WAYLAND_DISPLAY:-}" ] && theme=powermenu.rasi

rofi -dmenu -i \
    -p "Power" \
    -theme ~/.config/rofi/$theme \
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
    13) # Lock: SomeWM runs swaylock directly. On X11 logind asks xss-lock,
        # which runs scripts/lock.sh (i3lock-color); started by rc.lua.
        if [ "${XDG_CURRENT_DESKTOP:-}" = somewm ]; then ~/.config/wm-scripts/lock.sh
        else loginctl lock-session; fi ;;
    14) systemctl suspend ;;
esac
