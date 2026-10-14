{ config, pkgs, ... }:

# work-desktop — HP, AMD Ryzen 5 5600G + Radeon RX 460/560D (Polaris, amdgpu), 32 GB,
# three 1920x1080 monitors at 1x (no HiDPI), all on the RX card. Windows lives on
# its own NVMe disk; boot it from the firmware boot menu (F9).
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

  # GPU: the RX 460/560D (GCN 4) and the 5600G's Vega iGPU (unused) are both
  # amdgpu; VA-API comes from mesa (radeonsi), which hardware.graphics enables.
  services.xserver.videoDrivers = [ "amdgpu" ];

  # ── Bluetooth ──────────────────────────────────────────
  # Realtek USB radio; headphones (Sony MDR-XB950B1) are re-paired in blueman.
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # The release of the installer it is set up from (26.05). Never change it
  # after install: it pins stateful defaults such as database data layouts.
  system.stateVersion = "26.05";
}
