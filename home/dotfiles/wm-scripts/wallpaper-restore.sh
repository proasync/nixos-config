#!/usr/bin/env bash
# Start the awww wallpaper daemon and re-apply the wallpaper last picked in
# waypaper (niri runs this at startup). awww-daemon forgets it on every login,
# and `waypaper --restore` alone races the daemon: it starts awww-daemon but
# runs `awww img` before the daemon's socket exists.
# With nothing picked yet (a new machine), the screen gets Catppuccin's base
# color until you choose one in waypaper.

if ! pgrep -u "$USER" -x awww-daemon >/dev/null; then
    awww-daemon &
fi

for _ in $(seq 50); do        # up to 5 s for the daemon to answer
    awww query >/dev/null 2>&1 && break
    sleep 0.1
done

if grep -q '^wallpaper = .' "$HOME/.config/waypaper/config.ini" 2>/dev/null; then
    waypaper --restore
else
    awww clear 1e1e2e
fi
