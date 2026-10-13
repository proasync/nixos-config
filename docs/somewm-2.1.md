# SomeWM 2.1: rounded corners and the move off 1.4

**Status 2026-10-13:**
- **The shared config is migrated.** It runs unchanged on Awesome 4.3, SomeWM 1.4.6 and
  SomeWM `main` (2.1-dev, `93a22b29b`).
- **We stay on `release/1.4` (1.4.6)** until 2.1 is tagged.
- **Rounded corners still wait:** on `main` the border stays square (below).

Read this before switching the `somewm` input in `flake.nix`.

## Why we wait

In 1.4 and 2.0.x a client shape does nothing (Wayland has no shape protocol; SomeWM's
`DEVIATIONS.md`). Upstream added real rounded corners on `main` on 2026-10-12 (commit
`53ffe0c28`, a patched wlroots 0.20.2 bundled into SomeWM), due in the 2.1 tag. We built
`main` and ran it headless with our config and a real Alacritty window:

1. **The border stays square.** With `border_width` above 0 (ours is `dpi(2)`), each
   corner shows a small notch: the window inside is rounded, the border ring around it is
   not, so what is under the window shows between them. Without a border the corners are
   clean. Upstream says so in `lua/awful/client/clay.lua` (`assign_corners`: "A border
   stays square here"). Their renderer can already round a border ring (wibox borders do),
   so a later release may fix it.
2. **Our config needed a migration.** It was done on 2026-10-13; see *What the migration
   changed*.
3. **Upstream's Nix package on `main` did not build against our nixpkgs.** It needed the
   three fixes listed under step 1 of the checklist.
4. **`main` is still moving.** About 29 rewrite commits ("Render the desktop from one Clay
   tree per output", …) were pushed again on 2026-10-12, and a dozen fixes followed
   overnight, still before any tag.

## When 2.1 is tagged

1. **Build it against our nixpkgs** and see whether it builds as is:
   `nix build github:trip-zip/somewm/<tag> --override-input nixpkgs github:NixOS/nixpkgs/<rev from flake.lock>`.
   On `main` (2026-10-12 and 13) it needed:
   - removing `--wrap-mode=nodownload` from `mesonFlags`, because our meson hook already
     passes `-Dwrap_mode`;
   - `depsBuildBuild = [ pkg-config ]` plus `wayland-scanner` in `nativeBuildInputs`, for
     the bundled wlroots;
   - `NIX_CFLAGS_COMPILE = "-Wno-error=unused-result"`, for `tests/test-render.c`.

   If the tag still needs any of these, put them in an `overrideAttrs` in
   `modules/somewm.nix`.
2. **Run the tests again on the tag** (*How it was tested*): no startup errors, the same
   keys, rules and behaviour as on 1.4.6, and a bar that looks the same. Re-check the list
   under *Still different on `main`*.
3. **Look at the corners with our 2 px border.** Use `grim` against the headless socket,
   then crop and enlarge the corners.
   - If the border is rounded too, add the corners (below).
   - If it is still square, choose: no border plus corners in SomeWM only, or keep waiting.
4. **Switch the input** in `flake.nix` to `github:trip-zip/somewm/<tag>` and update the
   comment there. Also update the comment in `modules/somewm.nix` about upstream's
   `somewm-portals.conf`, which `main` no longer ships (our portal config does not use
   it). Then run `nrb` and log into SomeWM. The input does not touch Awesome; to roll
   back, revert the input or pick the previous generation.

## What the migration changed (2026-10-13)

Every change keeps Awesome 4.3 on X11 working. Where 4.3 lacks the new API, the code
chooses by `is_somewm`. Where SomeWM 1.4 and 2.x differ, it checks for the feature itself.

**Old names replaced by ones all three have:**
- `awful.util` is gone in 2.x.
  - Its functions became `gears.table`, `awful.spawn`, `awful.spawn.with_shell`,
    `gears.filesystem.get_cache_dir`, `gears.string.xml_escape`, `load` (the Lua prompt)
    and `os.getenv("SHELL")` (lain's alsa).
  - `rc.lua` used to pass the terminal, tag names and taglist/tasklist buttons to the
    theme through it. Now it passes them as `beautiful.at_screen_connect(s, screen_cfg)`,
    and the main menu is a local.
- Super+Ctrl+Return uses `awful.client.visible(screen)[1]`, which is the body of the old
  `getmaster`. Super+Shift+space sets `c.floating = not c.floating`.
- lain's `move_tag` sets `t.index` (`awful.tag.move` is gone).
- **The bar's arrows** were lain's separators, which draw themselves, and 2.x's renderer
  (Clay) drops such widgets. `theme.lua`'s `arrow_left` builds the same arrow from two
  shaped background containers. Compared with lain's, one pixel per arrow differs, by
  1/255.
- **The clock's leading space** is the `spr` widget in front of it. Clay draws a text in
  one font, that of its first character, and a space outside the markup's font span
  turned the whole clock into the textbox's default `sans 8`.

**SomeWM only (`is_somewm`), because Awesome 4.3 has only the old API:**
- **Rules** go to `ruled.client`. In 1.4, `awful.rules` was only an alias for it.
- **New-window signals:** `rc.lua` and lain's quake (Super+C) listen to
  `request::manage` and `request::unmanage`.
- **Notification popups:** `rc.lua` connects `request::display` (`naughty.layout.box`) and
  `request::display_error`. Without these, 2.x shows no notification at all. Visible
  change in SomeWM 1.4: popups now use naughty's box layout (a little more padding, title
  not bold).
- **lain's calendar, battery and network notifications** go through `helpers.notify`,
  `helpers.notify_destroy` and `helpers.notify_replace`. These use notification objects
  wherever `naughty.notification` exists, and the old calls on 4.3.

**Checked by feature:**
- **Carousel animation:** the "no layout animation in carousel" handler is installed
  only when `carousel.scroll_duration` exists (1.4). In 2.x the carousel scrolls through
  `layout_animation`.
- **`clay_renderer`** (`theme.lua`; `wibox.clay` exists only in 2.x) switches two things:
  - the calendar is not bold: a bold run made Clay draw it plain and lose today's
    highlight;
  - the layout dropdown is placed with `awful.placement.top_right`, `honor_workarea` and
    an offset. Clay sizes the popup after the frame, so the manual placement saw a width
    of 1 and put it off-screen.
- **`layout_anim.easing` is removed.** It is gone in 2.x, and 1.4's default was the same
  value.

## Still different on `main` (upstream, re-check at 2.1)

- **Notification popups come out wider than their box,** with a dark band on the right.
  This happens even without our `notification_*` theme settings.
- **Clay ignores font changes inside one text** (warning: "has more than one run and is
  drawn as one"). Colours are kept. Avoid bold or other fonts inside one textbox.
- **Hot reload (Super+Shift+R) loses which tag each window was on** (#731). Also open:
  tray duplicates after a reload (#761), a crash on reload (#736), the carousel drawing
  onto the next monitor (#825), and seams in bars at fractional scale (#826).
- **`awful.layout.layouts` set the old way** logs a warning in 1.4 and 2.x. It is
  harmless: the list is right.

## How it was tested

**Isolation from the real session:**
- Each WM ran on a scratch HOME with a copy of the repo's config, inside
  `dbus-run-session`. With a private bus, `awesome-client` and `notify-send` cannot reach
  the real session.
- Awesome 4.3 ran on `Xvfb :97`. SomeWM ran headless (`WLR_BACKENDS=headless`,
  `WLR_RENDERER=gles2`) with its own `XDG_RUNTIME_DIR`.
- Stub programs in `PATH` stood in for picom, nm-applet, flameshot, swayidle, systemctl
  and the rest.

**Driving it:**
- Keys were pressed by calling the binding: `k:emit_signal("press", c)` on 4.3 and
  `k.on_press(c)` on SomeWM.
- Captures came only from Xvfb and from `grim` on the private socket; their size was
  checked first.

**Comparing results:**
- A `date` stub printing a fixed time makes bar captures comparable pixel by pixel.
- On `main`, `awesome._clay_tree(screen[1])` dumps the layout tree with each text's font
  and box.

**Results:**
- **Awesome 4.3 and SomeWM 1.4.6:** the same 432 key bindings, rules, layouts and bar
  widgets as before. The master swap, floating toggle, workspace move, drop-down
  terminal, titlebar toggle, calendar, notifications and error popups behave the same.
  Bar captures match the old config pixel for pixel, apart from live numbers.
- **`main`:** no startup errors, with the same results. The two exceptions are the
  notification box width and the missing bold, both listed above.

## Adding the corners

Put this in the `is_somewm` part of `rc.lua` only, because Awesome on X11 would need
picom for this. A number is enough; `gears.shape.rounded_rect` with a radius works too.
Fullscreen windows stay square on their own.

```lua
client.connect_signal("request::manage", function(c) c.shape = dpi(6) end)
```
