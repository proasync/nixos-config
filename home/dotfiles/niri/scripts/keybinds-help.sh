#!/usr/bin/env bash
# niri keybindings cheat sheet (Mod+W) — Catppuccin Mocha colors.
# Written by hand from the binds block in ../config.kdl: change both together.
# Hyprland's own sheet is home/dotfiles/hypr/scripts/keybinds-help.sh.

MAUVE='\033[38;2;203;166;247m'
BLUE='\033[38;2;137;180;250m'
GREEN='\033[38;2;166;227;161m'
TEXT='\033[38;2;205;214;244m'
DIM='\033[38;2;88;91;112m'
BOLD='\033[1m'
R='\033[0m'

header() { echo -e "\n ${MAUVE}${BOLD}── $1 ──${R}"; }
key() { printf "   ${BLUE}%-26s${R} ${TEXT}%s${R}\n" "$1" "$2"; }

echo -e "${BOLD}${GREEN}"
echo "   ╔╗╔╦╦═╗╦  ╦╔═╔═╗╦ ╦╔═╗"
echo "   ║║║║╠╦╝║  ╠╩╗║╣ ╚╦╝╚═╗"
echo "   ╝╚╝╩╩╚═╩  ╩ ╩╚═╝ ╩ ╚═╝"
echo -e "${R}"

header "Core"
key "Super + Return"          "Terminal (Alacritty)"
key "Super + Shift + Return"  "File manager (Thunar)"
key "Super + Q"               "Close window"
key "Super + F"               "Maximize column"
key "Super + Shift + F"       "Fullscreen"
key "Super + Shift + Space"   "Toggle floating"
key "Super + O"               "Overview (all workspaces)"
key "Super + Escape"          "Quit niri (asks first)"

header "Focus (vim)"
key "Super + H / L"           "Focus column left/right"
key "Super + K / J"           "Focus window or workspace up/down"
key "Ctrl+Super + Arrows"     "Same, with arrow keys"

header "Move"
key "Super + Shift + H / L"   "Move column left/right"
key "Super + Shift + K / J"   "Move window up/down (or to workspace)"
key "Super + drag"            "Move window (right-drag: resize)"

header "Columns"
key "Super + [ / ]"           "Pull window into / push out of column"
key "Super + ="               "Cycle column width (1/3, 1/2, 2/3)"
key "Super + Shift + ="       "Cycle window height"
key "Super + Ctrl + H / L"    "Column width -/+ 5%"
key "Super + Ctrl + K / J"    "Window height -/+ 5%"

header "Workspaces"
key "Super + 1-9"             "Focus workspace 1-9"
key "Super + Shift + 1-9"     "Move column to workspace"
key "Super + Tab / Shift+Tab" "Workspace down/up (no wrap)"
key "Super + Scroll"          "Workspace down/up"

header "Monitors"
key "Super + , / ."           "Focus monitor left/right"
key "Super + Shift + , / ."   "Move column to monitor"

header "Launchers"
key "Super + R"               "Rofi app launcher"
key "Super + X"               "Power menu (k = lock)"
key "Super + D"               "Display settings (saves this host's monitor.kdl)"
key "Super + V"               "Volume control"
key "Super + P"               "Screenshot (select an area)"
key "Print"                   "Screenshot whole screen"
key "Super + Print"           "Screenshot focused window"
key "Ctrl + Shift + Escape"   "Task manager (htop)"

header "Apps"
key "Super + F1"              "Chrome"
key "Super + F2"              "VS Code"
key "Super + F3"              "Teams"
key "Super + F4"              "DBeaver"
key "Super + F5"              "GIMP"
key "Super + F6"              "Inkscape"

header "Media"
key "Volume Up/Down/Mute"     "Audio control"
key "Brightness Up/Down"      "Screen brightness"
key "Ctrl + Shift + M"        "Volume 100%"
key "Ctrl + Shift + 0"        "Volume 0%"

header "Toggles"
key "Super + W"               "This help window"
key "Super + B"               "Toggle waybar"
key "Super + T"               "Touchpad toggle (not supported in niri)"
key "Super + Space"           "Switch keyboard layout (us/se)"
key "Super + Ctrl + Escape"   "Emergency: end the session"

header "Locking"
key "Idle 10 min"             "Screen locks; screens go off 30 s later"
key "Suspend"                 "Locks first"

echo -e "\n ${DIM}Press q to close${R}\n"
