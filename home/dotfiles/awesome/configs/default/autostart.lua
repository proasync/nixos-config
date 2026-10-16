local awful = require("awful")
local gears = require("gears")

-- A host's autostart.lua may load this file with its X11 monitor layout (an
-- xrandr command) as argument, as configs/work-desktop/ does.
local x11_screen_layout = ...

-- Function to run commands once
local function run_once(cmd)
  awful.spawn.with_shell("pgrep -u $USER -fx '" .. cmd .. "' > /dev/null || (" .. cmd .. ")")
end

-- Launch Google Chrome on tag "➊" after startup settles
gears.timer.start_new(2, function()
  local s = awful.screen.focused()
  local tag = s.tags[1]
  awful.spawn("google-chrome-stable --no-default-browser-check", {
    screen = s,
    tag = tag,
    switchtotag = true,
    maximized = false,
  })
  return false -- don't repeat
end)

-- Autostart other applications. SomeWM (Wayland) shares this file: its tray
-- speaks StatusNotifier rather than XEmbed (hence --indicator), numlockx is
-- X11-only (rc.lua sets numlock there), and Flameshot's daemon is needed in
-- both: on Wayland the app that copied must stay alive to serve the clipboard.
local is_somewm = awesome.release == "somewm"
local startup_apps = is_somewm and {
  "nm-applet --indicator",
  "flameshot",
} or {
  "nm-applet",         -- Network manager applet
  "numlockx on",       -- Enable numlock
  "flameshot",         -- Screenshot daemon (needed for clipboard)
}

for _, app in ipairs(startup_apps) do
  run_once(app)
end

-- X11: the monitor layout, then the wallpaper picked in waypaper, in that order:
-- feh places it by the screen positions of the moment. SomeWM restores its
-- wallpaper in rc.lua.
if not is_somewm then
  awful.spawn.with_shell((x11_screen_layout and x11_screen_layout .. "; " or "")
    .. "~/.config/awesome/scripts/wallpaper-restore.sh")
end
