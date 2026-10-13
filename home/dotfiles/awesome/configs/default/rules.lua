local awful = require("awful")
local beautiful = require("beautiful")
-- SomeWM: ruled.client, Awesome's newer name (in SomeWM 1.4 awful.rules is
-- only an alias for it; 2.x removed the alias). Awesome 4.3 has only awful.rules.
local client_rules = awesome.release == "somewm" and require("ruled.client") or awful.rules
-- {{{ Rules
-- Rules to apply to new clients.
client_rules.rules = {
  -- All clients will match this rule.
  {
    rule = {},
    properties = {
      border_width = beautiful.border_width,
      border_color = beautiful.border_normal,
      focus = awful.client.focus.filter,
      raise = true,
      keys = clientkeys,
      buttons = clientbuttons,
      screen = awful.screen.preferred,
      placement = awful.placement.no_overlap + awful.placement.no_offscreen,
      size_hints_honor = false,
      maximized = false,
      maximized_horizontal = false,
      maximized_vertical = false
    }
  },

  -- Titlebars
  {
    rule_any = { type = { "dialog", "normal" } },
    properties = { titlebars_enabled = false }
  },


  -- Set applications to be maximized at startup.
  -- find class or role via xprop command

  {
    rule = { class = "Code" },
    properties = { maximized = true, floating = false }

  },
  {
    rule = { class = "Gimp*", role = "gimp-image-window" },
    properties = { maximized = true }
  },

  {
    rule = { class = "Gnome-disks" },
    properties = { maximized = true }
  },

  {
    rule = { class = "inkscape" },
    properties = { maximized = true }
  },
  {
    rule = { class = "Spotify" },
    properties = { maximized = true, floating = false }
  },
  {
    rule = { class = "Vlc" },
    properties = { maximized = true }
  },

  {
    rule = { class = "VirtualBox Manager" },
    properties = { maximized = true }
  },

  {
    rule = { class = "VirtualBox Machine" },
    properties = { maximized = true }
  },

  {
    rule = { class = "Xfce4-settings-manager" },
    properties = { floating = false }
  },
  {
    rule = { class = "libreoffice-writer" },
    properties = { floating = false, maximized = true }
  },

  -- Floating clients.
  {
    rule_any = {
      instance = {
        "DTA",   -- Firefox addon DownThemAll.
        "copyq", -- Includes session name in class.
      },
      class = {
        "Arandr",
        "wdisplays",     -- SomeWM's display settings (Wayland class, measured)
        "Arcolinux-welcome-app.py",
        "Blueberry",
        "Galculator",
        "Gnome-font-viewer",
        "Gpick",
        "Imagewriter",
        "Font-manager",
        "Kruler",
        "MessageWin", -- kalarm.
        "arcolinux-logout",
        "Peek",
        "Skype",
        "System-config-printer.py",
        "Sxiv",
        "Unetbootin.elf",
        "Wpa_gui",
        "pinentry",
        "veromix",
        "xtightvncviewer",
        "Xfce4-terminal" },

      name = {
        "Event Tester", -- xev.
      },
      role = {
        "AlarmWindow", -- Thunderbird's calendar.
        "pop-up",      -- e.g. Google Chrome's (detached) Developer Tools.
        "Preferences",
        "setup",
      }
    },
    properties = { floating = true }
  },

  -- Floating clients but centered in screen
  {
    rule_any = {
      class = {
        "Polkit-gnome-authentication-agent-1"
      },
    },
    properties = { floating = true },
    callback = function(c)
      awful.placement.centered(c, nil)
    end
  }
}

-- SomeWM (Wayland): Flameshot's capture overlay has no app_id, only the title
-- "flameshot". It asks to be fullscreen, but SomeWM put it below the bar
-- (y = bar height) with a border and not on top, which offsets the selection
-- from what you see. Pin it over the whole screen instead. Awesome on X11
-- places it right by itself.
if awesome.release == "somewm" then
  table.insert(client_rules.rules, {
    rule = { name = "flameshot" },
    properties = { floating = true, ontop = true, border_width = 0, titlebars_enabled = false },
    callback = function(c)
      c._no_border = true   -- rc.lua's "arrange" handler would reset it to 2 px
      c:geometry(c.screen.geometry)
    end,
  })

  -- SomeWM: Chrome's popups, windows a page opens (Outlook's message window,
  -- sign-in popups). On X11 Chrome marks them with the role "pop-up" (the
  -- floating rule above), but a native Wayland window has no role, and
  -- Chrome sends nothing else that sets a popup apart: same class, no
  -- parent, no size hints. What does: a page opens it on about:blank and
  -- loads into it a moment later, while a window you open yourself starts
  -- on "New Tab" or a page. Rules run when the window appears, so they see
  -- that first title. Measured on Outlook's message window 2026-10-13.
  -- A popup that a page opens straight on its URL is not caught.
  table.insert(client_rules.rules, {
    rule = { class = "google-chrome", name = "^about:blank" },
    properties = { floating = true, placement = awful.placement.centered },
  })
end
