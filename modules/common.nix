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

  # ── SDDM ──────────────────────────────────────────────
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.theme = "catppuccin-mocha-mauve";
  services.displayManager.sddm.package = pkgs.kdePackages.sddm;
  services.libinput.enable = true;

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
    (catppuccin-sddm.override { flavor = "mocha"; background = ../assets/nixos-dark.png; })
    libsecret
  ];

  # ── Cursor theme ───────────────────────────────────────
  xdg.icons.fallbackCursorThemes = [ "Bibata-Modern-Ice" ];
  environment.variables = {
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
  };

  # ── Desktop services ───────────────────────────────────
  services.dbus.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;
  programs.dconf.enable = true;
  programs.nix-ld.enable = true;
  security.polkit.enable = true;
}
