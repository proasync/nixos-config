local awful = require("awful")

-- Monitor layout, left to right: DVI-D-0 | DisplayPort-0 (primary) | HDMI-A-0,
-- all 1920x1080 at 60 Hz. X places them in its own order, so set it at every
-- start (layout as arranged 2026-10-14). To change it, arrange with arandr and
-- copy the positions here. X11 only: SomeWM's layout is in somewm.lua here.
local screen_layout = "xrandr"
  .. " --output DVI-D-0 --mode 1920x1080 --rate 60 --pos 0x0"
  .. " --output DisplayPort-0 --primary --mode 1920x1080 --rate 60 --pos 1920x0"
  .. " --output HDMI-A-0 --mode 1920x1080 --rate 60 --pos 3840x0"

-- The rest is the shared autostart, loaded rather than copied so its changes
-- reach this host too. Under X11 it applies the layout, then the wallpaper.
-- Chrome opens on tag 1 of the right-hand monitor: HDMI-A-1 under SomeWM,
-- HDMI-A-0 under X11.
loadfile(os.getenv("HOME") .. "/.config/awesome/configs/default/autostart.lua")({
  x11_screen_layout = screen_layout,
  chrome_output = { "HDMI-A-1", "HDMI-A-0" },
})

-- Teams, Signal, WhatsApp and Spotify, which rules.lua here puts on the same
-- monitor (tags 2, 7, 8, 9). Started only if not running yet (an Awesome
-- restart re-runs this file). pgrep runs without a shell: a shell command line
-- holding the app's name would match itself.
for _, app in ipairs({ "teams-for-linux", "signal-desktop", "whatsapp-electron", "spotify" }) do
  awful.spawn.easy_async({ "pgrep", "-u", os.getenv("USER") or "proasync", "-f", app },
    function(_, _, _, code)
      if code ~= 0 then awful.spawn(app) end
    end)
end
