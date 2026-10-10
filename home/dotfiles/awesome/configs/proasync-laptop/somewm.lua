-- proasync-laptop output layout under SomeWM (Wayland), loaded by rc.lua only
-- there. Same as niri (hosts/proasync-laptop/niri/monitor.kdl) and the old
-- Hyprland monitors.conf: the 3840x1080 desk monitor on the left, the panel to
-- its right at 1.67× (X11 gets the same size from Xft.dpi 160).
-- No modes: each output runs its preferred one. On a 4K TV that is the 4K@60
-- that froze this laptop under X11 (docs/external-display.md).

local layout = {
    ["eDP-1"] = { scale = 1.67, position = { x = 3840, y = 0 } },
    ["DP-1"]  = { scale = 1.0,  position = { x = 0,    y = 0 } },
}

local function apply(o)
    local want = layout[o.name]
    if not want then return end
    o.scale = want.scale
    o.position = want.position
end

for o in output do apply(o) end
output.connect_signal("added", apply)
