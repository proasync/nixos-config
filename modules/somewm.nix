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
in
{
  environment.systemPackages = [
    somewm   # somewm + somewm-client (the session's Exec is plain `somewm`)
    pkgs.wlopm   # screens off/on when idle (swayidle in configs/*/autostart.lua)
  ];

  # Adds "somewm" to SDDM. It sets XDG_CURRENT_DESKTOP=somewm.
  services.displayManager.sessionPackages = [ somewm ];

  # Portal choices for XDG_CURRENT_DESKTOP=somewm only; Awesome and niri are
  # untouched. This file wins over the somewm-portals.conf the package ships,
  # which routes screenshots and screen sharing to xdg-desktop-portal-wlr.
  # That portal is not installed yet, so screen sharing (Teams, Chrome) does
  # not work in SomeWM. Adding it needs one Awesome login checked for portal
  # timeouts first (see docs/updating.md: Hyprland's portal once stalled every
  # Awesome login for 25 s per call).
  xdg.portal.config.somewm = {
    default = [ "gtk" ];
    "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
    # gtk's Inhibit needs GNOME's session manager; apps fall back to Wayland's idle-inhibit
    "org.freedesktop.impl.portal.Inhibit" = [ "none" ];
  };
}
