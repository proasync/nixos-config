#!/usr/bin/env bash
# Restore the X11 wallpaper at Awesome start, after the monitor layout: run by
# configs/default/autostart.lua, and on the laptop by monitor-setup.sh.
#
# Change the wallpaper in waypaper, per monitor or for all of them. Under X11 it
# sets it with xwallpaper, under Wayland with awww (home/packages/waypaper.nix);
# the picks share one config, so an "All" pick shows in Awesome, SomeWM and
# niri, and a per-monitor pick where that monitor name exists.
# Without a waypaper pick, this replays ~/.fehbg: what feh set last, e.g.
# `feh --bg-fill <img> [<img> …]` for one image per screen. nitrogen was
# removed from nixpkgs (2026-10, it needed gtk2); feh replaces it.
# Images live in ~/.config/wallpapers (= home/dotfiles/wallpapers, Git LFS).
set -u

cfg=$HOME/.config/waypaper/config.ini
if grep -q '^wallpaper = .' "$cfg" 2>/dev/null; then
  # One xwallpaper call for all monitors. `waypaper --restore` starts one
  # setter per monitor at once, and before the first wallpaper of a login
  # exists they race: only one monitor keeps its image. "All" comes first in
  # waypaper's list, so the per-monitor picks after it win. xwallpaper skips
  # outputs this X server does not have (SomeWM's names, like DP-1).
  python3 - "$cfg" <<'PY' && exit 0
import configparser, os, sys
s = configparser.ConfigParser(interpolation=None)
s.read(sys.argv[1])
s = s["Settings"]
fill = {"fill": "--zoom", "fit": "--maximize", "center": "--center",
        "stretch": "--stretch", "tile": "--tile"}.get(s.get("fill", "fill").lower(), "--zoom")
args = []
for mon, img in zip(s.get("monitors", "All").split("\n"), s.get("wallpaper", "").split("\n")):
    img = os.path.expanduser(img.strip())
    if os.path.isfile(img):
        args += ["--output", "all" if mon.strip() == "All" else mon.strip(), fill, img]
if not args:
    sys.exit(1)  # nothing usable: fall back to ~/.fehbg below
os.execvp("xwallpaper", ["xwallpaper"] + args)
PY
fi
if [ -x "$HOME/.fehbg" ]; then exec "$HOME/.fehbg"; fi

# First run: the same images and mode (scaled) nitrogen had saved.
W=$HOME/.config/wallpapers
exec feh --bg-scale \
  "$W/login/mountain-peak-5120x2880-24313.jpg" \
  "$W/ultrawide/UltrawideWallpapersDotNet-82.jpeg"
