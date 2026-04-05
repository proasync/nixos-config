{ config, pkgs, lib, ... }:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

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
    nerd-fonts.mononoki
    adwaita-icon-theme
    bibata-cursors
    libsecret
    usbutils
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
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Electron / Chromium runtime dependencies
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
  ];
  security.polkit.enable = true;
}
