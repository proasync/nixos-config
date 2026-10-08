{ config, pkgs, ... }:

# home-desktop — i5-12400F + RX 7600 (AMD GPU).
# Everything shared lives in modules/common.nix (system) and
# modules/dev-services.nix (databases/WordPress). Only genuinely
# desktop-specific settings belong here.

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/dev-services.nix
    ../../modules/lan-dev-ports.nix   # Expo/Metro + training API for the phone
  ];

  # GPU drivers (desktop = AMD)
  services.xserver.videoDrivers = [ "amdgpu" ];

  system.stateVersion = "25.11";
}
