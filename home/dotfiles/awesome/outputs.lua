-- require("outputs")(name, ...): the screen showing the first connected output
-- of those named, or nil. Works under Awesome (X11) and SomeWM (Wayland), which
-- name the same connector differently (HDMI-A-0 vs HDMI-A-1) and number the
-- screens differently too, so pass every name the monitor goes by.
return function(...)
    for _, name in ipairs({ ... }) do
        -- SomeWM: output objects know their screen. Awesome has no `output`.
        if output then
            for o in output do
                if o.name == name and o.screen then return o.screen end
            end
        end
        -- Awesome: s.outputs is keyed by output name (in SomeWM it is a list).
        for s in screen do
            for k, v in pairs(s.outputs or {}) do
                if k == name or (type(v) == "table" and v.name == name) then return s end
            end
        end
    end
end
