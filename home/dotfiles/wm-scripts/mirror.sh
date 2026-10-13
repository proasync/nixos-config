#!/usr/bin/env bash
# Mirror one screen onto another under Wayland (SomeWM, niri). Neither
# compositor mirrors outputs itself; wl-mirror shows a live copy of SOURCE
# fullscreen on TARGET, captured through wlr-screencopy. Awesome (X11) has
# ~/.config/awesome/scripts/tv-mirror.sh instead (docs/external-display.md).
#
# Usage: mirror.sh on [TARGET [SOURCE]] | off | status
#   SOURCE: the laptop panel eDP-1, or the first screen if there is none.
#   TARGET: the first other enabled screen; with eDP-1 as SOURCE, not the
#           laptop's desk monitor DP-1 (a TV comes as HDMI-A-1 or another DP-n).
#   Names as `wlr-randr` lists them.
#
# The TV keeps its own mode and scale: under SomeWM the laptop's somewm.lua
# gives a new TV 1080p@60 at scale 1. The copy is scaled to fit, so the 16:10
# panel shows on a 16:9 TV with thin bars at the sides.
set -u

enabled_outputs() {
  wlr-randr | awk '/^[^ ]/ { name = $1 } /^  Enabled: yes/ { print name }'
}

case "${1:-}" in
  on)
    mapfile -t outs < <(enabled_outputs)
    target=${2:-}
    source=${3:-}
    if [ -z "$source" ]; then
      for o in "${outs[@]}"; do [ "$o" = eDP-1 ] && source=eDP-1; done
      [ -z "$source" ] && source=${outs[0]:-}
    fi
    if [ -z "$target" ]; then
      for o in "${outs[@]}"; do
        [ "$o" = "$source" ] && continue
        [ "$source" = eDP-1 ] && [ "$o" = DP-1 ] && continue
        target=$o
        break
      done
    fi
    if [ -z "$source" ] || [ -z "$target" ]; then
      echo "mirror.sh: no second screen to mirror onto (screens: ${outs[*]:-none})" >&2
      exit 1
    fi
    pkill -u "$USER" -x wl-mirror
    setsid -f wl-mirror --fullscreen-output "$target" "$source" >/dev/null 2>&1
    echo "mirroring $source onto $target"
    ;;
  off)
    pkill -u "$USER" -x wl-mirror && echo "mirror off" || echo "mirror was not running"
    ;;
  status)
    pgrep -a -u "$USER" -x wl-mirror || echo "mirror off"
    ;;
  *)
    echo "usage: mirror.sh on [TARGET [SOURCE]] | off | status" >&2
    exit 2
    ;;
esac
