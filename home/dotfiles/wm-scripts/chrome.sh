#!/usr/bin/env bash
# Launch Chrome, clearing a stale singleton lock if Chrome is not actually running.
# On Wayland, Chrome silently fails when a stale lock exists because it can't
# render the "profile in use" dialog without an existing window.

if ! pgrep -f google-chrome > /dev/null; then
    rm -f ~/.config/google-chrome/Singleton{Lock,Cookie,Socket}
fi

exec google-chrome-stable "$@"
