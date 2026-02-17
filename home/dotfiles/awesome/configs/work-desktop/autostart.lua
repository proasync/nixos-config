local awful = require("awful")
local naughty = require("naughty") -- For notifications

-- Function to run commands once
local function run_once(cmd)
  awful.spawn.with_shell("pgrep -u $USER -fx '" .. cmd .. "' > /dev/null || (" .. cmd .. ")")
end

-- Autostart other applications
local startup_apps = {
  "nm-applet",
  "pamac-tray",
  "xfce4-power-manager",
  "blueberry-tray",
  "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1",
  "numlockx on",
  "volumeicon",
  "dbeaver",         -- Start DBeaver
  "teams-for-linux", -- Start Teams
  "spotify",         -- Start Spotify
  "signal-desktop",  -- Start Signal
  "whatsdesk",       -- Start Whatsdesk
  "nitrogen --restore"
}

for _, app in ipairs(startup_apps) do
  run_once(app)
end
