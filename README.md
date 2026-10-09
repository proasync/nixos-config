# nixos-config

Flake-based NixOS + Home Manager configuration for three machines:

| | `home-desktop` | `proasync-laptop` | `work-desktop` |
| --- | --- | --- | --- |
| Hardware | i5-12400F + RX 7600 | ASUS Zenbook S 13 UX5304MA (Core Ultra 7 155U) | Ryzen 5 5600X + RX 470, 32 GB |
| GPU | AMD (`amdgpu`) | Intel Arc iGPU (`modesetting` + iHD VA-API) | AMD (`amdgpu`) |
| Display | standard DPI | 2880x1800 HiDPI (SDDM 2×, Xft.dpi 160, Hyprland 1.67×) | 3 × 1920x1080/1200, standard DPI |
| Host-only quirks | — | USB-root autosuspend guard, Intel ISH blacklist, i915 in initrd + `xe` blacklisted, iwlwifi force-load, thermald, power-profiles-daemon, lid handling, Bluetooth | — |
| Remote access (Tailscale + tailnet-only SSH) | — | yes | yes |
| Phone dev ports on LAN (8081, 4300) | yes | yes | — (phone uses Tailscale) |
| SDDM theme | stock catppuccin-sddm-corners | same + custom wallpaper | stock |
| Dev services | MariaDB, Apache+PHP, PostgreSQL | same | same |
| Status | | | **not installed yet**: hardware config is a placeholder (see *Installing on a new machine*) |

- **WMs (all hosts):** Hyprland (Wayland, primary), niri (Wayland), Awesome (Xorg fallback)
- **Theme:** Catppuccin Mocha Mauve — SDDM, Hyprland, Waybar, Rofi, Alacritty, Mako, Hyprlock, GTK
- **Wallpaper:** feh on X11 (`awesome/scripts/wallpaper-restore.sh` replays `~/.fehbg`); `awww` daemon (formerly swww) + `waypaper` picker available on Wayland — final approach TBD

## Repo structure

```
nixos-config/
├── flake.nix                  # Entry point — host list; mkHost <name> wires hosts/<name>/
├── assets/                    # Build-time static assets
├── docs/
│   ├── desktop-freeze.md      # laptop freeze runbook: escape hatches, logs, past incidents
│   ├── dev-environments.md    # pagoda/proasync monorepo dev setup on NixOS
│   └── external-display.md    # laptop → TV/projector runbook (read before touching xrandr)
├── hosts/                     # one folder per host, named exactly like the hostname
│   ├── home-desktop/          # AMD GPU
│   ├── proasync-laptop/       # Intel GPU/VA-API, HiDPI, power, hardware quirks
│   │   └── home.nix           # per-host Home Manager overrides (Xft.dpi)
│   └── work-desktop/          # AMD GPU, remote access (hardware config = placeholder)
│       (each has configuration.nix, hardware-configuration.nix and hypr/monitors.conf;
│        home.nix and hypr/hostextras.conf are optional)
├── modules/
│   ├── common.nix             # Everything shared: boot, locale, user, WMs, SDDM, audio,
│   │                          #   fonts, keyd, nix-ld (Electron libs), docker, printing, gc,
│   │                          #   zram swap + earlyoom
│   ├── sddm-theme.nix         # SDDM theme package; `proasync.sddmBackground` per host
│   ├── dev-services.nix       # MariaDB + Apache/PHP (WordPress) + PostgreSQL — imported per host
│   ├── remote-access.nix      # Tailscale + tailnet-only SSH — imported per host
│   └── lan-dev-ports.nix      # firewall ports for phone dev (Expo/Metro, training API) — per host
├── home/
│   ├── home.nix               # Home Manager: packages, bash, git, GTK, dotfile symlinks
│   ├── scripts/               # User scripts installed to ~/.local/bin
│   ├── applications/          # Custom .desktop entries
│   └── dotfiles/              # Live-symlinked into ~/.config/ (edit → takes effect, no rebuild)
│       ├── hypr/  niri/  awesome/   # window managers
│       ├── waybar/  rofi/  mako/    # bar, launcher, notifications
│       ├── alacritty/  btop/  cava/ # terminal & TUI rice
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
- `hypr/monitors.conf` — **required** for every host (an assertion fails the build without
  it). nwg-displays (Super+D) writes through the `~/.config/hypr` symlink, so this must
  never be a file that hosts share.
- `hypr/hostextras.conf` *(optional)* — falls back to the no-op `home/dotfiles/hypr/hostextras.conf`,
  which must stay a **regular file** (it was once accidentally committed as a symlink into
  `/nix/store`).
- Awesome does the same at runtime: `home/dotfiles/awesome/configs/<hostname>/`, falling back
  to `configs/default/`. Don't copy the `proasync-laptop` folder to a desktop; it runs the
  laptop's xrandr/DPI setup.

## Day-to-day

| Command | Action |
| --- | --- |
| `nrs` | rebuild + switch (`sudo nixos-rebuild switch --flake ~/nixos-config#$(hostname)`) |
| `nrt` / `nrd` | rebuild test / dry-build |
| `nrb` | rebuild for next boot, then reboot — when `nrs` refuses to switch live |
| `hyprctl reload` | reload Hyprland config |
| `waypaper` | pick a wallpaper for the current Wayland session (not auto-restored on reboot) |
| `Super + W` | popup listing all current Hyprland keybindings |
| `tv-mirror.sh on` / `off` | laptop → TV mirror on X11/Awesome — see [docs/external-display.md](docs/external-display.md) first |
| `Mod+Shift+P` (Awesome) | restart picom (logs to `~/.cache/picom/`) — screen frozen? see [docs/desktop-freeze.md](docs/desktop-freeze.md) |

Frequently used binds: `Super+Return` terminal · `Super+R` launcher · `Super+Q` close ·
`Super+P` screenshot→satty · `Super+X` powermenu · `Super+HJKL` focus ·
`Super+1-9` workspaces · `Super+Tab`/`Alt+Tab` cycle · `Super+O` scratchpad ·
`Super+F1-F6` app launchers. The full, always-current list is in
[keybindings.conf](home/dotfiles/hypr/keybindings.conf) or via `Super+W`.

CapsLock is a nav layer via keyd (`modules/common.nix`): `CapsLock+HJKL` → arrows,
`CapsLock+1-9` → F1-F9. Works system-wide at the kernel level on every host.

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
nix flake update      # bump nixpkgs + home-manager pins
nrd                   # dry-build first
nrs                   # then switch; rollback via systemd-boot menu if needed
```

The lock is pinned to `nixos-unstable`; update deliberately and test, don't let it drift
for months and update in a panic.

- One `flake.lock` serves every host: update and test on one machine, commit + push,
  then `git pull && nrs` on the others when convenient — they get identical versions.
- Fix *evaluation warnings* too (renamed packages/options); they become errors later.
  Check all hosts: `nix eval --raw .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`.
- Rollback restores programs, not data. Databases are pinned to a major version
  (`postgresql_17`, `mariadb_114` in `modules/dev-services.nix`) — bump those on purpose.
- Terminal `claude` (and everything else from nixpkgs) only moves when the lock does;
  the VS Code extension updates itself.
- If `nrs` stops right after building with a "switch inhibitor" message, a core
  component changed and can't be swapped live: run `nrb` (or, before that alias exists,
  `sudo nixos-rebuild boot --flake ~/nixos-config#$(hostname)`) and reboot. Until then
  the boot menu does not contain the new generation.
- Last update: 2026-10-09 (from 2026-02-13): nitrogen removed → feh, swww → awww,
  libreoffice-fresh → libreoffice, Firefox `configPath`, `gtk.gtk4.theme`. D-Bus
  default changed to dbus-broker (switch inhibitor) → needs `nrb` + reboot on each host.

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
   closest existing host) and `hypr/monitors.conf`, and add `"<newhost>"` to the host list
   in `flake.nix`. (`work-desktop` already exists.)
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
