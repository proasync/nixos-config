#!/usr/bin/env bash
# Lock the Wayland session with swaylock (theme: ~/.config/swaylock/config).
# Used by powermenu.sh and by niri's swayidle (idle timeout, before sleep).
# -f returns once the screen is locked, so swayidle's before-sleep waits for
# the lock; the pgrep keeps a second swaylock from stacking on the first.
pgrep -u "$USER" -x swaylock >/dev/null || exec swaylock -f
