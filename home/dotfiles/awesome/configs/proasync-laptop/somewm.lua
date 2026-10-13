-- proasync-laptop output layout under SomeWM (Wayland), loaded by rc.lua only
-- there. Same as niri (hosts/proasync-laptop/niri/monitor.kdl) and the old
-- Hyprland monitors.conf when docked: the 3840x1080 desk monitor (DP-1) on
-- the left, the panel to its right at 1.67× (X11 gets the same size from
-- Xft.dpi 160).
-- Without the desk monitor the panel moves to x = 0. Some programs assume the
-- leftmost screen starts at 0: Flameshot 14 crops from 0, and with the panel
-- alone at x = 3840 its overlay showed a ~3x zoomed sliver of the screen.
-- The panel and DP-1 run their preferred modes.
--
-- Any other screen (a TV, a projector) is extended to the right of the panel
-- at 1920x1080, the refresh rate nearest 60 Hz, and scale 1. SomeWM turns a
-- new screen on at its preferred mode, which on a 4K TV is 4K@60: what went
-- black on this laptop under X11 (its HDMI tops out below 4K@60;
-- docs/external-display.md). It does so before this file hears of the
-- screen, so the switch to 1080p follows a moment later. A screen without a
-- 1080p mode keeps its own. wdisplays can change all of it live, until the
-- next plug or unplug runs arrange() again.

local gears = require("gears")

-- The screen's 1920x1080 mode nearest 60 Hz (refresh is in mHz), or nil.
local function tv_mode(o)
    local best
    for _, m in ipairs(o.modes or {}) do
        if m.width == 1920 and m.height == 1080
                and (not best or math.abs(m.refresh - 60000) < math.abs(best.refresh - 60000)) then
            best = m
        end
    end
    return best
end

-- Width in layout coordinates: its screen's, which is exact; before the
-- screen exists, what wlroots computes (mode width / scale, truncated: the
-- panel is 2880 / 1.67 = 1724). Rounding instead left a 1 px gap.
local function layout_width(o)
    if o.screen then return o.screen.geometry.width end
    local m = o.current_mode
    return m and math.floor(m.width / (o.scale or 1)) or 0
end

local function arrange()
    local docked = false
    for o in output do
        if o.name == "DP-1" and o.enabled ~= false then docked = true end
    end
    local next_x = 0   -- where the first other screen goes: right of the panel
    for o in output do
        if o.name == "eDP-1" then
            o.scale = 1.67
            o.position = { x = docked and 3840 or 0, y = 0 }
            next_x = math.max(next_x, (docked and 3840 or 0) + layout_width(o))
        elseif o.name == "DP-1" then
            o.scale = 1.0
            o.position = { x = 0, y = 0 }
            next_x = math.max(next_x, 3840)
        end
    end
    for o in output do
        if o.name ~= "eDP-1" and o.name ~= "DP-1" and o.enabled ~= false then
            local m, cur = tv_mode(o), o.current_mode
            if m and not (cur and cur.width == m.width and cur.height == m.height
                    and cur.refresh == m.refresh) then
                o.mode = { width = m.width, height = m.height, refresh = m.refresh }
            end
            o.scale = 1.0
            o.position = { x = next_x, y = 0 }
            next_x = next_x + layout_width(o)
        end
    end
end

arrange()
output.connect_signal("added", arrange)
-- During "removed" the output may still be listed; look again once it is gone.
output.connect_signal("removed", function() gears.timer.delayed_call(arrange) end)
