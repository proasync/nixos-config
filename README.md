# nixos-config

Flake-based NixOS configuration for `home-desktop` and `proasync-laptop`.

- **Desktop:** i5-12400F + RX 7600, AMD GPU
- **Laptop:** ASUS Zenbook S 13 UX5304MA, Intel Core Ultra 7 155U, Intel GPU
- **WM:** Hyprland (Wayland) + Awesome WM (Xorg fallback)
- **Theme:** Catppuccin Mocha Mauve — applied to SDDM, Hyprland, Waybar, Rofi, Alacritty, Mako, Hyprlock, GTK

---

## Repo Structure

```
nixos-config/
├── flake.nix                     # Entry point — defines all hosts
├── bootstrap.nix                 # Minimal config for first boot before flake is applied
├── assets/                       # Static assets (wallpapers used at build time, e.g. SDDM bg)
├── hosts/
│   ├── desktop/
│   │   ├── configuration.nix     # Host-specific: hostname, AMD GPU, dev services
│   │   └── hardware-configuration.nix  # Auto-generated — do NOT copy between machines
│   └── laptop/
│       ├── configuration.nix     # Host-specific: hostname, Intel GPU, dev services
│       └── hardware-configuration.nix  # Auto-generated — do NOT copy between machines
├── modules/
│   └── common.nix                # Shared: SDDM, Hyprland, theming, fonts, system packages
├── home/
│   ├── home.nix                  # Home Manager: user packages, GTK, git, dotfile symlinks
│   ├── scripts/                  # User scripts (imv-dir, etc.)
│   └── dotfiles/                 # Configs symlinked into ~/.config/
│       ├── hypr/                 # Hyprland modular config
│       ├── waybar/               # Bar config + style
│       ├── rofi/                 # Launcher + powermenu themes
│       ├── alacritty/            # Terminal
│       ├── mako/                 # Notifications
│       ├── imv/                  # Image viewer
│       └── wallpapers/           # Wallpaper files for hyprpaper
└── scripts/
    └── setup-wordpress.sh        # One-time WordPress/WooCommerce dev setup
```

---

## Installing on a New Machine (e.g. laptop)

### Step 1 — Install NixOS

Boot the NixOS ISO and install normally. When partitioning, choose EFI + ext4 (or btrfs). Complete the graphical installer or do a minimal install via terminal.

The installer will generate `/etc/nixos/hardware-configuration.nix` — keep that file, you'll need it.

### Step 2 — Enable Flakes and Clone the Repo

After first boot, open a terminal:

```bash
# Enable flakes temporarily
sudo nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#git

# Clone the config
git clone git@github.com:proasync/nixos-config.git ~/nixos-config
# Or via HTTPS if SSH keys aren't set up yet:
git clone https://github.com/proasync/nixos-config.git ~/nixos-config
```

### Step 3 — Create a Host Entry for the New Machine

```bash
mkdir -p ~/nixos-config/hosts/laptop
```

Copy the auto-generated hardware config from the installer:

```bash
cp /etc/nixos/hardware-configuration.nix ~/nixos-config/hosts/laptop/
```

Create `~/nixos-config/hosts/laptop/configuration.nix` based on `hosts/desktop/configuration.nix`, adjusting:

- `networking.hostName` — e.g. `"proasync-laptop"`
- `services.xserver.videoDrivers` — e.g. `[ "intel" ]` or `[ "modesetting" ]` for Intel GPU, or remove for auto-detect
- Remove `services.mysql`, `services.httpd`, `services.postgresql` if you don't want dev services on the laptop
- Keep `system.stateVersion` matching what the NixOS installer used

### Step 4 — Register the Host in flake.nix

Add a new entry to `flake.nix`:

```nix
nixosConfigurations = {
  home-desktop = mkHost {
    hostModule = ./hosts/desktop/configuration.nix;
  };
  proasync-laptop = mkHost {            # <-- add this
    hostModule = ./hosts/laptop/configuration.nix;
  };
};
```

### Step 5 — Stage and Apply

```bash
cd ~/nixos-config
git add hosts/laptop/
sudo nixos-rebuild switch --flake ~/nixos-config#proasync-laptop
```

> **Alias:** After the first successful build, `nrs` (defined in your shell) will do this automatically.

---

## After Install — Manual Steps

These cannot be automated and must be done by hand on each new machine.

### Git Credentials

Git identity is managed declaratively in `home/home.nix`. The config file is a read-only nix store symlink — do **not** run `git config --global`, it will fail. To change name or email, edit `home/home.nix`:

```nix
programs.git = {
  settings.user.name = "your-name";
  settings.user.email = "your@email.com";
};
```

Then run `nrs` to apply.

### SSH Keys

Your SSH keys are **not** stored in this repo. After install:

```bash
# Option A: Generate a new key
ssh-keygen -t ed25519 -C "your@email.com"
# Then add ~/.ssh/id_ed25519.pub to GitHub

# Option B: Restore from backup
cp /path/to/backup/id_ed25519 ~/.ssh/
cp /path/to/backup/id_ed25519.pub ~/.ssh/
chmod 600 ~/.ssh/id_ed25519
```

### Wallpaper (Hyprland)

Edit `~/.config/hypr/hyprpaper.conf` and set your preferred wallpaper:

```conf
preload = /home/proasync/.config/wallpapers/your-wallpaper.png
wallpaper {
    monitor =
    path = /home/proasync/.config/wallpapers/your-wallpaper.png
}
```

Then restart hyprpaper:

```bash
pkill hyprpaper && hyprpaper &
```

Wallpaper files are in `home/dotfiles/wallpapers/` (symlinked to `~/.config/wallpapers/`).

### App Accounts (must log in manually)

| App           | Notes                                               |
| ------------- | --------------------------------------------------- |
| Google Chrome | Sign in to sync bookmarks/extensions                |
| VS Code       | Sign in for Settings Sync                           |
| Signal        | Link as new device from phone                       |
| WhatsApp      | Scan QR code from phone                             |
| Teams         | Sign in with Microsoft account                      |
| Spotify       | Sign in                                             |
| Obsidian      | Point at your vault folder (`~/notes/` or wherever) |

### WordPress Dev Setup (desktop only)

If you need the WordPress/WooCommerce dev environment:

```bash
sudo bash ~/nixos-config/scripts/setup-wordpress.sh
```

You will be prompted for an admin password. Then clone your plugin repo:

```bash
mkdir -p ~/dev
git clone git@github.com:proasync/wisdom-woocommerce-plugin.git ~/dev/wisdom-woocommerce-plugin
```

### Dev Repos

```bash
mkdir -p ~/dev
git clone git@github.com:proasync/pagoda-monorepo.git ~/dev/pagoda-monorepo
git clone git@github.com:proasync/wisdom-woocommerce-plugin.git ~/dev/wisdom-woocommerce-plugin
```

---

## Keyboard Remapping: Vim Arrows with CapsLock

CapsLock → Nav layer, Nav+HJKL → arrow keys. Declared in `modules/common.nix` via `services.keyd` and applied automatically on every `nixos-rebuild`. No manual steps needed on a new machine.

| Key combo       | Output     |
| --------------- | ---------- |
| `CapsLock + H`  | ← Left     |
| `CapsLock + J`  | ↓ Down     |
| `CapsLock + K`  | ↑ Up       |
| `CapsLock + L`  | → Right    |
| `CapsLock + 1`  | F1         |
| `CapsLock + 2`  | F2         |
| `CapsLock + 3`  | F3         |
| `CapsLock + 4`  | F4         |
| `CapsLock + 5`  | F5         |
| `CapsLock + 6`  | F6         |
| `CapsLock + 7`  | F7         |
| `CapsLock + 8`  | F8         |
| `CapsLock + 9`  | F9         |

Works system-wide at the kernel input level — terminals, browsers, Hyprland, everything. For more customization, see [keyd documentation](https://github.com/rvaiya/keyd).

---

## Day-to-Day Usage

| Command                          | Action                                                                             |
| -------------------------------- | ---------------------------------------------------------------------------------- |
| `nrs`                            | Rebuild and switch (`sudo nixos-rebuild switch --flake ~/nixos-config#<hostname>`) |
| `hyprctl reload`                 | Reload Hyprland (picks up sourced config files)                                    |
| `pkill hyprpaper && hyprpaper &` | Reload wallpaper after changing hyprpaper.conf                                     |

### Key Hyprland Shortcuts

| Shortcut                          | Action                             |
| --------------------------------- | ---------------------------------- |
| `Super + Return`                  | Terminal (Alacritty)               |
| `Super + R` / `Super + Shift + D` | App launcher (Rofi)                |
| `Super + Q`                       | Close window                       |
| `Super + P`                       | Screenshot → Satty annotation tool |
| `Super + X`                       | Power menu                         |
| `Super + H/J/K/L`                 | Focus window (vim keys)            |
| `Super + Shift + H/J/K/L`         | Move window                        |
| `Super + Alt + H/J/K/L`           | Resize window                      |
| `Super + 1-9`                     | Switch workspace                   |
| `Super + Tab` / `Alt + Tab`       | Cycle workspaces                   |
| `Super + F`                       | Fullscreen                         |
| `Super + Shift + Space`           | Toggle floating                    |
| `Super + B`                       | Toggle Waybar                      |
| `Super + V`                       | PulseAudio volume control          |
| `Super + Escape`                  | Kill window (cursor mode)          |
| `Ctrl + Shift + Escape`           | Task manager (htop)                |

---

## Adding Packages

- **User packages** (apps, CLI tools): `home/home.nix` → `home.packages`
- **System packages** (system-wide, all users): `modules/common.nix` → `environment.systemPackages`
- **Host-specific services**: `hosts/<hostname>/configuration.nix`

After editing, run `nrs`.
