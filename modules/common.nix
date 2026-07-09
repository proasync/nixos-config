{ config, pkgs, lib, ... }:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ── Nix store hygiene ──────────────────────────────────
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.settings.auto-optimise-store = true;  # hard-link identical files

  # ── Bootloader ─────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Networking ─────────────────────────────────────────
  # (hostname is set per host in hosts/<host>/configuration.nix)
  networking.networkmanager.enable = true;

  # ── Timezone & locale ──────────────────────────────────
  time.timeZone = "Europe/Stockholm";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "sv_SE.UTF-8";
    LC_IDENTIFICATION = "sv_SE.UTF-8";
    LC_MEASUREMENT = "sv_SE.UTF-8";
    LC_MONETARY = "sv_SE.UTF-8";
    LC_NAME = "sv_SE.UTF-8";
    LC_NUMERIC = "sv_SE.UTF-8";
    LC_PAPER = "sv_SE.UTF-8";
    LC_TELEPHONE = "sv_SE.UTF-8";
    LC_TIME = "sv_SE.UTF-8";
  };

  # ── Keyboard layout (X11) ──────────────────────────────
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # ── User account ───────────────────────────────────────
  users.users.proasync = {
    isNormalUser = true;
    description = "Proasync";
    extraGroups = [ "networkmanager" "wheel" "docker" "lp" ];
  };

  # ── Display / Window Managers ──────────────────────────
  services.xserver.enable = true;
  services.xserver.windowManager.awesome.enable = true;
  programs.hyprland.enable = true;
  programs.niri.enable = true;

  # ── SDDM ──────────────────────────────────────────────
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.theme = "catppuccin-sddm-corners";
  services.displayManager.sddm.package = pkgs.kdePackages.sddm;
  services.displayManager.sddm.extraPackages = with pkgs.qt6; [
    qt5compat
    qtwayland
    qtquick3d
    qtsvg
  ];
  services.libinput.enable = true;

  # ── USB auto-mount ───────────────────────────────────
  services.udisks2.enable = true;

  # ── Dev: phone ↔ laptop over LAN ──────────────────────
  # 8081 = Expo/Metro (JS bundle); 4300 = training API (sign-in + sync).
  networking.firewall.allowedTCPPorts = [ 8081 4300 ];

  # ── Audio (PipeWire) ──────────────────────────────────
  # Handles Bluetooth audio (A2DP hi-fi + HSP/HFP mic auto-switch) out of the box.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;        # PulseAudio compat — provides pactl/paplay
    wireplumber.enable = true;
  };
  security.rtkit.enable = true; # realtime scheduling for low audio latency

  # ── X11 Session Commands ───────────────────────────────
  services.xserver.displayManager.sessionCommands = ''
    export GNOME_KEYRING_CONTROL=/run/user/$UID/keyring
    export SSH_AUTH_SOCK=/run/user/$UID/gcr/ssh
    export GTK_THEME=catppuccin-mocha-mauve-standard+default
    export XCURSOR_THEME=Bibata-Modern-Ice
    export XCURSOR_SIZE=24
    systemctl --user import-environment GNOME_KEYRING_CONTROL SSH_AUTH_SOCK GTK_THEME XCURSOR_THEME XCURSOR_SIZE XCURSOR_PATH
    ${pkgs.xrdb}/bin/xrdb -merge $HOME/.Xresources
    ${pkgs.xsetroot}/bin/xsetroot -cursor_name left_ptr
  '';

  # ── System-level packages (shared across all hosts) ────
  environment.systemPackages = with pkgs; [
    git
    curl
    openssh
    acl
    psmisc
    adwaita-icon-theme
    bibata-cursors
    libsecret
    usbutils
  ];

  # ── Fonts (registered with fontconfig for all users + SDDM) ──
  fonts.packages = with pkgs; [
    nerd-fonts.mononoki   # terminal / bar / awesome theme glyphs
    font-awesome          # waybar icons
  ];

  # ── Cursor theme ───────────────────────────────────────
  xdg.icons.fallbackCursorThemes = [ "Bibata-Modern-Ice" ];
  environment.variables = {
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
  };

  # ── Keyboard remapping (CapsLock → Fn, Fn+HJKL = arrows) ──
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main.capslock = "layer(nav)";
        nav = {
          h = "left";
          j = "down";
          k = "up";
          l = "right";
          "1" = "f1";
          "2" = "f2";
          "3" = "f3";
          "4" = "f4";
          "5" = "f5";
          "6" = "f6";
          "7" = "f7";
          "8" = "f8";
          "9" = "f9";
        };
      };
    };
  };

  # ── AppImage support (FUSE2) ───────────────────────────
  programs.appimage = {
    enable = true;
    binfmt = true;   # run AppImages directly without appimage-run wrapper
  };

  # ── Printing (CUPS) ────────────────────────────────────
  services.printing = {
    enable = true;
    drivers = with pkgs; [ gutenprint hplip ];
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # ── Docker ─────────────────────────────────────────────
  virtualisation.docker.enable = true;

  # ── Desktop services ───────────────────────────────────
  services.dbus.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;
  programs.dconf.enable = true;
  # nix-ld lets prebuilt dynamic binaries (npm-downloaded Electron, esbuild,
  # prebuild-install artifacts like better-sqlite3, …) run unpatched.
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Electron / Chromium runtime dependencies
    # (pagoda-monorepo apps/printing-service runs Electron 33 from node_modules)
    glib
    gtk3
    nss
    nspr
    dbus
    atk
    at-spi2-atk
    at-spi2-core
    cups
    libdrm
    pango
    cairo
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    mesa
    libgbm
    expat
    libxcb
    libxkbcommon
    alsa-lib
    gdk-pixbuf
    systemd
    libGL
    libxscrnsaver
    libxtst
    libxcursor
    libxi
    libxrender
    libxshmfence
    # generic native-module runtime deps (lightningcss & co. need libstdc++)
    stdenv.cc.cc.lib
    zlib
    fontconfig
    freetype
    wayland
  ];
  security.polkit.enable = true;
}
