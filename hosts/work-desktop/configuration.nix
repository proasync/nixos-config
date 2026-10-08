{ config, pkgs, ... }:

# work-desktop — AMD Ryzen 5 5600X + Radeon RX 470 (Polaris, amdgpu), 32 GB,
# three 1920x1080/1200 monitors at 1x (no HiDPI).
# Mirrors home-desktop (same dev services), plus remote access so the laptop
# can SSH in over Tailscale. Everything shared lives in modules/common.nix;
# only genuinely work-desktop-specific settings belong here.

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/dev-services.nix    # Postgres (portal), MariaDB + Apache/PHP (WordPress)
    ../../modules/remote-access.nix   # Tailscale + tailnet-only SSH
    # No lan-dev-ports: the office LAN stays closed; the phone uses Tailscale.
  ];

  # GPU: RX 470 (GCN 4) is handled by amdgpu out of the box; VA-API comes from
  # mesa (radeonsi), which hardware.graphics enables by default.
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Install day: set this to what nixos-generate-config writes, then never
  # change it (it pins stateful defaults such as database data layouts).
  system.stateVersion = "26.05";
}
