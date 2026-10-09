#!/usr/bin/env bash
# Restore the X11 wallpaper (run by monitor-setup.sh at Awesome start).
# nitrogen was removed from nixpkgs (2026-10, it needed gtk2); feh replaces it.
#
# Change the wallpaper:  feh --bg-scale <screen0 image> [<screen1 image>]
#   (screen 0 = laptop panel, screen 1 = external; --bg-fill crops instead of
#   stretching). feh records the command in ~/.fehbg, which this replays.
# Images live in ~/.config/wallpapers (= home/dotfiles/wallpapers, Git LFS).
set -u

if [ -x "$HOME/.fehbg" ]; then exec "$HOME/.fehbg"; fi

# First run: the same images and mode (scaled) nitrogen had saved.
W=$HOME/.config/wallpapers
exec feh --bg-scale \
  "$W/login/mountain-peak-5120x2880-24313.jpg" \
  "$W/ultrawide/UltrawideWallpapersDotNet-82.jpeg"
