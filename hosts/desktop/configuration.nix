{ config, pkgs, ... }:

# home-desktop — i5-12400F + RX 7600 (AMD GPU).
# Everything shared lives in modules/common.nix (system) and
# modules/dev-services.nix (databases/WordPress). Only genuinely
# desktop-specific settings belong here.

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/dev-services.nix
  ];

  networking.hostName = "home-desktop";

  # GPU drivers (desktop = AMD)
  services.xserver.videoDrivers = [ "amdgpu" ];

  # SDDM theme (unmodified — laptop overrides it with a custom wallpaper)
  environment.systemPackages = [ pkgs.catppuccin-sddm-corners ];

  system.stateVersion = "25.11";
}
