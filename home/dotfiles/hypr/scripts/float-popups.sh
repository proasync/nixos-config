#!/usr/bin/env bash
# Float browser popup windows (Chrome/Brave).
# Chrome on Wayland doesn't set xdg parent hints for popups,
# so we detect them by checking the window title for "about:blank".

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

socat -U - "UNIX-CONNECT:$SOCKET" | while read -r line; do
    case $line in
        openwindow\>\>*)
            # Event format: openwindow>>ADDR,WORKSPACE,CLASS,TITLE
            IFS=',' read -r addr _ws class title <<< "${line#*>>}"
            if [[ ("$class" == "google-chrome" || "$class" == "brave-browser") && "$title" == *"about:blank"* ]]; then
                hyprctl --batch "dispatch setfloating address:0x$addr ; dispatch resizewindowpixel exact 1200 800,address:0x$addr ; dispatch centerwindow address:0x$addr"
            fi
            ;;
    esac
done
