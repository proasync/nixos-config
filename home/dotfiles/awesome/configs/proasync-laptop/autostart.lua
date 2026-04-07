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

-- Monitor setup (detect external monitors, set DPI accordingly)
awful.spawn.with_shell("~/.config/awesome/scripts/monitor-setup.sh")

-- Autostart other applications
local startup_apps = {
  "nm-applet",         -- Network manager applet
  "numlockx on",       -- Enable numlock
  "flameshot",         -- Screenshot daemon (needed for clipboard)
}

for _, app in ipairs(startup_apps) do
  run_once(app)
end
