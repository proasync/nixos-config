--[[

     proasync - Awesome WM theme
     Catppuccin Mocha — matching Hyprland

--]]

local gears = require("gears")
local lain  = require("lain")
local awful = require("awful")
local wibox = require("wibox")
local dpi   = require("beautiful.xresources").apply_dpi

local os = os
local my_table = awful.util.table or gears.table -- 4.{0,1} compatibility

-- Catppuccin Mocha palette
local colors = {
    base      = "#1e1e2e",
    mantle    = "#181825",
    crust     = "#11111b",
    surface0  = "#313244",
    surface1  = "#45475a",
    surface2  = "#585b70",
    overlay0  = "#6c7086",
    overlay1  = "#7f849c",
    subtext0  = "#a6adc8",
    text      = "#cdd6f4",
    lavender  = "#b4befe",
    blue      = "#89b4fa",
    sapphire  = "#74c7ec",
    teal      = "#94e2d5",
    green     = "#a6e3a1",
    yellow    = "#f9e2af",
    peach     = "#fab387",
    red       = "#f38ba8",
    mauve     = "#cba6f7",
    pink      = "#f5c2e7",
    flamingo  = "#f2cdcd",
    rosewater = "#f5e0dc",
}

local theme                                     = {}
theme.dir                                       = os.getenv("HOME") .. "/.config/awesome/themes/proasync"
theme.font                                      = "mononoki Nerd Font 11"
theme.fg_normal                                 = colors.text
theme.fg_focus                                  = colors.mauve
theme.fg_urgent                                 = colors.red
theme.bg_normal                                 = colors.base
theme.bg_focus                                  = colors.surface0
theme.bg_urgent                                 = colors.base
theme.border_width                              = dpi(2)
theme.border_normal                             = colors.surface0
theme.border_focus                              = colors.mauve
theme.border_marked                             = colors.red
theme.tasklist_bg_focus                         = colors.base
theme.titlebar_bg_focus                         = colors.surface0
theme.titlebar_bg_normal                        = colors.base
theme.titlebar_fg_focus                         = colors.mauve
theme.menu_height                               = dpi(16)
theme.menu_width                                = dpi(140)
theme.menu_submenu_icon                         = theme.dir .. "/icons/submenu.png"
-- Drop the square indicator images; rely on bg/fg state colors instead
theme.taglist_squares_sel                       = nil
theme.taglist_squares_unsel                     = nil
theme.taglist_bg_focus                          = colors.mauve
theme.taglist_fg_focus                          = colors.base
theme.taglist_bg_occupied                       = colors.surface0
theme.taglist_fg_occupied                       = colors.lavender
theme.taglist_bg_empty                          = colors.base
theme.taglist_fg_empty                          = colors.overlay0
theme.taglist_bg_urgent                         = colors.red
theme.taglist_fg_urgent                         = colors.base
theme.taglist_spacing                           = dpi(2)

-- Notifications (naughty)
theme.notification_font         = "mononoki Nerd Font 11"
theme.notification_bg           = colors.base
theme.notification_fg           = colors.text
theme.notification_border_color = colors.mauve
theme.notification_border_width = dpi(2)
theme.notification_margin       = dpi(12)
theme.notification_shape        = function(cr, w, h)
    require("gears").shape.rounded_rect(cr, w, h, dpi(8))
end
theme.notification_max_width    = dpi(420)
theme.notification_icon_size    = dpi(48)
theme.notification_opacity      = 0.97
theme.layout_tile                               = theme.dir .. "/icons/tile.png"
theme.layout_tileleft                           = theme.dir .. "/icons/tileleft.png"
theme.layout_tilebottom                         = theme.dir .. "/icons/tilebottom.png"
theme.layout_tiletop                            = theme.dir .. "/icons/tiletop.png"
theme.layout_fairv                              = theme.dir .. "/icons/fairv.png"
theme.layout_fairh                              = theme.dir .. "/icons/fairh.png"
theme.layout_spiral                             = theme.dir .. "/icons/spiral.png"
theme.layout_dwindle                            = theme.dir .. "/icons/dwindle.png"
theme.layout_max                                = theme.dir .. "/icons/max.png"
theme.layout_fullscreen                         = theme.dir .. "/icons/fullscreen.png"
theme.layout_magnifier                          = theme.dir .. "/icons/magnifier.png"
theme.layout_floating                           = theme.dir .. "/icons/floating.png"
theme.widget_ac                                 = theme.dir .. "/icons/ac.png"
theme.widget_battery                            = theme.dir .. "/icons/battery.png"
theme.widget_battery_low                        = theme.dir .. "/icons/battery_low.png"
theme.widget_battery_empty                      = theme.dir .. "/icons/battery_empty.png"
theme.widget_mem                                = theme.dir .. "/icons/mem.png"
theme.widget_cpu                                = theme.dir .. "/icons/cpu.png"
theme.widget_temp                               = theme.dir .. "/icons/temp.png"
theme.widget_net                                = theme.dir .. "/icons/net.png"
theme.widget_hdd                                = theme.dir .. "/icons/hdd.png"
theme.widget_vol                                = theme.dir .. "/icons/vol.png"
theme.widget_vol_low                            = theme.dir .. "/icons/vol_low.png"
theme.widget_vol_no                             = theme.dir .. "/icons/vol_no.png"
theme.widget_vol_mute                           = theme.dir .. "/icons/vol_mute.png"
theme.tasklist_plain_task_name                  = true
theme.tasklist_disable_icon                     = true
theme.useless_gap                               = dpi(3)
theme.titlebar_close_button_focus               = theme.dir .. "/icons/titlebar/close_focus.png"
theme.titlebar_close_button_normal              = theme.dir .. "/icons/titlebar/close_normal.png"
theme.titlebar_ontop_button_focus_active        = theme.dir .. "/icons/titlebar/ontop_focus_active.png"
theme.titlebar_ontop_button_normal_active       = theme.dir .. "/icons/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_inactive      = theme.dir .. "/icons/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_inactive     = theme.dir .. "/icons/titlebar/ontop_normal_inactive.png"
theme.titlebar_sticky_button_focus_active       = theme.dir .. "/icons/titlebar/sticky_focus_active.png"
theme.titlebar_sticky_button_normal_active      = theme.dir .. "/icons/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_inactive     = theme.dir .. "/icons/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_inactive    = theme.dir .. "/icons/titlebar/sticky_normal_inactive.png"
theme.titlebar_floating_button_focus_active     = theme.dir .. "/icons/titlebar/floating_focus_active.png"
theme.titlebar_floating_button_normal_active    = theme.dir .. "/icons/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_inactive   = theme.dir .. "/icons/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_inactive  = theme.dir .. "/icons/titlebar/floating_normal_inactive.png"
theme.titlebar_maximized_button_focus_active    = theme.dir .. "/icons/titlebar/maximized_focus_active.png"
theme.titlebar_maximized_button_normal_active   = theme.dir .. "/icons/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_inactive  = theme.dir .. "/icons/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_inactive = theme.dir .. "/icons/titlebar/maximized_normal_inactive.png"

local markup = lain.util.markup
local separators = lain.util.separators

-- Big keyboard layout badge (driven by rc.lua kbdcfg)
local kbd_textbox = wibox.widget.textbox()
local function render_kbd(name)
    local label = string.upper(name or "US")
    local color = (label == "SE") and colors.yellow or colors.sapphire
    kbd_textbox:set_markup(markup.font("mononoki Nerd Font Bold 12",
        markup(colors.base, markup.bg(color, " " .. label .. " "))))
end
render_kbd("US")
function theme.set_keyboard_layout(name) render_kbd(name) end
local keyboardlayout = kbd_textbox

-- Textclock
local clockicon = wibox.widget.imagebox(theme.widget_clock)
local clock = awful.widget.watch(
    "date +'%a %d %b %R'", 60,
    function(widget, stdout)
        widget:set_markup(" " .. markup.font(theme.font, markup(colors.yellow, stdout)))
    end
)

-- Calendar
theme.cal = lain.widget.cal({
    week_start = 2,
    attach_to = { clock },
    followtag = true,
    notification_preset = {
        font = "mononoki Nerd Font 10",
        fg   = colors.sapphire,
        bg   = colors.base
    }
})

-- Nerd Font icon helper
local icon_font = "mononoki Nerd Font 12"
local function nf_icon(glyph, color)
    local w = wibox.widget.textbox()
    w:set_markup(markup.font(icon_font, markup(color, " " .. glyph .. " ")))
    return w
end

-- Nerd Font glyphs as literal UTF-8 (Lua 5.2 has no \u{} escapes)
local glyph_mem      = "󰍛"
local glyph_cpu      = "󰻠"
local glyph_temp     = "󰔏"
local glyph_bat_full = "󰁹"
local glyph_bat_low  = "󰁺"
local glyph_bat_emp  = "󰂎"
local glyph_bat_chg  = "󰂄"
local glyph_vol_hi   = "󰕾"
local glyph_vol_lo   = "󰕿"
local glyph_vol_mut  = "󰝟"
local glyph_net      = "󰈀"

-- MEM
local memicon = nf_icon(glyph_mem, colors.green)
local mem = lain.widget.mem({
    settings = function()
        widget:set_markup(markup.font(theme.font, markup(colors.green, " " .. mem_now.used .. "MB ")))
    end
})

-- CPU
local cpuicon = nf_icon(glyph_cpu, colors.blue)
local cpu = lain.widget.cpu({
    settings = function()
        widget:set_markup(markup.font(theme.font, markup(colors.blue, " " .. cpu_now.usage .. "% ")))
    end
})

-- Coretemp
-- Zone numbers vary per machine (and can change on kernel updates), so find
-- the CPU package sensor by type instead of hardcoding a zone. On the laptop
-- this resolves to thermal_zone9 (x86_pkg_temp); if no match, lain falls back
-- to its default (thermal_zone0).
-- NOTE: must return the /sys/devices/... form — lain matches tempfile
-- against `find /sys/devices` output, so the /sys/class/... alias won't match.
local function cpu_temp_file()
    for i = 0, 20 do
        local zone = "/sys/devices/virtual/thermal/thermal_zone" .. i
        local f = io.open(zone .. "/type")
        if f then
            local t = f:read("*l")
            f:close()
            if t == "x86_pkg_temp" then
                return zone .. "/temp"
            end
        end
    end
    return nil
end
local tempicon = nf_icon(glyph_temp, colors.peach)
local temp = lain.widget.temp({
    tempfile = cpu_temp_file(),
    settings = function()
        widget:set_markup(markup.font(theme.font, markup(colors.peach, " " .. coretemp_now .. "°C ")))
    end
})

-- Battery (icon glyph chosen by state inside settings)
local baticon = wibox.widget.textbox()
baticon:set_markup(markup.font(icon_font, markup(colors.lavender, " " .. glyph_bat_full .. " ")))
local bat = lain.widget.bat({
    settings = function()
        local glyph = glyph_bat_full
        if bat_now.status and bat_now.status ~= "N/A" then
            if bat_now.ac_status == 1 then
                glyph = glyph_bat_chg
            elseif bat_now.perc and tonumber(bat_now.perc) <= 5 then
                glyph = glyph_bat_emp
            elseif bat_now.perc and tonumber(bat_now.perc) <= 15 then
                glyph = glyph_bat_low
            end
            widget:set_markup(markup.font(theme.font, markup(colors.lavender, " " .. bat_now.perc .. "% ")))
        else
            glyph = glyph_bat_chg
            widget:set_markup(markup.font(theme.font, markup(colors.lavender, " AC ")))
        end
        baticon:set_markup(markup.font(icon_font, markup(colors.lavender, " " .. glyph .. " ")))
    end
})

-- ALSA volume
local volicon = wibox.widget.textbox()
volicon:set_markup(markup.font(icon_font, markup(colors.teal, " " .. glyph_vol_hi .. " ")))
theme.volume = lain.widget.alsa({
    settings = function()
        local glyph = glyph_vol_hi
        if volume_now.status == "off" then
            glyph = glyph_vol_mut
        elseif tonumber(volume_now.level) == 0 then
            glyph = glyph_vol_mut
        elseif tonumber(volume_now.level) <= 50 then
            glyph = glyph_vol_lo
        end
        volicon:set_markup(markup.font(icon_font, markup(colors.teal, " " .. glyph .. " ")))
        widget:set_markup(markup.font(theme.font, markup(colors.teal, " " .. volume_now.level .. "% ")))
    end
})
theme.volume.widget:buttons(awful.util.table.join(
                               awful.button({}, 4, function ()
                                     awful.util.spawn("amixer set Master 1%+")
                                     theme.volume.update()
                               end),
                               awful.button({}, 5, function ()
                                     awful.util.spawn("amixer set Master 1%-")
                                     theme.volume.update()
                               end)
))

-- Net
local neticon = nf_icon(glyph_net, colors.pink)
local net = lain.widget.net({
    settings = function()
        widget:set_markup(markup.font(theme.font,
                          markup(colors.pink, " " .. string.format("%06.1f", net_now.received))
                          .. " " ..
                          markup(colors.mauve, " " .. string.format("%06.1f", net_now.sent) .. " ")))
    end
})

-- Separators
local spr     = wibox.widget.textbox(' ')
local arrl_dl = separators.arrow_left(colors.surface0, "alpha")
local arrl_ld = separators.arrow_left("alpha", colors.surface0)

function theme.at_screen_connect(s)
    -- Quake application
    s.quake = lain.util.quake({ app = awful.util.terminal })

    -- Tags
    awful.tag(awful.util.tagnames, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(my_table.join(
                           awful.button({}, 1, function () awful.layout.inc( 1) end),
                           awful.button({}, 2, function () awful.layout.set( awful.layout.layouts[1] ) end),
                           awful.button({}, 3, function () awful.layout.inc(-1) end),
                           awful.button({}, 4, function () awful.layout.inc( 1) end),
                           awful.button({}, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, awful.util.taglist_buttons)

    -- Create a tasklist widget (compact: icon + truncated title, fixed-width per entry)
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = awful.util.tasklist_buttons,
        style   = {
            shape_border_width = 0,
            shape  = gears.shape.rectangle,
        },
        layout  = {
            spacing = dpi(2),
            layout  = wibox.layout.fixed.horizontal,
        },
        widget_template = {
            {
                {
                    {
                        {
                            id     = "icon_role",
                            widget = wibox.widget.imagebox,
                        },
                        margins = dpi(2),
                        widget  = wibox.container.margin,
                    },
                    {
                        {
                            id     = "text_role",
                            widget = wibox.widget.textbox,
                        },
                        width  = dpi(140),
                        strategy = "max",
                        widget = wibox.container.constraint,
                    },
                    layout = wibox.layout.fixed.horizontal,
                },
                left  = dpi(4),
                right = dpi(4),
                widget = wibox.container.margin,
            },
            id     = "background_role",
            widget = wibox.container.background,
        },
    }

    -- Spotify / MPRIS now-playing widget (playerctl)
    s.nowplaying = awful.widget.watch(
        { "sh", "-c", "playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null | head -c 60" },
        2,
        function(widget, stdout)
            local text = stdout:gsub("\n", "")
            if text == "" then
                widget:set_markup("")
            else
                widget:set_markup(markup.font(theme.font, markup(colors.mauve, " 󰎈 " .. text .. " ")))
            end
        end
    )
    s.nowplaying:buttons(my_table.join(
        awful.button({}, 1, function() awful.spawn("playerctl play-pause") end),
        awful.button({}, 4, function() awful.spawn("playerctl next") end),
        awful.button({}, 5, function() awful.spawn("playerctl previous") end)
    ))

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s, height = dpi(20), bg = colors.base, fg = colors.text })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            s.mytaglist,
            s.mypromptbox,
            spr,
            s.mytasklist,
        },
        { -- Middle widget: now-playing, forced centered
            s.nowplaying,
            halign = "center",
            valign = "center",
            widget = wibox.container.place,
        },
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            wibox.widget.systray(),
            keyboardlayout,
            spr,
            arrl_ld,
            volicon,
            theme.volume.widget,
            arrl_dl,
            memicon,
            mem.widget,
            arrl_ld,
            wibox.container.background(cpuicon, colors.surface0),
            wibox.container.background(cpu.widget, colors.surface0),
            arrl_dl,
            tempicon,
            temp.widget,
            arrl_ld,
            wibox.container.background(baticon, colors.surface0),
            wibox.container.background(bat.widget, colors.surface0),
            arrl_dl,
            wibox.container.background(neticon, colors.surface0),
            wibox.container.background(net.widget, colors.surface0),
            arrl_dl,
            clock,
            spr,
            arrl_ld,
            wibox.container.background(s.mylayoutbox, colors.surface0),
        },
    }
end

return theme
