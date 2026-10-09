#!/bin/bash
if pgrep -x "picom" > /dev/null
then
	killall picom
else
	~/.config/awesome/scripts/picom-restart.sh
fi
