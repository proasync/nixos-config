-- work-desktop: the shared rules (configs/default/rules.lua), plus the apps that
-- live on the right-hand monitor (HDMI): Teams on tag 2, Signal on 7, WhatsApp
-- on 8, Spotify on 9, maximized, without switching to their tag. As in the Arch config, but
-- found by output name, not screen number: Awesome and SomeWM number the
-- screens differently (HDMI is screen 3 under Awesome, 2 under SomeWM).
-- autostart.lua here starts them; Chrome goes there too, on tag 1, from the
-- autostart (a rule would catch every Chrome window).
-- Classes: X11 class or Wayland app id, both case-sensitive.

local awful = require("awful")
local screen_of = require("outputs")

dofile(os.getenv("HOME") .. "/.config/awesome/configs/default/rules.lua")

local function hdmi() return screen_of("HDMI-A-1", "HDMI-A-0") end

local function on_hdmi(classes, tag_index)
    return {
        rule_any = { class = classes },
        properties = {
            screen = function(c) return hdmi() or awful.screen.preferred(c) end,
            tag = function() local s = hdmi() return s and s.tags[tag_index] end,
            switchtotag = false,
            maximized = true,
            floating = false,
        },
    }
end

local extra = {
    on_hdmi({ "teams-for-linux" }, 2),
    on_hdmi({ "signal", "Signal" }, 7),
    on_hdmi({ "com.github.dagmoller.whatsapp-electron", "whatsapp-electron" }, 8),
    on_hdmi({ "spotify", "Spotify" }, 9),
}

-- Under X11 Spotify sets its class only after its window appears, too late for
-- the rule above: place it when the class arrives. (Under SomeWM it runs on
-- Wayland, with its app id there from the start.)
client.connect_signal("property::class", function(c)
    if c.class ~= "Spotify" then return end
    local s = hdmi()
    if s and c.first_tag ~= s.tags[9] then
        c:move_to_tag(s.tags[9])
        c.maximized = true
    end
end)

-- SomeWM's ruled.client takes new rules through append_rule; Awesome 4.3's
-- awful.rules.rules is a plain list.
local client_rules = awesome.release == "somewm" and require("ruled.client") or awful.rules
for _, r in ipairs(extra) do
    if client_rules.append_rule then client_rules.append_rule(r) else table.insert(client_rules.rules, r) end
end
