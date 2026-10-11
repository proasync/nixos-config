-- proasync-laptop output layout under SomeWM (Wayland), loaded by rc.lua only
-- there. Same as niri (hosts/proasync-laptop/niri/monitor.kdl) and the old
-- Hyprland monitors.conf when docked: the 3840x1080 desk monitor (DP-1) on
-- the left, the panel to its right at 1.67× (X11 gets the same size from
-- Xft.dpi 160).
-- Without the desk monitor the panel moves to x = 0. Some programs assume the
-- leftmost screen starts at 0: Flameshot 14 crops from 0, and with the panel
-- alone at x = 3840 its overlay showed a ~3x zoomed sliver of the screen.
-- No modes: each output runs its preferred one. On a 4K TV that is the 4K@60
-- that froze this laptop under X11 (docs/external-display.md).

local gears = require("gears")

local function arrange()
    local docked = false
    for o in output do
        if o.name == "DP-1" and o.enabled ~= false then docked = true end
    end
    for o in output do
        if o.name == "eDP-1" then
            o.scale = 1.67
            o.position = { x = docked and 3840 or 0, y = 0 }
        elseif o.name == "DP-1" then
            o.scale = 1.0
            o.position = { x = 0, y = 0 }
        end
    end
end

arrange()
output.connect_signal("added", arrange)
-- During "removed" the output may still be listed; look again once it is gone.
output.connect_signal("removed", function() gears.timer.delayed_call(arrange) end)
