{ config, pkgs, lib, ... }:

{
  # Allow unfree packages (selected during installation)
  nixpkgs.config.allowUnfree = true;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Xorg + Awesome window manager (your stable baseline)
  services.xserver.enable = true;
  # AMD GPU drivers
  services.xserver.videoDrivers = [ "amdgpu" ];
  # Enable Awesome window manager
  services.xserver.windowManager.awesome.enable = true;

  # Minimal login manager (SDDM)
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.theme = "catppuccin-mocha-mauve";
  services.displayManager.sddm.package = pkgs.kdePackages.sddm;
  # Enable touchpad and mouse support
  services.libinput.enable = true;

  # Set keyring environment variables for the session
  services.xserver.displayManager.sessionCommands = ''
    export GNOME_KEYRING_CONTROL=/run/user/$UID/keyring
    export SSH_AUTH_SOCK=/run/user/$UID/gcr/ssh
    export GTK_THEME=Adwaita:dark
    export XCURSOR_THEME=Bibata-Modern-Ice
    export XCURSOR_SIZE=24
    systemctl --user import-environment GNOME_KEYRING_CONTROL SSH_AUTH_SOCK GTK_THEME XCURSOR_THEME XCURSOR_SIZE XCURSOR_PATH
    # Load Xresources (cursor theme) and set root window cursor
    ${pkgs.xorg.xrdb}/bin/xrdb -merge $HOME/.Xresources
    ${pkgs.xorg.xsetroot}/bin/xsetroot -cursor_name left_ptr
  '';

  # System packages
  environment.systemPackages = with pkgs; [
   git
   curl
   google-chrome
   brave
   firefox
   alacritty
   xclip
   openssh
   (vscode.override {
     commandLineArgs = [
       "--password-store=gnome-libsecret"
     ];
   })
   dmenu
   rofi
   seahorse
   libsecret
   # Awesome WM dependencies
   picom
   unclutter
   nerd-fonts.mononoki
   adwaita-icon-theme       # Full icon set for Thunar and GTK apps
   bibata-cursors           # Modern cursor theme
   (catppuccin-sddm.override { flavor = "mocha"; })
   # Awesome WM applications (from rc.lua hotkeys)
   xfce.thunar            # File manager
   xfce.thunar-archive-plugin  # Right-click extract/compress in Thunar
   xarchiver              # Lightweight archive manager
   unzip                  # ZIP extraction
   zip                    # ZIP creation
   p7zip                  # 7z, RAR, and other formats
   pavucontrol            # PulseAudio volume control
   flameshot              # Screenshot tool
   htop                   # Task manager
   networkmanagerapplet   # nm-applet
   numlockx               # Numlock control
   nitrogen               # Wallpaper manager (per-screen support)
   teams-for-linux        # Microsoft Teams
   whatsapp-electron      # WhatsApp desktop
   signal-desktop         # Signal messenger
   dbeaver-bin            # Database manager
   gimp                   # Image editor
   inkscape               # Vector graphics editor
   xorg.xkill             # Kill unresponsive windows
   xorg.xrandr            # Display/monitor configuration
   arandr                 # GUI for xrandr
   lsof                   # List open files/ports (debugging)
   # Development tools
   nodejs_20              # Node.js 20.x (default/fallback)
   yarn                   # Yarn package manager
   direnv                 # Per-directory environment management
   nix-direnv             # Cached nix-shell integration for direnv
   fastfetch              # System info (neofetch replacement)
   rsync                  # File sync (WooCommerce plugin dev)
   jq                     # JSON processor (build scripts)
   acl                    # Access control lists (setfacl)
   wp-cli                 # WordPress CLI management
    # Hyprland / Wayland utilities
    waybar                 # Wayland status bar
    # rofi already has Wayland support on NixOS 25.11 (rofi-wayland merged into rofi)
    mako                   # Wayland notification daemon
    hyprpaper              # Hyprland wallpaper manager
    hyprlock               # Hyprland screen locker
    hypridle               # Hyprland idle daemon
    wl-clipboard           # Wayland clipboard (wl-copy/wl-paste)
    grim                   # Wayland screenshot tool
    slurp                  # Wayland region selector
    brightnessctl          # Brightness control
    playerctl              # Media key control
    imv                    # Lightweight image viewer (X11 + Wayland)
    psmisc                 # killall, fuser, pstree
    wlr-randr              # Wayland monitor management (CLI)
    nwg-displays           # Wayland monitor management (GUI, like arandr)
    libnotify              # notify-send command
  ];

  # Cursor theme
  xdg.icons.fallbackCursorThemes = [ "Bibata-Modern-Ice" ];
  environment.variables = {
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
  };

  # Enable D-Bus system message bus
  services.dbus.enable = true;

  # Provide an OS keyring (Secret Service) for VS Code / browsers etc.
  services.gnome.gnome-keyring.enable = true;

  # Make SDDM unlock the keyring when you log in
  security.pam.services.sddm.enableGnomeKeyring = true;

  # Also unlock on TTY login (optional, but nice)
  security.pam.services.login.enableGnomeKeyring = true;

  # Enable dconf for GNOME keyring configuration
  programs.dconf.enable = true;
  # Enable nix-ld for running unpatched dynamic binaries
  programs.nix-ld.enable = true;

  # Hyprland (Wayland compositor) — runs alongside Awesome WM
  programs.hyprland.enable = true;

  # Polkit is often needed for desktop features even without a full DE
  security.polkit.enable = true;

  # MariaDB for WordPress development
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    ensureDatabases = [ "wordpress" ];
    ensureUsers = [
      {
        name = "wordpress";
        ensurePermissions = {
          "wordpress.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  # Apache + PHP for WordPress
  services.httpd = {
    enable = true;
    user = "wwwrun";
    group = "wwwrun";
    virtualHosts.localhost = {
      documentRoot = "/srv/http";
      extraConfig = ''
        <Directory "/srv/http">
          Options Indexes FollowSymLinks
          AllowOverride All
          Require all granted
          DirectoryIndex index.php index.html
        </Directory>
      '';
    };
    enablePHP = true;
    phpPackage = pkgs.php84.buildEnv {
      extensions = { enabled, all }: enabled ++ (with all; [
        mysqli
        pdo_mysql
        curl
        gd
        zip
        mbstring
        xml
        imagick
        intl
        soap
        bcmath
      ]);
      extraConfig = ''
        upload_max_filesize = 64M
        post_max_size = 64M
        memory_limit = 256M
        max_execution_time = 300
      '';
    };
  };

  # PostgreSQL local development database
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
    ensureDatabases = [ "proasync" ];
    ensureUsers = [
      {
        name = "proasync";
        ensureClauses.superuser = true;
        ensureClauses.login = true;
      }
    ];
    authentication = ''
      # Local connections (Unix socket) - trust for dev
      local all all trust
      # Localhost TCP connections - trust for dev
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
    '';
  };
}
