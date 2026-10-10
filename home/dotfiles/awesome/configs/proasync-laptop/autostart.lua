local awful = require("awful")
local gears = require("gears")

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

-- Monitor setup (detect external monitors, set DPI accordingly). X11 only:
-- xrandr/xrdb/feh. SomeWM's layout is in configs/proasync-laptop/somewm.lua.
if awesome.release ~= "somewm" then
  awful.spawn.with_shell("~/.config/awesome/scripts/monitor-setup.sh")
end

-- Autostart other applications. SomeWM (Wayland) shares this file: its tray
-- speaks StatusNotifier rather than XEmbed (hence --indicator), numlockx and
-- flameshot are X11-only, and rc.lua starts the Wayland counterparts.
local is_somewm = awesome.release == "somewm"
local startup_apps = is_somewm and {
  "nm-applet --indicator",
} or {
  "nm-applet",         -- Network manager applet
  "numlockx on",       -- Enable numlock
  "flameshot",         -- Screenshot daemon (needed for clipboard)
}

for _, app in ipairs(startup_apps) do
  run_once(app)
end
