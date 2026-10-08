#!/usr/bin/env bash
# Mirror the laptop panel (eDP-1) onto whatever external display is plugged in
# (HDMI, or DP-* via a USB-C adapter) — for demos/presentations on unknown TVs.
#
# Why it is this careful (see docs/external-display.md):
#   - 2026-09-25: switching an external output OFF while picom (glx, vsync) was
#     running wedged the laptop CRTC ("Present-flip ... Device or resource busy")
#     → both screens black, hard reboot, lost work. So picom is stopped before
#     any output change and only restarted once the external is off again.
#   - 4K@60 over this laptop's HDMI (max TMDS 300 MHz) needs YCbCr 4:2:0 and
#     went black after a while. We never use it: 1080p first, then smaller.
#   - The laptop panel is never passed to xrandr. Only the external output is
#     touched, in both directions, so the panel keeps its mode no matter what.
#   - The framebuffer stays 2880x1800 (the external's footprint fits inside it),
#     so X never resizes the screen → no implicit modeset on the panel.
#
# Aspect: the panel is 16:10, TVs are 16:9. By default the bottom 180 px of the
# desktop are reserved via Awesome screen padding and the TV shows the top
# 2880x1620 → correct aspect, nothing important hidden (bar is at the top).
# `--stretch` shows the whole desktop instead, ~11 % wider on the TV.
#
# Usage: tv-mirror.sh on [--stretch] | off | status
# Do NOT restart Awesome or log in with the TV attached: monitor-setup.sh runs
# at Awesome start and will re-arrange outputs (extended, TV's preferred mode).
set -u

INTERNAL=eDP-1
RUN=${XDG_RUNTIME_DIR:-/tmp}
STATE=$RUN/tv-mirror.state
LOG=$RUN/tv-mirror.log
PICOM_CONF=$HOME/.config/awesome/picom.conf

log() { echo "$(date +%T) $*" | tee -a "$LOG"; }
die() { log "ABORT: $*"; exit 1; }

# First connected output that isn't the panel.
external() { xrandr | awk -v i="$INTERNAL" '$2=="connected" && $1!=i {print $1; exit}'; }
# Mode lines listed under an output.
modes_of() { xrandr | sed -n "/^$1 connected/,/^[^ ]/p" | tail -n +2 | awk '{print $1}'; }
# Largest sane mode the TV offers: 1080p if it has it, otherwise smaller.
pick_mode() {
  local m
  for m in 1920x1080 1920x1200 1680x1050 1600x900 1280x800 1280x720 1024x768; do
    modes_of "$1" | grep -qx "$m" && { echo "$m"; return; }
  done
  # Nothing from the list — use the TV's preferred mode as a last resort.
  xrandr | sed -n "/^$1 connected/,/^[^ ]/p" | grep '+' | awk '{print $1}' | head -1
}
panel_mode() { xrandr | awk -v i="$INTERNAL" '$1==i && $2=="connected" {print $0}' | grep -oE '[0-9]+x[0-9]+\+0\+0' | head -1; }
panel_ok() { xrandr | grep -q "^$INTERNAL connected primary [0-9]*x[0-9]*+0+0"; }

set_padding() {  # bottom padding on every Awesome screen
  printf 'for s in screen do s.padding = { left = 0, right = 0, top = 0, bottom = %d } end\n' "$1" \
    | awesome-client >/dev/null 2>&1
}

status() {
  xrandr --listmonitors
  xrandr | grep -E '^[A-Za-z0-9-]+ (dis)?connected'
  echo "picom: $(pgrep -x picom >/dev/null && echo running || echo stopped)"
  echo "flip errors since boot: $(journalctl -b 0 --no-pager 2>/dev/null | grep -c 'Present-flip')"
  [ -e "$STATE" ] && echo "state: $(cat "$STATE")"
}

case "${1:-}" in
  on)
    stretch=0; [ "${2:-}" = "--stretch" ] && stretch=1
    panel_ok || die "$INTERNAL is not active/primary at +0+0 — not touching anything"
    ext=$(external); [ -n "$ext" ] || die "no external display connected"
    xrandr | grep -qE "^$ext connected [0-9]" && die "$ext already active — run 'off' first"
    mode=$(pick_mode "$ext"); [ -n "$mode" ] || die "no usable mode on $ext"

    geom=$(panel_mode); pw=${geom%%x*}; ph=${geom#*x}; ph=${ph%%+*}
    if [ $stretch = 1 ]; then
      from="${pw}x${ph}"; pad=0
    else
      fh=$(( pw * 9 / 16 )); [ $fh -gt $ph ] && fh=$ph
      from="${pw}x${fh}"; pad=$(( ph - fh ))
    fi

    picom_was=0
    if pgrep -x picom >/dev/null; then
      picom_was=1; log "stopping picom"; pkill -x picom
      for _ in $(seq 20); do pgrep -x picom >/dev/null || break; sleep 0.25; done
      pgrep -x picom >/dev/null && die "picom still running"
      sleep 1
    fi
    echo "ext=$ext picom=$picom_was pad=$pad" >"$STATE"

    [ $pad -gt 0 ] && { log "awesome padding bottom=$pad"; set_padding "$pad"; }
    log "$ext on: $mode, showing ${from} of the panel"
    if ! xrandr --output "$ext" --mode "$mode" --scale-from "$from" --same-as "$INTERNAL"; then
      log "xrandr failed — $ext off"; xrandr --output "$ext" --off; set_padding 0
      status; exit 1
    fi
    panel_ok || log "WARNING: panel state changed — check the screen; 'off' restores"
    status | tee -a "$LOG"
    log "mirror ON. Nothing turns it off automatically; run 'tv-mirror.sh off' when done (before unplugging if you can)."
    ;;
  off)
    ext=""; picom_was=0
    # shellcheck disable=SC1090
    [ -e "$STATE" ] && { eval "$(sed 's/ /;/g' "$STATE")"; ext=${ext:-}; picom_was=${picom:-0}; }
    [ -n "$ext" ] || ext=$(xrandr | awk -v i="$INTERNAL" '$1!=i && $2 ~ /connected/ && $3 ~ /^[0-9]+x[0-9]+\+/ {print $1; exit}')
    pgrep -x picom >/dev/null && die "picom is running — it must be stopped before an output is switched off (pkill -x picom)"
    if [ -n "$ext" ]; then log "$ext off"; xrandr --output "$ext" --off; else log "no active external output"; fi
    set_padding 0
    if [ "$picom_was" = 1 ]; then
      sleep 1; log "starting picom"; picom -b --config "$PICOM_CONF"
    fi
    rm -f "$STATE"
    status | tee -a "$LOG"
    ;;
  status) status ;;
  *) echo "usage: $0 on [--stretch] | off | status"; exit 2 ;;
esac
