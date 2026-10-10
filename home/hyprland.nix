{ config, pkgs, lib, osConfig, ... }:

# Hyprland's Home Manager side. Active only on hosts that import
# modules/hyprland.nix, which is none since Hyprland was retired (2026-10-10).
# Everything here is Hyprland-only; shared Wayland tools stay in home.nix.

let
  hostName = osConfig.networking.hostName;
  hyprDir = "/home/proasync/nixos-config/home/dotfiles/hypr";
  hostHyprDir = "/home/proasync/nixos-config/hosts/${hostName}/hypr";
  hostHasHyprExtras = builtins.pathExists (../hosts + "/${hostName}/hypr/hostextras.conf");
in
lib.mkIf osConfig.programs.hyprland.enable {
  # monitors.conf is always per host: nwg-displays (Super+D) writes through the
  # ~/.config/hypr symlink, so it must never point at a file other hosts share.
  assertions = [{
    assertion = builtins.pathExists (../hosts + "/${hostName}/hypr/monitors.conf");
    message = "hosts/${hostName}/hypr/monitors.conf is missing: every host running Hyprland needs its own (copy one from another host).";
  }];

  home.packages = with pkgs; [
    hyprlock   # Hyprland's locker; powermenu.sh uses it under Hyprland, swaylock elsewhere
    hypridle
  ];

  # Hyprland is shared, except monitors.conf (always per host) and
  # hostextras.conf (per host if hosts/<host>/hypr/hostextras.conf exists).
  home.file.".config/hypr/hyprland.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${hyprDir}/hyprland.conf";
  home.file.".config/hypr/input.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${hyprDir}/input.conf";
  home.file.".config/hypr/appearance.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${hyprDir}/appearance.conf";
  home.file.".config/hypr/keybindings.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${hyprDir}/keybindings.conf";
  home.file.".config/hypr/windowrules.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${hyprDir}/windowrules.conf";
  home.file.".config/hypr/autostart.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${hyprDir}/autostart.conf";
  home.file.".config/hypr/hyprlock.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${hyprDir}/hyprlock.conf";
  home.file.".config/hypr/scripts".source =
    config.lib.file.mkOutOfStoreSymlink "${hyprDir}/scripts";
  home.file.".config/hypr/monitors.conf" = {
    source = config.lib.file.mkOutOfStoreSymlink "${hostHyprDir}/monitors.conf";
    force = true;
  };
  home.file.".config/hypr/hostextras.conf" = {
    source = config.lib.file.mkOutOfStoreSymlink
      (if hostHasHyprExtras then "${hostHyprDir}/hostextras.conf" else "${hyprDir}/hostextras.conf");
    force = true;
  };

  # Hyprland's bar: plain `waybar` reads ~/.config/waybar. niri starts its own
  # bar with explicit paths into ~/.config/niri/waybar/.
  home.file.".config/waybar".source =
    config.lib.file.mkOutOfStoreSymlink
      "/home/proasync/nixos-config/home/dotfiles/waybar";
}
