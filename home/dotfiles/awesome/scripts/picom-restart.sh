#!/usr/bin/env bash
# (Re)start picom with a log file. `picom -b` detaches from stderr, so without
# --log-file every picom warning/error is thrown away and a frozen desktop
# leaves nothing to look at (see docs/desktop-freeze.md).
#
# Used by: Awesome autostart (rc.lua, only when picom isn't already running),
# Mod+Shift+p (restart — first thing to try when the screen stops updating but
# the cursor still moves), tv-mirror.sh and picom-toggle.sh.
#
# Logs: ~/.cache/picom/picom-<start time>.log, newest $KEEP kept. A restart
# starts a new file, so the log of a run that froze is preserved.
# More detail for one run: PICOM_LOG_LEVEL=debug picom-restart.sh
set -u

CONF=$HOME/.config/awesome/picom.conf
LOG_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/picom
LOG_LEVEL=${PICOM_LOG_LEVEL:-info}
KEEP=10
ME=$(id -un)

running() { pgrep -u "$ME" -x picom >/dev/null; }

if running; then
  pkill -u "$ME" -x picom
  # A wedged picom may ignore SIGTERM: give it 2 s, then SIGKILL.
  for _ in $(seq 20); do running || break; sleep 0.1; done
  if running; then pkill -KILL -u "$ME" -x picom; sleep 0.5; fi
  if running; then
    # Still alive after SIGKILL = stuck in the kernel (GPU driver). Starting a
    # second one would just fail with "another compositor is running".
    msg="picom did not exit (stuck in kernel?) — not restarted"
    echo "picom-restart: $msg" >&2
    notify-send -u critical "picom-restart" "$msg" 2>/dev/null
    exit 1
  fi
fi

mkdir -p "$LOG_DIR"
# Names are timestamps, so glob order is oldest first. Keep the newest KEEP-1
# plus the one about to be created.
shopt -s nullglob
logs=("$LOG_DIR"/picom-*.log)
n=$(( ${#logs[@]} - KEEP + 1 ))
(( n > 0 )) && rm -f -- "${logs[@]:0:n}"
exec picom -b --config "$CONF" \
  --log-level "$LOG_LEVEL" \
  --log-file "$LOG_DIR/picom-$(date +%Y%m%d-%H%M%S).log"
