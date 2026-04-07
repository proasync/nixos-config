#!/usr/bin/env bash
# Monitor setup for Awesome WM on proasync-laptop
# Auto-detects external monitors on any port (HDMI-1, DP-1, DP-2, etc.)

# Find all connected external outputs
EXTERNALS=$(xrandr | grep ' connected' | grep -v 'eDP-1' | awk '{print $1}')

if [ -n "$EXTERNALS" ]; then
    # External monitor(s) detected
    # Build xrandr command: place externals left-to-right, laptop screen last
    CMD="xrandr"
    POS_X=0

    for OUTPUT in $EXTERNALS; do
        # Use the preferred/native mode (marked with +)
        MODE=$(xrandr | sed -n "/$OUTPUT connected/,/^[^ ]/p" | grep '+' | awk '{print $1}' | head -1)
        CMD="$CMD --output $OUTPUT --mode $MODE --pos ${POS_X}x0 --scale 1x1"

        # Get width for next monitor position
        WIDTH=$(echo "$MODE" | cut -d'x' -f1)
        POS_X=$((POS_X + WIDTH))
    done

    # Place laptop screen to the right of externals
    CMD="$CMD --output eDP-1 --mode 2880x1800 --pos ${POS_X}x0 --scale 1x1"

    # Set the first external as primary
    FIRST=$(echo "$EXTERNALS" | head -1)
    CMD="$CMD --output $FIRST --primary"

    eval "$CMD"

    # Mixed DPI setup — drop to 96 for external monitors
    echo "Xft.dpi: 96" | xrdb -merge
else
    # Laptop only — use HiDPI
    xrandr --output eDP-1 --mode 2880x1800 --pos 0x0 --scale 1x1 --primary
    echo "Xft.dpi: 160" | xrdb -merge
fi

# Restore wallpapers after monitor change
nitrogen --restore &
