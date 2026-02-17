local awful = require("awful")

-- Function to run commands once
local function run_once(cmd)
  awful.spawn.with_shell("pgrep -u $USER -fx '" .. cmd .. "' > /dev/null || (" .. cmd .. ")")
end

-- Launch applications with specific tag placement at startup
awful.spawn(function()
  -- Launch Google Chrome on screen 1, tag "➊" on startup
  local screen_index = 1
  local tag_name = "➊"
  local cmd = "google-chrome-stable --no-default-browser-check"

  -- Start the application
  awful.spawn(cmd, {
    screen = screen_index,
    tag = awful.tag.find_by_name(awful.screen.getbyindex(screen_index), tag_name),
    switchtotag = true, -- Optionally switch to the tag when launching
    maximized = false,  -- Tile with other windows
  })
end)

-- Autostart other applications
local startup_apps = {
  "nm-applet",         -- Network manager applet
  "numlockx on",       -- Enable numlock
  "nitrogen --restore", -- Restore wallpapers (per-screen)
  "flameshot",         -- Screenshot daemon (needed for clipboard)
}

for _, app in ipairs(startup_apps) do
  run_once(app)
end
