#!/usr/bin/env bash
# Restore the X11 wallpaper at Awesome start, after the monitor layout: run by
# configs/default/autostart.lua, and on the laptop by monitor-setup.sh.
#
# Change the wallpaper in waypaper. Under X11 it sets it with feh, under
# Wayland with awww (home/packages/waypaper.nix), so Awesome, SomeWM and niri
# share the one picked last. A per-monitor pick made under Wayland shows on
# every screen here (feh's mode in waypaper is all screens).
# Without a waypaper pick, this replays ~/.fehbg: what feh set last, e.g.
# `feh --bg-fill <img> [<img> …]` for one image per screen. nitrogen was
# removed from nixpkgs (2026-10, it needed gtk2); feh replaces it.
# Images live in ~/.config/wallpapers (= home/dotfiles/wallpapers, Git LFS).
set -u

if grep -q '^wallpaper = .' "$HOME/.config/waypaper/config.ini" 2>/dev/null; then
  exec waypaper --restore
fi
if [ -x "$HOME/.fehbg" ]; then exec "$HOME/.fehbg"; fi

# First run: the same images and mode (scaled) nitrogen had saved.
W=$HOME/.config/wallpapers
exec feh --bg-scale \
  "$W/login/mountain-peak-5120x2880-24313.jpg" \
  "$W/ultrawide/UltrawideWallpapersDotNet-82.jpeg"
