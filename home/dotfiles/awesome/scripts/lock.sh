#!/usr/bin/env bash
# X11 lock screen for Awesome: i3lock-color, Catppuccin Mocha with the Mauve
# accent, matching swaylock (home/dotfiles/swaylock/config) used on Wayland.
# Run by xss-lock (rc.lua) on idle, before suspend and on `loginctl
# lock-session`. -n keeps i3lock in the foreground, which xss-lock needs to
# hold the sleep lock until the screen is locked.
# Sizes follow Xft.dpi (160 on the laptop = 1.67x), as the rest of X11 does.

dpi=$(xrdb -query 2>/dev/null | awk '/^Xft.dpi:/ {print $2; exit}')
scale() { awk -v v="$1" -v d="${dpi:-96}" 'BEGIN { printf "%d", v * d / 96 + 0.5 }'; }

exec i3lock -n \
    --color=1e1e2e \
    --ignore-empty-password --show-failed-attempts \
    --radius="$(scale 110)" --ring-width="$(scale 8)" \
    --ring-color=cba6f7ff --ringver-color=89b4faff --ringwrong-color=f38ba8ff \
    --inside-color=1e1e2eff --insidever-color=1e1e2eff --insidewrong-color=1e1e2eff \
    --keyhl-color=a6e3a1ff --bshl-color=f38ba8ff \
    --line-color=00000000 --separator-color=00000000 \
    --verif-color=89b4faff --wrong-color=f38ba8ff --layout-color=cdd6f4ff \
    --verif-text="" --wrong-text="" --noinput-text="" \
    --pass-media-keys --pass-volume-keys --pass-screen-keys
