# SomeWM 2.1: rounded corners and the move off 1.4

**Status 2026-10-12: waiting.** We stay on `release/1.4` (1.4.6). Rounded window corners
are the reason to move; they are not usable for us yet. Read this before switching the
`somewm` input in `flake.nix`.

## Why we wait

In 1.4 and 2.0.x a client shape does nothing (Wayland has no shape protocol; SomeWM's
`DEVIATIONS.md`). Upstream added real rounded corners on `main` on 2026-10-12 (commit
`53ffe0c28`, a patched wlroots 0.20.2 bundled into SomeWM), due in the 2.1 tag. We built
`main` at `7b3ae1c0e` and ran it headless with our config and a real Alacritty window:

1. **The border stays square.** With `border_width` above 0 (ours is `dpi(2)`), each
   corner shows a small notch: the window inside is rounded, the border ring around it is
   not, so what is under the window shows between them. Without a border the corners are
   clean. Upstream says so in `lua/awful/client/clay.lua` (`assign_corners`: "A border
   stays square here"). Their renderer can already round a border ring (wibox borders do),
   so a later release may fix it.
2. **Our config does not load on `main`.** `awful.util` is gone, so `rc.lua:37` fails and
   SomeWM falls back to its built-in default config. The rest of the list under
   *Config migration* would break next.
3. **Upstream's Nix package on `main` did not build against our nixpkgs.** It needed the
   three fixes listed under step 1 of the checklist.
4. **`main` was moving.** About 29 rewrite commits ("Render the desktop from one Clay
   tree per output", "Remove wibox.container.border and 21 widget properties…") were
   pushed again the same day, before any tag.

## When 2.1 is tagged

1. **Build it against our nixpkgs** and see whether it builds as is:
   `nix build github:trip-zip/somewm/<tag> --override-input nixpkgs github:NixOS/nixpkgs/<rev from flake.lock>`.
   On `main` (2026-10-12) it needed:
   - removing `--wrap-mode=nodownload` from `mesonFlags`, because our meson hook already
     passes `-Dwrap_mode`;
   - `depsBuildBuild = [ pkg-config ]` plus `wayland-scanner` in `nativeBuildInputs`, for
     the bundled wlroots;
   - `NIX_CFLAGS_COMPILE = "-Wno-error=unused-result"`, for `tests/test-render.c`.

   If the tag still needs any of these, put them in an `overrideAttrs` in
   `modules/somewm.nix`.
2. **Do the config migration below**, then check Awesome on Xvfb as well as SomeWM.
3. **Run it headless** with stubs in `PATH` and a private `XDG_RUNTIME_DIR`
   (`WLR_BACKENDS=headless`). `awesome.startup_errors` must be nil. Then check keys,
   carousel, the layout dropdown, the Flameshot rule and the window animation.
4. **Look at the corners with our 2 px border.** Use `grim` against the headless socket,
   then crop and enlarge the corners.
   - If the border is rounded too, add the corners (below).
   - If it is still square, choose: no border plus corners in SomeWM only, or keep waiting.
5. **Switch the input** in `flake.nix` to `github:trip-zip/somewm/<tag>`, update the
   comment there, run `nrb`, and log into SomeWM. Awesome is untouched by the input;
   rolling back means reverting the input or picking the previous generation.

## Config migration

This list was found on `main` at `7b3ae1c0e` (2026-10-12). Re-check it against the tag.
The `awful.util` failure was seen in a run; the rest was read from upstream's source.
Line numbers are from that date.

Each fix must keep Awesome 4.3 on X11 working. Where 4.3 lacks the new API, choose by
`is_somewm`.

**Removed APIs:**
- **`awful.util` is gone.** `awful.util` is nil and `require("awful.util")` errors. It is
  used about 50 times in `rc.lua`, `themes/proasync/theme.lua` and the bundled lain
  (`widget/alsa.lua:10` and `widget/cal.lua:178` break `beautiful.init`).
  - Replace the functions with `gears.table`, `awful.spawn`, `awful.spawn.with_shell`,
    `gears.string.xml_escape` and `gears.filesystem.get_cache_dir`.
  - The values `rc.lua` keeps in `awful.util` (`terminal`, `tagnames`, `taglist_buttons`,
    `tasklist_buttons`, `mymainmenu`) go into a table of our own.
- **`awful.rules` is gone** (`configs/*/rules.lua`). Use
  `awful.rules or require("ruled.client")`; `.rules = {…}` and `table.insert` still work.
- **`naughty.notify` and the built-in popup are gone.** Without a
  `request::display` handler, no notification shows at all: not apps', and not error
  popups.
  - Under `is_somewm`, add handlers for `request::display` (with `naughty.layout.box`) and
    `request::display_error`. Keep the old code for 4.3.
  - lain's `cal`, `bat` and `net` call `naughty.notify`. Shim it, or use
    `awful.widget.calendar_popup`.
- **`client` `manage`/`unmanage` never fire**; there is only a warning in the log. This
  breaks `rc.lua:721` and `lain/util/quake.lua` (Super+C is not placed, and its
  shown/hidden flag goes stale). Use `is_somewm and "request::manage" or "manage"`.
- **`awful.client.getmaster` is gone** (`rc.lua:633`). Use
  `awful.client.visible(c.screen)[1]`.
- **`awful.client.floating.toggle` does nothing** (`rc.lua:631`). Use
  `c.floating = not c.floating`.
- **`awful.tag.move` is gone** (`lain/util/init.lua:166`, Super+Shift+Left/Right). Use
  `t.index = t.index ± 1`.

**Behaviour changes:**
- **Widgets that draw themselves are dropped** by the new renderer. That removes lain's
  arrow separators (`theme.lua:313`); use powerline glyphs in textboxes.
- **`layout_anim.easing` is gone** (`rc.lua:70`, warns only).
- **Carousel now scrolls through `somewm.layout_animation`.** Our handler that turns the
  animation off in carousel (`rc.lua:59`) would make it snap: delete it.
- **`carousel.push_window(dir)` now consumes or expels by itself.** Our
  `carousel_consume_or_expel` can become that one call.
- **Hot reload (Super+Shift+R) loses which tag each window was on** (upstream #731).

**Stale in our repo:** `modules/somewm.nix` mentions upstream's `somewm-portals.conf`,
which `main` no longer ships. Our portal config does not depend on it.

**Unchanged** (no work needed): `awesome.release`, `#N` key bindings, output objects and
their signals, the carousel functions, `awful.input`, `set_dpi`, `mousegrabber`,
titlebars, `awful.popup`, `layoutlist`, and `somewm-client eval`. Startup warnings go to
stderr, not popups.

**Check once it runs:**
- whether windows grow out of an empty box after a tag switch;
- whether the layout dropdown still lands under its icon;
- the open upstream issues that touch us: #825 (carousel draws onto the next monitor),
  #826 (seams in bars at fractional scale), #761 and #736 (hot-reload tray duplicates and
  a crash).

## Adding the corners

Put this in the `is_somewm` part of `rc.lua` only, because Awesome on X11 would need
picom for this. A number is enough; `gears.shape.rounded_rect` with a radius works too.
Fullscreen windows stay square on their own.

```lua
client.connect_signal("request::manage", function(c) c.shape = dpi(6) end)
```
