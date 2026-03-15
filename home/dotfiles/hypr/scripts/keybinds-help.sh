#!/usr/bin/env bash
# Keybindings cheat sheet — Catppuccin Mocha colors

# Catppuccin Mocha ANSI colors
MAUVE='\033[38;2;203;166;247m'
BLUE='\033[38;2;137;180;250m'
GREEN='\033[38;2;166;227;161m'
PEACH='\033[38;2;250;179;135m'
TEXT='\033[38;2;205;214;244m'
SUBTEXT='\033[38;2;166;173;200m'
DIM='\033[38;2;88;91;112m'
BOLD='\033[1m'
R='\033[0m'

header() { echo -e "\n ${MAUVE}${BOLD}── $1 ──${R}"; }
key() { printf "   ${BLUE}%-24s${R} ${TEXT}%s${R}\n" "$1" "$2"; }

echo -e "${BOLD}${GREEN}"
echo "   ╦ ╦╦ ╦╔═╗╦═╗╦  ╔═╗╔╗╔╔╦╗  ╦╔═╔═╗╦ ╦╔═╗"
echo "   ╠═╣╚╦╝╠═╝╠╦╝║  ╠═╣║║║ ║║  ╠╩╗║╣ ╚╦╝╚═╗"
echo "   ╩ ╩ ╩ ╩  ╩╚═╩═╝╩ ╩╝╚╝═╩╝  ╩ ╩╚═╝ ╩ ╚═╝"
echo -e "${R}"

header "Core"
key "Super + Return"       "Terminal (Alacritty)"
key "Super + Shift + Return" "File manager (Thunar)"
key "Super + Q"            "Close window"
key "Super + F"            "Fullscreen"
key "Super + M"            "Maximize (monocle)"
key "Super + Shift + Space" "Toggle floating"
key "Super + Escape"       "Kill window (xkill)"

header "Focus (vim)"
key "Super + H/J/K/L"     "Focus left/down/up/right"
key "Ctrl+Super + Arrows"  "Focus (arrow keys)"

header "Move windows"
key "Super + Shift + H/J/K/L" "Move left/down/up/right"

header "Layout control"
key "Super + S"            "Toggle split (horiz/vert)"

header "Resize windows"
key "Super + Ctrl + H/J/K/L" "Resize left/down/up/right"

header "Workspaces"
key "Super + 1-9"          "Switch to workspace 1-9"
key "Super + Shift + 1-9"  "Move window to workspace"
key "Super + Tab"          "Next workspace (wraps)"
key "Super + Shift + Tab"  "Prev workspace (wraps)"
key "Alt + Tab / Shift+Tab" "Next/prev workspace"
key "Super + Scroll"       "Scroll workspaces"

header "Monitors"
key "Super + , / ."        "Focus prev/next monitor"
key "Super + Shift + , / ." "Move window to monitor"

header "Launchers"
key "Super + R"            "Rofi app launcher"
key "Super + X"            "Power menu"
key "Super + D"            "Display settings"
key "Super + V"            "Volume control"
key "Super + P"            "Screenshot (select)"

header "Apps"
key "Super + F1"           "Chrome"
key "Super + F2"           "VS Code"
key "Super + F3"           "Teams"
key "Super + F4"           "DBeaver"
key "Super + F5"           "GIMP"
key "Super + F6"           "Inkscape"

header "Media"
key "Volume Up/Down/Mute"  "Audio control"
key "Brightness Up/Down"   "Screen brightness"
key "Ctrl+Shift + M"       "Volume 100%"
key "Ctrl+Shift + 0"       "Volume 0% (mute)"

header "Toggles"
key "Super + W"            "This help window"
key "Super + B"            "Toggle waybar"
key "Super + T"            "Toggle touchpad"
key "Super + I"            "Pin window (all workspaces)"
key "Super + O"            "Toggle scratchpad"
key "Super + Shift + O"    "Send window to scratchpad"
key "Super + Ctrl + Esc"   "Emergency: drop to TTY"

echo -e "\n ${DIM}Press q to close${R}\n"
