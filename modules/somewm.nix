{ pkgs, inputs, ... }:

# SomeWM: AwesomeWM's Lua API on Wayland (wlroots). On trial since 2026-10-10
# as a third SDDM session next to Awesome (X11, the daily driver) and niri.
#
# It reads ~/.config/awesome/rc.lua when there is no ~/.config/somewm/, so
# Awesome and SomeWM share one config. rc.lua sets
# `is_somewm = awesome.release == "somewm"` and skips the X11-only parts there
# (picom, xrandr, xrdb, flameshot, setxkbmap); configs/<host>/somewm.lua holds
# the Wayland output layout. To split the configs later, add a separate
# ~/.config/somewm/ link in home/home.nix.
#
# Imported by modules/common.nix, so every host gets the session. To drop it,
# remove that import and the `somewm` input in flake.nix.

let
  somewm = inputs.somewm.packages.${pkgs.stdenv.hostPlatform.system}.somewm;

  # What SDDM runs for the "somewm" session. Upstream's own wrapper is
  # systemd-unit based and is not built (-Dsystemd=disabled); this does the two
  # things that matter here and nothing else.
  sessionScript = pkgs.writeShellScript "somewm-session" ''
    # Sharpness: apps under XWayland render at 1x and get upscaled to the
    # laptop's 1.67x, which looks soft. Tested 2026-10-10 under SomeWM: Chrome
    # 155, VS Code 1.140, Teams, Obsidian and Signal open as native Wayland
    # windows on their own; Spotify only with NIXOS_OZONE_WL (its nixpkgs
    # wrapper then adds the Wayland flags); DBeaver stays on XWayland (it would
    # need GDK_BACKEND=wayland, and SWT on Wayland has menu/popup quirks).
    # Only this session sets it; it does nothing without WAYLAND_DISPLAY.
    export NIXOS_OZONE_WL=1
    export XDG_CURRENT_DESKTOP=somewm XDG_SESSION_TYPE=wayland

    # Portals: rc.lua exports this session's variables to the systemd user
    # manager so screen sharing works. Take them back when SomeWM ends, and stop
    # the portals, so the next X11 Awesome login starts clean even if the user
    # manager outlives this session (SSH, tmux). Best effort: on shutdown the
    # manager may already be going away, which clears them anyway.
    cleanup() {
      timeout 5 systemctl --user unset-environment \
        WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE NIXOS_OZONE_WL
      timeout 5 systemctl --user stop \
        xdg-desktop-portal.service xdg-desktop-portal-wlr.service xdg-desktop-portal-gtk.service
    }
    trap cleanup EXIT
    trap 'exit 143' TERM HUP INT

    ${somewm}/bin/somewm "$@"
  '';

  # Same session name and desktop name as upstream's somewm.desktop, so SDDM's
  # list and XDG_CURRENT_DESKTOP stay "somewm"; only Exec differs.
  session = pkgs.runCommand "somewm-session" { passthru.providedSessions = [ "somewm" ]; } ''
    mkdir -p $out/share/wayland-sessions
    cat > $out/share/wayland-sessions/somewm.desktop <<EOF
    [Desktop Entry]
    Name=somewm
    Comment=AwesomeWM-compatible Wayland compositor
    Exec=${sessionScript}
    Type=Application
    DesktopNames=somewm
    EOF
  '';
in
{
  environment.systemPackages = [
    somewm   # somewm + somewm-client
    pkgs.wlopm   # screens off/on when idle (swayidle, started by rc.lua)
  ];

  services.displayManager.sessionPackages = [ session ];

  # Screen sharing and screenshots for SomeWM: the wlroots portal (monitor
  # sharing through wlr-screencopy; SomeWM 1.4 has no per-window capture yet,
  # so pick "entire screen"). slurp asks which monitor when there are several.
  xdg.portal.wlr = {
    enable = true;
    settings.screencast = {
      chooser_type = "simple";
      chooser_cmd = "${pkgs.slurp}/bin/slurp -f 'Monitor: %o' -or";
    };
  };

  # Portal choices for XDG_CURRENT_DESKTOP=somewm only. Wins over the
  # somewm-portals.conf the package ships (same choices plus Secret).
  #
  # Why this cannot stall Awesome: xdg-desktop-portal 1.22 only uses a backend
  # named in the current desktop's config, or one whose .portal file lists that
  # desktop in UseIn; otherwise gtk alone (xdp-portal-config.c). An Awesome
  # login exports no XDG_CURRENT_DESKTOP to the systemd user manager, so its
  # portals only ever use gtk, and wlr is never even started there. (1.20.3,
  # before the 2026-10-09 update, also fell back to *any* backend: that is how
  # Hyprland's portal stalled Awesome logins.) The one way in would be
  # XDG_CURRENT_DESKTOP=somewm left behind in the user manager; the session
  # script above removes it, and so does Awesome's login (modules/common.nix).
  xdg.portal.config.somewm = {
    default = [ "gtk" ];
    "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
    "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
    "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
    # gtk's Inhibit needs GNOME's session manager; apps fall back to Wayland's idle-inhibit
    "org.freedesktop.impl.portal.Inhibit" = [ "none" ];
  };
}
