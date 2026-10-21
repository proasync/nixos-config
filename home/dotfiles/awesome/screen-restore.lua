-- SomeWM only (rc.lua): windows go back to their monitor and tag when it returns.
--
-- On Wayland a monitor that drops its connection is removed, and SomeWM moves
-- its windows to a remaining screen. The DisplayPort and HDMI monitors here do
-- that whenever they sleep, several times a day (the log below showed it);
-- under X11 the layout stays, which is why Awesome never did this.
--
-- How: every 5 s, while every monitor is there and nothing has changed for
-- 10 s, each window's place is noted: its monitor (by output name) and tag,
-- and the tag each monitor shows. When a monitor drops out the notes stop;
-- once all are back, every window not in its noted place moves back, and
-- each monitor shows its tag again. (SomeWM 1.4 also saves a vanishing
-- screen's tags, in awful.permissions.saved_tags, but never restores them,
-- and its save sometimes held no windows: HDMI's were lost on 2026-10-20.)
--
-- Every removal and return is logged to the journal:
--   journalctl --user -t somewm-screens

local awful = require("awful")
local gears = require("gears")
local permissions = require("awful.permissions")

local function log(msg)
    awful.spawn({ "logger", "-t", "somewm-screens", msg }, false)
end

local function output_of(s)
    return s and s.valid and s.output and s.output.name or nil
end

local function screen_of(name)
    for s in screen do
        if output_of(s) == name then return s end
    end
end

local function outputs_now()
    local n = 0
    for s in screen do
        if output_of(s) then n = n + 1 end
    end
    return n
end

local most = outputs_now()                    -- most monitors seen at once
local last_change = os.time()
local homes = setmetatable({}, { __mode = "k" })  -- client -> { output, tag }
local shown = {}                              -- output -> tag name it shows

local function note()
    local n = outputs_now()
    if n > most then most = n end
    if n < most or os.time() - last_change < 10 then return end
    for _, c in ipairs(client.get()) do
        local o, t = output_of(c.screen), c.first_tag
        if o and t then homes[c] = { output = o, tag = t.name } end
    end
    for s in screen do
        local o, t = output_of(s), s.selected_tag
        if o and t then shown[o] = t.name end
    end
end

local function restore()
    if outputs_now() < most then return end   -- not all back yet
    local moved = 0
    for c, h in pairs(homes) do
        local s = c.valid and screen_of(h.output)
        local t = s and awful.tag.find_by_name(s, h.tag)
        if t and c.first_tag ~= t then
            c:move_to_tag(t)
            moved = moved + 1
        end
    end
    for o, name in pairs(shown) do
        local s = screen_of(o)
        local t = s and awful.tag.find_by_name(s, name)
        if t and not t.selected then t:view_only() end
    end
    log(("all %d monitors back; moved %d window(s) to their place"):format(most, moved))
end

gears.timer { timeout = 5, autostart = true, call_now = false, callback = note }

screen.connect_signal("removed", function(s)
    last_change = os.time()
    log(("screen for %s removed; its windows move to another screen"):format(output_of(s) or "?"))
end)

screen.connect_signal("added", function(s)
    last_change = os.time()
    -- Not used: SomeWM's own save of the vanished screen's tags would only pile up.
    permissions.saved_tags = {}
    log(("screen for %s added"):format(output_of(s) or "?"))
    -- Let the new screen get its tags (rc.lua) and a quick drop-out settle.
    gears.timer.start_new(3, function() restore() return false end)
end)
