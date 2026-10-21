-- work-desktop output layout under SomeWM (Wayland), loaded by rc.lua only
-- there. Left to right: DVI-D-1 | DP-1 | HDMI-A-1, all 1920x1080 at their
-- preferred 60 Hz and scale 1, as arranged in wdisplays on 2026-10-16. The
-- same order as under X11 (autostart.lua here), where the outputs are named
-- DVI-D-0, DisplayPort-0 and HDMI-A-0. wdisplays can change it live, until the
-- next plug, unplug or output switched back on runs arrange() again.

local gears = require("gears")

local x_of = { ["DVI-D-1"] = 0, ["DP-1"] = 1920, ["HDMI-A-1"] = 3840 }

local function arrange()
    for o in output do
        local x = x_of[o.name]
        if x then
            o.scale = 1.0
            o.position = { x = x, y = 0 }
        end
    end
end

arrange()
output.connect_signal("added", arrange)
-- During "removed" the output may still be listed; look again once it is gone.
output.connect_signal("removed", function() gears.timer.delayed_call(arrange) end)
-- An output switched off and on again (wdisplays, wlr-randr) is not added anew,
-- only gets a screen again, which wlroots placed at the right end (x = 5760).
screen.connect_signal("added", function() gears.timer.delayed_call(arrange) end)
