# nixos-config

Flake-based NixOS + Home Manager configuration for three machines:

| | `home-desktop` | `proasync-laptop` | `work-desktop` |
| --- | --- | --- | --- |
| Hardware | i5-12400F + RX 7600 | ASUS Zenbook S 13 UX5304MA (Core Ultra 7 155U) | Ryzen 5 5600X + RX 470, 32 GB |
| GPU | AMD (`amdgpu`) | Intel Arc iGPU (`modesetting` + iHD VA-API) | AMD (`amdgpu`) |
| Display | standard DPI | 2880x1800 HiDPI (SDDM 2×, Xft.dpi 160, niri 1.67×) | 3 × 1920x1080/1200, standard DPI |
| Host-only quirks | — | USB-root autosuspend guard, Intel ISH blacklist, i915 in initrd + `xe` blacklisted, iwlwifi force-load, thermald, power-profiles-daemon, lid handling, Bluetooth | — |
| Remote access (Tailscale + tailnet-only SSH) | — | yes | yes |
| Phone dev ports on LAN (8081, 4300) | yes | yes | — (phone uses Tailscale) |
| SDDM theme | catppuccin-sddm-corners (Mononoki, larger text), penguin avatar | same + nixos-lightdark2 wallpaper, greeter at 2× on the panel | same as home-desktop |
| Dev services | MariaDB, Apache+PHP, PostgreSQL | same | same |
| Status | | | **not installed yet**: hardware config is a placeholder (see *Installing on a new machine*) |

- **WMs (all hosts):** Awesome (Xorg, the daily driver) and niri (Wayland, scrolling columns),
  plus SomeWM on trial (Wayland, runs Awesome's own config: see *SomeWM (trial)* below).
  Hyprland is retired but its config is kept: see *Hyprland (retired)* below.
- **Theme:** Catppuccin Mocha Mauve — SDDM, Awesome, niri, Waybar, Rofi, Alacritty, Mako, GTK, and the lock
  screens (swaylock on Wayland, i3lock-color on X11)
- **Wallpaper:** feh on X11 (`awesome/scripts/wallpaper-restore.sh` replays `~/.fehbg`); on niri, `waypaper`
  picks it and `wm-scripts/wallpaper-restore.sh` re-applies it at login through the `awww` daemon

## Repo structure

```
nixos-config/
├── flake.nix                  # Entry point — host list; mkHost <name> wires hosts/<name>/
├── assets/                    # Build-time static assets
├── docs/
│   ├── desktop-freeze.md      # laptop freeze runbook: escape hatches, logs, past incidents
│   ├── updating.md            # how to update safely + post-update checklist
│   ├── dev-environments.md    # pagoda/proasync monorepo dev setup on NixOS
│   ├── external-display.md    # laptop → TV/projector runbook (read before touching xrandr)
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
│       ├── wm-scripts/              # power menu, lock, Chrome, touchpad: shared by niri + Hyprland
│       ├── swaylock/                # lock screen theme (niri)
│       ├── waybar/  rofi/  mako/    # bar (waybar/ = Hyprland's; niri's is niri/waybar/), launcher, notifications
│       ├── alacritty/  btop/  cava/ # terminal & TUI rice
│       ├── fastfetch/               # banner every new shell prints; logo NixOS2, 32 cols so lines don't wrap
│       ├── claude/                  # Claude Code settings
│       └── wallpapers/              # browsable by waypaper; stored via Git LFS (see below)
└── scripts/
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
  laptop's xrandr/DPI setup.

## Day-to-day

| Command | Action |
| --- | --- |
| `nrs` | rebuild + switch (`sudo nixos-rebuild switch --flake ~/nixos-config#$(hostname)`) |
| `nrt` / `nrd` | rebuild test / dry-build |
| `nrb` | rebuild for next boot, then reboot — when `nrs` refuses to switch live |
| `niri validate` | check niri's config after editing it (niri reloads it on save; a broken file keeps the old one) |
| `waypaper` | pick the niri wallpaper; it is re-applied at every niri login |
| `Super + W` | popup listing the keybindings (niri's sheet in niri; Hyprland's in Hyprland) |
| `Super + X`, then `k` | lock the screen: i3lock-color on X11 (via xss-lock), swaylock on Wayland. Never automatic in Awesome or SomeWM; screens just turn off after 10 min idle |
| `Super + Shift + T` | show/hide the focused window's titlebar (Awesome, SomeWM; off by default) |
| `Super + C` | drop-down terminal from the top of the screen; same key hides it, and it keeps running (Awesome, SomeWM) |
| click the layout icon (top right) | dropdown of all layouts, current one highlighted; scroll on the icon cycles (Awesome, SomeWM) |
| `Super + Shift + H / L` | swap the window with its left/right neighbour (carousel: move the column) |
| `tv-mirror.sh on` / `off` | laptop → TV mirror on X11/Awesome — see [docs/external-display.md](docs/external-display.md) first |
| `Mod+Shift+P` (Awesome) | restart picom (logs to `~/.cache/picom/`) — screen frozen? see [docs/desktop-freeze.md](docs/desktop-freeze.md) |

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
- **Removing it:** drop `./somewm.nix` from the imports in `modules/common.nix` and the
  `somewm` input from `flake.nix`.

## Adding things

- **User packages** (apps, CLI tools): `home/home.nix` → `home.packages`
- **System packages / services** (all hosts): `modules/common.nix`
- **Host-specific anything**: `hosts/<hostname>/` (see *Per-host settings* above)
- **Fonts**: `modules/common.nix` → `fonts.packages`
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

Before you start, if the machine has other disks (e.g. an old install you keep as a
backup): **unplug them for the install.** Otherwise the installer may put the NixOS
bootloader on the other disk's EFI partition, and `hardware-configuration.nix` may pick up
its partitions. Afterwards NixOS is the default boot entry; reach the old disk through the
firmware boot menu (F8/F11/F12) — systemd-boot does not list OSes on other disks.

1. Install NixOS normally (UEFI; Secure Boot off). Create the user `proasync` (the
   dotfile links hardcode `/home/proasync`). Keep the generated
   `/etc/nixos/hardware-configuration.nix` and note `system.stateVersion` in
   `/etc/nixos/configuration.nix`.
2. `nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#git nixpkgs#git-lfs`,
   then clone this repo to `~/nixos-config` (that exact path — dotfiles link into it).
   Wallpapers arrive as small LFS pointer text files until the *Git LFS* step below.
3. If the host isn't in the repo yet: create `hosts/<newhost>/` with a `configuration.nix`
   (GPU driver, optional module imports, whatever is genuinely host-specific — copy the
   closest existing host) and `niri/monitor.kdl` (copy `home-desktop`'s empty one), and add
   `"<newhost>"` to the host list in `flake.nix`. (`work-desktop` already exists.) Add
   `hypr/monitors.conf` only if the host will run Hyprland.
4. Copy the generated `hardware-configuration.nix` over `hosts/<newhost>/hardware-configuration.nix`
   (for `work-desktop` this replaces the placeholder) and set `system.stateVersion` to the
   value from step 1.
5. `git add hosts/<newhost>/` (flakes only see tracked files), then
   `sudo nixos-rebuild switch --flake ~/nixos-config#<newhost>` — spelled out, because the
   hostname is still `nixos` until this first switch, so `nrs` can't find the host yet.
6. Reboot, then commit the hardware config.

### Manual steps after install

- **SSH keys** — generate (`ssh-keygen -t ed25519`) or restore from backup; add to GitHub.
  Keys allowed to SSH *in* are listed in `modules/remote-access.nix`.
- **Tailscale** (hosts importing `modules/remote-access.nix`) — `sudo tailscale up`. If an older
  install of the same machine is still registered under the same name (e.g. the Arch
  `work-desktop`), remove it in the Tailscale admin console first, or the new node gets a
  `-1` suffix and `ssh proasync@work-desktop` reaches the old one.
- **Git identity** — declared in `home/home.nix` (`programs.git.settings.user.*`); do **not** use `git config --global` (the config file is a read-only symlink).
- **Git LFS** — `cd ~/nixos-config && git lfs update && git lfs pull`. Until this runs, the
  wallpapers added since 2026-09-25 are small text pointer files, not images. Home Manager
  (`programs.git.lfs`) installs git-lfs and its filters, but the per-repo hooks (needed so
  `git push` uploads LFS objects) and the wallpaper downloads are per-clone.
- **Wallpaper** — run `waypaper` (Wayland), or on X11 `feh --bg-scale <laptop img> [<external img>]`
  (feh remembers it in `~/.fehbg`).
- **App logins** — Chrome, VS Code, Signal, WhatsApp, Teams, Spotify, Obsidian.
- **Dev repos** — see [docs/dev-environments.md](docs/dev-environments.md):

  ```bash
  mkdir -p ~/dev
  git clone git@github.com:proasync/pagoda-monorepo.git ~/dev/pagoda-monorepo
  git clone git@github.com:proasync/proasync-monorepo.git ~/dev/proasync-monorepo
  git clone git@github.com:proasync/wisdom-woocommerce-plugin.git ~/dev/wisdom-woocommerce-plugin
  ```

- **WordPress dev env** (optional): `sudo bash ~/nixos-config/scripts/setup-wordpress.sh`
