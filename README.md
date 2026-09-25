# nixos-config

Flake-based NixOS + Home Manager configuration for two machines:

| | `home-desktop` | `proasync-laptop` |
| --- | --- | --- |
| Hardware | i5-12400F + RX 7600 | ASUS Zenbook S 13 UX5304MA (Core Ultra 7 155U) |
| GPU | AMD (`amdgpu`) | Intel Arc iGPU (`modesetting` + iHD VA-API) |
| Display | standard DPI | 2880x1800 HiDPI (SDDM 2×, Xft.dpi 160, Hyprland 1.67×) |
| Laptop-only quirks | — | USB-root autosuspend guard, Intel ISH blacklist, thermald, power-profiles-daemon, lid handling, Bluetooth |
| SDDM theme | stock catppuccin-sddm-corners | same theme + custom wallpaper override |
| Dev services | MariaDB, Apache+PHP, PostgreSQL | same (via `modules/dev-services.nix`) |

- **WMs (all hosts):** Hyprland (Wayland, primary), niri (Wayland), Awesome (Xorg fallback)
- **Theme:** Catppuccin Mocha Mauve — SDDM, Hyprland, Waybar, Rofi, Alacritty, Mako, Hyprlock, GTK
- **Wallpaper:** nitrogen (X11/current setup); `swww` daemon + `waypaper` picker available on Wayland — final approach TBD

## Repo structure

```
nixos-config/
├── flake.nix                  # Entry point — one mkHost call per machine
├── bootstrap.nix              # Minimal config for first boot before the flake is applied
├── assets/                    # Build-time static assets
├── docs/
│   └── dev-environments.md    # pagoda/proasync monorepo dev setup on NixOS
├── hosts/
│   ├── desktop/               # hostname, AMD GPU, SDDM theme
│   └── laptop/                # hostname, Intel GPU/VA-API, HiDPI, power, hardware quirks
│       └── hypr/              # laptop-only monitors.conf + hostextras.conf overrides
├── modules/
│   ├── common.nix             # Everything shared: boot, locale, user, WMs, SDDM, audio,
│   │                          #   fonts, keyd, nix-ld (Electron libs), docker, printing, gc
│   └── dev-services.nix       # MariaDB + Apache/PHP (WordPress) + PostgreSQL — imported per host
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

**Desktop vs laptop:** shared config lives in `modules/`; anything host-specific lives in
`hosts/<host>/configuration.nix`. Hyprland's `monitors.conf` and `hostextras.conf` are the
same pattern at the dotfile level — `home/home.nix` binds the laptop to
`hosts/laptop/hypr/*` and every other host to the defaults in `home/dotfiles/hypr/`.
Those two default files must stay **regular files** (they were once accidentally committed
as symlinks into `/nix/store`, which breaks any other machine).

## Day-to-day

| Command | Action |
| --- | --- |
| `nrs` | rebuild + switch (`sudo nixos-rebuild switch --flake ~/nixos-config#$(hostname)`) |
| `nrt` / `nrd` | rebuild test / dry-build |
| `hyprctl reload` | reload Hyprland config |
| `waypaper` | pick a wallpaper for the current Wayland session (not auto-restored on reboot) |
| `Super + W` | popup listing all current Hyprland keybindings |

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
- **Host-specific anything**: `hosts/<hostname>/configuration.nix`
- **Fonts**: `modules/common.nix` → `fonts.packages`
- **New dotfile dir**: put it in `home/dotfiles/` and add a `mkOutOfStoreSymlink` entry in `home/home.nix`
- **New wallpaper**: drop it in `home/dotfiles/wallpapers/` and commit — `.gitattributes` routes it
  through Git LFS. Wallpapers committed before 2026-09-25 are still plain blobs (history wasn't
  rewritten). Never widen the LFS pattern to files Nix reads at build time (e.g.
  `hosts/laptop/sddm-background.jpeg`): a clean-tree flake build would get the pointer, not the image.

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

## Installing on a new machine

1. Install NixOS normally (EFI). Keep the generated `/etc/nixos/hardware-configuration.nix`.
2. `nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#git nixpkgs#git-lfs`, then clone this repo to `~/nixos-config`.
3. Create `hosts/<newhost>/`, copy the machine's `hardware-configuration.nix` in, and write a `configuration.nix` with the hostname, GPU driver, and whatever is genuinely host-specific — everything else comes from `modules/common.nix`. Import `../../modules/dev-services.nix` if the machine should run dev databases.
4. Register the host in `flake.nix` (`nixosConfigurations.<newhost> = mkHost { hostModule = ./hosts/<newhost>/configuration.nix; };`).
5. `git add hosts/<newhost>/` (flakes only see tracked files), then `sudo nixos-rebuild switch --flake ~/nixos-config#<newhost>`.

### Manual steps after install

- **SSH keys** — generate (`ssh-keygen -t ed25519`) or restore from backup; add to GitHub.
- **Git identity** — declared in `home/home.nix` (`programs.git.settings.user.*`); do **not** use `git config --global` (the config file is a read-only symlink).
- **Git LFS hooks** — `cd ~/nixos-config && git lfs update && git lfs pull`. Home Manager
  (`programs.git.lfs`) installs git-lfs and its filters, but the per-repo hooks (needed so
  `git push` uploads LFS objects) and the wallpaper downloads are per-clone.
- **Wallpaper** — run `waypaper` (Wayland) or nitrogen (X11) and pick one per session.
- **App logins** — Chrome, VS Code, Signal, WhatsApp, Teams, Spotify, Obsidian.
- **Dev repos** — see [docs/dev-environments.md](docs/dev-environments.md):

  ```bash
  mkdir -p ~/dev
  git clone git@github.com:proasync/pagoda-monorepo.git ~/dev/pagoda-monorepo
  git clone git@github.com:proasync/proasync-monorepo.git ~/dev/proasync-monorepo
  git clone git@github.com:proasync/wisdom-woocommerce-plugin.git ~/dev/wisdom-woocommerce-plugin
  ```

- **WordPress dev env** (optional): `sudo bash ~/nixos-config/scripts/setup-wordpress.sh`
