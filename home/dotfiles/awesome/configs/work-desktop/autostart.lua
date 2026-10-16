-- Monitor layout, left to right: DVI-D-0 | DisplayPort-0 (primary) | HDMI-A-0,
-- all 1920x1080 at 60 Hz. X places them in its own order, so set it at every
-- start (layout as arranged 2026-10-14). To change it, arrange with arandr and
-- copy the positions here. X11 only: SomeWM places its outputs itself
-- (configs/default/somewm.lua).
local screen_layout = "xrandr"
  .. " --output DVI-D-0 --mode 1920x1080 --rate 60 --pos 0x0"
  .. " --output DisplayPort-0 --primary --mode 1920x1080 --rate 60 --pos 1920x0"
  .. " --output HDMI-A-0 --mode 1920x1080 --rate 60 --pos 3840x0"

-- The rest is the shared autostart, loaded rather than copied so its changes
-- reach this host too. Under X11 it applies the layout, then the wallpaper.
loadfile(os.getenv("HOME") .. "/.config/awesome/configs/default/autostart.lua")(screen_layout)
