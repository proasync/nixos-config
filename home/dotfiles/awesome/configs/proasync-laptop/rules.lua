local awful = require("awful")
local beautiful = require("beautiful")
-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
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

  -- Used as reference: Set applications to always map on the tag 5 on screen 1.
  --{ rule = { class = "Meld" },
  --properties = { screen = 1, tag = awful.util.tagnames[5] , switchtotag = true  } },


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
