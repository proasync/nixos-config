# nixos-config

Flake-based NixOS + Home Manager configuration for three machines:

| | `home-desktop` | `proasync-laptop` | `work-desktop` |
| --- | --- | --- | --- |
| Hardware | i5-12400F + RX 7600 | ASUS Zenbook S 13 UX5304MA (Core Ultra 7 155U) | HP, Ryzen 5 5600G + RX 460/560D, 32 GB |
| GPU | AMD (`amdgpu`) | Intel Arc iGPU (`modesetting` + iHD VA-API) | AMD (`amdgpu`) |
| Display | standard DPI | 2880x1800 HiDPI (SDDM 2×, Xft.dpi 160, niri 1.67×) | 3 × 1920x1080, standard DPI |
| Host-only quirks | — | USB-root autosuspend guard, Intel ISH blacklist, i915 in initrd + `xe` blacklisted, iwlwifi force-load, thermald, power-profiles-daemon, lid handling, Bluetooth | Bluetooth; Windows on its own NVMe (boot via F9); the office Brother printer as a permanent CUPS queue (its PPD in `hosts/work-desktop/`); monitor ports forced connected (`video=…:e`), so sleeping monitors don't disconnect |
| Remote access (Tailscale + tailnet-only SSH) | — | yes | yes |
| Phone dev ports on LAN (8081, 4300) | yes | yes | — (phone uses Tailscale) |
| SDDM theme | catppuccin-sddm-corners (Mononoki, larger text), penguin avatar | same + nixos-lightdark2 wallpaper, greeter at 2× on the panel | same + skull-hacking-time wallpaper |
| Dev services | MariaDB, Apache+PHP, PostgreSQL | same | same |
| Status | | | **not installed yet**: hardware config is a placeholder until `scripts/install.sh` runs ([docs/install.md](docs/install.md)) |

- **WMs (all hosts):** Awesome (Xorg, the daily driver) and niri (Wayland, scrolling columns),
  plus SomeWM on trial (Wayland, runs Awesome's own config: see *SomeWM (trial)* below).
  Hyprland is retired but its config is kept: see *Hyprland (retired)* below.
- **Theme:** Catppuccin Mocha Mauve — SDDM, Awesome, niri, Waybar, Rofi, Alacritty, Mako, GTK, and the lock
  screens (swaylock on Wayland, i3lock-color on X11). Dark everywhere: `gtk.colorScheme` also sets
  the desktop-wide color-scheme, which Wayland apps (Signal, WhatsApp) get through the portal
- **Wallpaper:** picked in `waypaper`, per monitor or for all of them. Its wrapper
  (`home/packages/waypaper.nix`) sets it with xwallpaper on X11 and through the `awww` daemon
  on Wayland; at login `awesome/scripts/wallpaper-restore.sh` (X11) and
  `wm-scripts/wallpaper-restore.sh` (Wayland) re-apply it. The sessions share one waypaper
  config: an "All" pick shows in all of them, a per-monitor pick only in the session it was
  made in (X11 and Wayland name the monitors differently: `DisplayPort-0` vs `DP-1`), and a
  new "All" pick replaces the per-monitor ones

## Repo structure

```
nixos-config/
├── flake.nix                  # Entry point — host list; mkHost <name> wires hosts/<name>/
├── assets/                    # Build-time static assets
├── docs/
│   ├── install.md             # install-day runbook: USB stick, scripts/install.sh, after the first boot
│   ├── desktop-freeze.md      # laptop freezes/slowness: escape hatches, live checks, past incidents
│   ├── updating.md            # how to update safely + post-update checklist
│   ├── dev-environments.md    # pagoda/proasync monorepo dev setup on NixOS
│   ├── external-display.md    # laptop → TV/projector runbook, Awesome and SomeWM (read before touching xrandr)
│   ├── agent-tooling.md       # multi-agent coding setup (claude-squad, Codex) and the shared agent instructions
│   └── somewm-2.1.md          # SomeWM 2.x: config migration, rounded corners, upgrade checklist
├── hosts/                     # one folder per host, named exactly like the hostname
│   ├── home-desktop/          # AMD GPU
│   ├── proasync-laptop/       # Intel GPU/VA-API, HiDPI, power, hardware quirks
│   │   └── home.nix           # per-host Home Manager overrides (Xft.dpi)
│   └── work-desktop/          # AMD GPU, remote access (hardware config = placeholder)
│       (each has configuration.nix, hardware-configuration.nix, niri/monitor.kdl and
│        hypr/monitors.conf; home.nix, niri/hostextras.kdl and hypr/hostextras.conf are optional)
├── modules/
│   ├── common.nix             # Everything shared: boot, locale, user, WMs, SDDM, audio,
│   │                          #   fonts, keyd, nix-ld (Electron libs), docker, printing, gc,
│   │                          #   zram swap + earlyoom
│   ├── sddm-theme.nix         # SDDM theme package; `proasync.sddmBackground` per host
│   ├── dev-services.nix       # MariaDB + Apache/PHP (WordPress) + PostgreSQL — imported per host
│   ├── hyprland.nix           # Hyprland (retired) — imported by no host; see *Hyprland (retired)*
│   ├── somewm.nix             # SomeWM session (trial), from the `somewm` flake input
│   ├── remote-access.nix      # Tailscale + tailnet-only SSH — imported per host
│   └── lan-dev-ports.nix      # firewall ports for phone dev (Expo/Metro, training API) — per host
├── home/
│   ├── home.nix               # Home Manager: packages, bash, git, GTK, dotfile symlinks
│   ├── hyprland.nix           # Hyprland's links + packages, active only with modules/hyprland.nix
│   ├── scripts/               # User scripts installed to ~/.local/bin
│   ├── applications/          # Custom .desktop entries
│   └── dotfiles/              # Live-symlinked into ~/.config/ (edit → takes effect, no rebuild)
│       ├── awesome/  niri/  hypr/   # window managers (hypr = retired Hyprland)
│       ├── wm-scripts/              # power menu, lock, Chrome, touchpad, TV mirror: shared by niri, SomeWM + Hyprland
│       ├── swaylock/                # lock screen theme (niri)
│       ├── waybar/  rofi/  mako/    # bar (waybar/ = Hyprland's; niri's is niri/waybar/), launcher, notifications
│       ├── alacritty/  btop/  cava/ # terminal & TUI rice
│       ├── fastfetch/               # banner every new shell prints; logo NixOS2, 32 cols so lines don't wrap
│       ├── claude/                  # Claude Code settings; CLAUDE.md = global agent instructions
│       │                            #   (~/.claude/CLAUDE.md and ~/.codex/AGENTS.md link to it), /onboard + /audit
│       └── wallpapers/              # browsable by waypaper; stored via Git LFS (see below)
└── scripts/
    ├── install.sh             # Install from the NixOS live USB: disk, nixos-install, passwords
    └── setup-wordpress.sh     # One-time WordPress/WooCommerce dev setup
```

**Per-host settings:** one name drives everything — the flake attribute, `networking.hostName`
(set by `mkHost`) and the `hosts/<name>/` folder — so `nrs` (`#$(hostname)`) always finds the
right host. Shared config lives in `modules/` and `home/`; anything host-specific lives in
`hosts/<name>/`:

- `configuration.nix` — system settings, plus which optional modules the host imports.
- `home.nix` *(optional)* — Home Manager overrides, merged on top of `home/home.nix`.
  Never add hostname checks to `home/home.nix`.
- `niri/monitor.kdl` — **required** for every host (an assertion fails the build without it;
  niri itself rejects a config whose `include` is missing). nwg-displays (Super+D in niri)
  writes through the `~/.config/niri/monitor.kdl` link, so this must never be a file that
  hosts share. Commit what it writes.
- `niri/hostextras.kdl` *(optional)* — included last by `niri/config.kdl`; falls back to the
  no-op `home/dotfiles/niri/hostextras.kdl`, which must stay a **regular file**. The laptop's
  disables direct scanout (i915 freezes), like its `hypr/hostextras.conf`.
- `hypr/monitors.conf` — **required** on every host that runs Hyprland (an assertion fails
  the build without it). nwg-displays (Super+D) writes through the `~/.config/hypr` symlink,
  so this must never be a file that hosts share. Keep the existing ones: they are what a
  Hyprland comeback starts from.
- `hypr/hostextras.conf` *(optional)* — falls back to the no-op `home/dotfiles/hypr/hostextras.conf`,
  which must stay a **regular file** (it was once accidentally committed as a symlink into
  `/nix/store`).
- Awesome does the same at runtime: `home/dotfiles/awesome/configs/<hostname>/`, falling back
  to `configs/default/`. Under SomeWM it also loads `somewm.lua` from there (Wayland output
  scale and position; the laptop's mirrors its niri `monitor.kdl`). Don't copy the `proasync-laptop` folder to a desktop; it runs the
  laptop's xrandr/DPI setup. The fallback is per file: a host's `autostart.lua` or `rules.lua`
  can load the default one and add to it, as work-desktop's do (Chrome, Teams, Signal,
  WhatsApp and Spotify on the HDMI monitor, tags 1, 2, 7, 8, 9). To place things on a monitor, find it by
  output name with `require("outputs")`: Awesome and SomeWM number the screens differently,
  and name the outputs differently too (`HDMI-A-0` under X11, `HDMI-A-1` under Wayland).

## Day-to-day

| Command | Action |
| --- | --- |
| `nrs` | rebuild + switch (`sudo nixos-rebuild switch --flake ~/nixos-config#$(hostname)`) |
| `nrt` / `nrd` | rebuild test / dry-build |
| `nrb` | rebuild for next boot, then reboot — when `nrs` refuses to switch live |
| `niri validate` | check niri's config after editing it (niri reloads it on save; a broken file keeps the old one) |
| `waypaper` | pick the wallpaper, per monitor (dropdown at the bottom) or for all; every login re-applies it |
| `Super + W` | popup listing the keybindings (niri's sheet in niri; Hyprland's in Hyprland) |
| `Super + X`, then `k` | lock the screen: i3lock-color on X11 (via xss-lock), swaylock on Wayland. Never automatic in Awesome or SomeWM; screens just turn off after 10 min idle |
| `Super + Shift + T` | show/hide the focused window's titlebar (Awesome, SomeWM; off by default) |
| `Super + C` | drop-down terminal from the top of the screen; same key hides it, and it keeps running (Awesome, SomeWM) |
| click the layout icon (top right) | dropdown of all layouts, current one highlighted; scroll on the icon cycles (Awesome, SomeWM) |
| `Super + Shift + H / L` | swap the window with its left/right neighbour (carousel: move the column) |
| `Super + R` / `Super + X` | rofi launcher / power menu; the same key again closes it. Under SomeWM rofi is an overlay that once stayed open with Escape going to the window behind it, so this is the sure way out; a click on any window also closes it (Awesome, SomeWM) |
| `Super + , / .` | focus the screen to the left/right, by position, wrapping around (Awesome, SomeWM; not by screen number, which changes when a monitor drops out and returns) |
| `Super + Shift + , / .` | move the window to the screen to the left/right; focus and pointer follow it, so the same key moves it on |
| `wdisplays` | arrange monitors on Wayland (SomeWM, niri): arandr's equivalent. Applies live and saves nothing; the WM's own file wins again on hot-plug, so copy a layout you keep into `configs/<host>/somewm.lua` (SomeWM) or let nwg-displays write `monitor.kdl` (niri) |
| `tv-mirror.sh on` / `off` | laptop → TV mirror on X11/Awesome — see [docs/external-display.md](docs/external-display.md) first |
| `~/.config/wm-scripts/mirror.sh on` / `off` | laptop → TV mirror on Wayland (SomeWM): `wl-mirror` shows the panel fullscreen on the TV. Under SomeWM a TV is otherwise its own screen at 1080p, right of the panel. See [docs/external-display.md](docs/external-display.md) |
| `Mod+Shift+P` (Awesome) | restart picom (logs to `~/.cache/picom/`) — screen frozen? see [docs/desktop-freeze.md](docs/desktop-freeze.md) |
| USB stick | auto-mounts to `/run/media/proasync/<label>` in every session (udiskie user service); eject: `udiskie-umount -a` or Thunar |

Frequently used niri binds: `Super+Return` terminal · `Super+R` launcher · `Super+Q` close ·
`Super+P` screenshot · `Super+X` powermenu (`k` locks) · `Super+HJKL` focus ·
`Super+1-9` workspaces · `Super+Tab` next workspace · `Super+O` overview ·
`Super+F1-F6` app launchers. The full list is the `binds` block in
[niri/config.kdl](home/dotfiles/niri/config.kdl); the `Super+W` sheet
(`niri/scripts/keybinds-help.sh`) is written by hand, so update it with the binds.

CapsLock is a nav layer via keyd (`modules/common.nix`): `CapsLock+HJKL` → arrows,
`CapsLock+1-9` → F1-F9. Works system-wide at the kernel level on every host.

### Hyprland (retired)

Retired 2026-10-10 because updates kept breaking it. Nothing was deleted:
`home/dotfiles/hypr/`, `hosts/<host>/hypr/` and `home/dotfiles/waybar/` (its bar) are all kept.
To bring it back on a host:

1. Add `../../modules/hyprland.nix` to `imports` in `hosts/<host>/configuration.nix`.
2. `nrs`. `home/hyprland.nix` sees `programs.hyprland.enable` and restores the
   `~/.config/hypr` and `~/.config/waybar` links, hyprlock and hypridle. Hyprland then
   appears in SDDM's session list.

Its power menu, Chrome launcher and touchpad toggle live in `home/dotfiles/wm-scripts/`
(shared with niri). Under Hyprland the power menu locks with hyprlock; elsewhere with swaylock.

### SomeWM (trial)

[SomeWM](https://github.com/trip-zip/somewm) is AwesomeWM's Lua API on Wayland, added
2026-10-10 as a possible way off X11 that keeps Awesome's per-screen tags. It is a third
SDDM session ("somewm"), built from the `release/1.4` branch (the `somewm` input in
`flake.nix`; module `modules/somewm.nix`).

- **One config for both.** SomeWM reads `~/.config/awesome/rc.lua`, so it runs the same
  files as Awesome. `rc.lua` sets `is_somewm = awesome.release == "somewm"`; anything
  X11-only (picom, xrandr, xrdb, flameshot, setxkbmap, xkill, numlockx, unclutter) must sit
  behind it, with the Wayland replacement next to it. Under SomeWM: layouts via
  `awful.input`, screenshots with Flameshot through the Screenshot portal (xdg-desktop-portal-wlr runs grim; a rule in
  `configs/default/rules.lua` pins its overlay over the whole screen), wallpaper and idle lock through the
  niri scripts in `wm-scripts/` (but no idle lock), tray icons via `nm-applet --indicator`.
- **DPI.** SomeWM also reads `~/.Xresources`, so `rc.lua` pins its Lua-side DPI to 96 there.
  The laptop's 1.67× comes from the output scale in `configs/proasync-laptop/somewm.lua`.
- **Monitor layout.** `configs/<host>/somewm.lua` is the saved layout: it runs at startup and
  on every output added/removed (the laptop's handles docked/undocked; work-desktop's keeps
  its three monitors in the same order as under X11). The Lua `output`
  object takes `enabled`, `position`, `scale`, `transform`, `mode` and `adaptive_sync`. To
  find a layout, use `wdisplays` (or `wlr-randr`): SomeWM implements wlr-output-management,
  so they apply live, but save nothing. nwg-displays does not run here (it wants a niri,
  sway or Hyprland socket). The default `somewm.lua` does nothing, so on a desktop without
  its own file SomeWM places the outputs itself at every login.
- **A monitor that drops out** (DisplayPort/HDMI monitors disconnect in deep standby, e.g.
  over a weekend) is removed on Wayland, and SomeWM moves its windows to another screen;
  X11 keeps the layout, so Awesome never did this. Here they drop out whenever they sleep,
  several times a day. `screen-restore.lua` notes every window's monitor and tag while all
  monitors are there, and moves them back once all have returned (SomeWM's own save of a
  vanishing screen's tags is never restored in 1.4, and sometimes held no windows). Each
  removal and return is logged: `journalctl --user -t somewm-screens`. On 2026-10-23 a
  drop-out crashed SomeWM itself (wlroots assertion while removing the monitor) and the
  session with every window was gone, so work-desktop forces its ports connected
  (`boot.kernelParams` in its `configuration.nix`): its monitors no longer drop out at all. Per-screen widget
  timers must stop with their screen (theme.lua's now-playing does): one that kept running
  piled up to ~66 over a few days of sleeps and made everything slow (2026-10-21).
- **Reload without losing windows:** `somewm-client reload` rebuilds SomeWM's Lua side from
  `rc.lua` (validated first) and keeps every window on its tag; the autostart skips Chrome
  when a Chrome window is open. (`somewm-client restart` would end the session.)
- **Check a change** with `somewm --check ~/.config/awesome/rc.lua` and `awesome -k`.
  Electron apps started from a VS Code terminal inherit `ELECTRON_RUN_AS_NODE=1` and fail
  with "Cannot find module 'electron'"; unset it when testing from there.
  SomeWM's check flags X11 tools by pattern, even inside the guarded X11 branch.
- **Session script:** SDDM runs a small wrapper (`modules/somewm.nix`) that sets
  `NIXOS_OZONE_WL=1`. At startup `rc.lua` exports the session's variables to the systemd
  user manager and starts `nixos-fake-graphical-session.target` (xdg-desktop-portal refuses
  to run without `graphical-session.target`; NixOS's X11 login starts the same target).
  When SomeWM exits, the wrapper removes the variables and stops the portals and the target.
- **Screen sharing** goes through xdg-desktop-portal-wlr: whole monitors only (SomeWM 1.4
  has no per-window capture), so pick "entire screen" in Teams/Chrome; with two monitors,
  click the one to share. It cannot stall Awesome logins: see the comment in
  `modules/somewm.nix` and the portal check in `docs/updating.md`.
- **Sharpness on the laptop's 1.67× panel:** Chrome, VS Code, Teams, Obsidian and Signal run
  as native Wayland windows and are sharp; Spotify too, through `NIXOS_OZONE_WL`. DBeaver
  stays on XWayland and looks soft (`GDK_BACKEND=wayland dbeaver` runs it natively, with
  SWT's Wayland quirks).
- **Splitting the configs later:** link `~/.config/somewm` to its own folder in
  `home/home.nix`; SomeWM prefers that over `~/.config/awesome`.
- **Carousel layout** (SomeWM only, last in the layout list): niri-style scrolling columns.
  New windows open as a new column at half the screen width; the view scrolls to keep the
  focused column visible. `Super+H/L` focus left/right · `Super+Shift+H/L` move the column ·
  `Super+Ctrl+H/L` narrower/wider (5 %) · `Super+=` width presets 1/3 → 1/2 → 2/3 → full ·
  `Super+[` / `Super+]` put the window into the left/right column, or, if it is stacked, back
  into its own column · `Super+Home/End` first/last column · three-finger swipe pans the view.
  `=`, `[`, `]` are bound by key position, so they are the same keys on the se layout.
- **Window animation** (SomeWM only): windows glide to their new place in 0.25 s when the
  tiling changes (not when switching workspaces). `layout_anim.duration` in `rc.lua` sets the speed; 0 turns it off. Not used
  in carousel, which animates its own scrolling.
- **SomeWM 2.x:** the shared config already runs on it (migrated 2026-10-13, tested on
  2.1-dev), but we stay on 1.4 until 2.1 is tagged. Rounded window corners come with 2.1,
  but there the border stays square and leaves a notch at each corner. What changed,
  how it was tested and the upgrade checklist are in
  [docs/somewm-2.1.md](docs/somewm-2.1.md).
- **Notifications under SomeWM** use naughty's box layout (`request::display` in
  `rc.lua`). Awesome keeps its built-in popups.
- **Floating rules under SomeWM.**
  - **Class rules need the Wayland name.** A native Wayland app reports its app id as
    its class, sometimes spelled differently from X11. For example, Arandr is `arandr`
    there; the match is case-sensitive.
  - **Rules on role or instance only match X11 windows.** Wayland windows have neither.
  - **Chrome popups** (Outlook's message window, sign-in popups) carry no popup marker on
    Wayland. A SomeWM-only rule floats a Chrome window that appears as `about:blank`,
    which is how pages open popups (`configs/default/rules.lua`). A popup a page opens
    straight on its URL still tiles.
- **Removing it:** drop `./somewm.nix` from the imports in `modules/common.nix` and the
  `somewm` input from `flake.nix`.

## Adding things

- **User packages** (apps, CLI tools): `home/home.nix` → `home.packages`
- **System packages / services** (all hosts): `modules/common.nix`
- **Host-specific anything**: `hosts/<hostname>/` (see *Per-host settings* above)
- **Fonts**: `modules/common.nix` → `fonts.packages`
- **Default app for a file type** (folders → Thunar, PDF → Chrome, images → imv…): `home/home.nix` →
  `xdg.mimeApps.defaultApplications`. Set every type you care about: unset ones fall to whichever
  app happens to claim them (VS Code claims folders). Check with `xdg-mime query default <type>`.
- **Thunar** comes from `programs.thunar` (+ gvfs, tumbler) in `modules/common.nix`, not
  `home.packages`, and its daemon starts with the session so "Show in folder" is instant.
- **New dotfile dir**: put it in `home/dotfiles/` and add a `mkOutOfStoreSymlink` entry in `home/home.nix`
- **New wallpaper**: drop it in `home/dotfiles/wallpapers/` and commit — `.gitattributes` routes it
  through Git LFS. Wallpapers committed before 2026-09-25 are still plain blobs (history wasn't
  rewritten). Never widen the LFS pattern to files Nix reads at build time (e.g.
  `hosts/proasync-laptop/sddm-background.jpeg`): a clean-tree flake build would get the pointer, not the image.

After editing nix files, run `nrs`. Dotfile edits under `home/dotfiles/` take effect
immediately (live symlinks) — no rebuild needed unless you add/remove a symlink.

### Updating packages

```bash
cd ~/nixos-config
nix flake update      # bump nixpkgs + home-manager (and somewm) pins
nrd                   # dry-build first
nrs                   # then switch; rollback via systemd-boot menu if needed
```

The lock is pinned to `nixos-unstable`; update little and often, on a branch, one machine
first. **Read [docs/updating.md](docs/updating.md) before updating** — procedure, the
`nrb` + reboot case (switch inhibitors), the post-reboot checklist, and what broke on the
8-month jump of 2026-10-09.

## Installing on a new machine

From the NixOS live USB, one script partitions the new disk, installs this repo's
config for the host and sets the passwords:

```sh
git clone https://github.com/proasync/nixos-config.git
cd nixos-config
sudo bash scripts/install.sh <host>
```

It only offers disks that are neither the live USB nor Windows (NTFS/BitLocker), and
asks you to type the disk's name and `ERASE`. **Read [docs/install.md](docs/install.md)
first:** backups, writing the USB stick, the boot menu, adding a new host, and the
manual steps after the first boot (commit the generated hardware config, Git LFS,
Tailscale, app logins, dev repos).
