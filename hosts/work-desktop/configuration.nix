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

  # ── Printer ────────────────────────────────────────────
  # The office Brother DCP-L3550CDW, as on Arch: driverless (IPP Everywhere) at
  # its fixed address, A4 and grayscale by default, the default printer.
  # cups-browsed also finds it by itself, but only as a temporary queue, which
  # Chrome's print dialog does not list. The PPD is the one CUPS generated from
  # the printer on Arch, shipped here so that setting up the queue needs no
  # network: model "everywhere" asks the printer at every boot, and fails while
  # it is off. (The Zebra GK420d label printer is not set up yet: on USB, and
  # on Arch a queue with device usb://Zebra%20Technologies/ZTC%20GK420d.)
  services.printing.drivers = [
    (pkgs.runCommand "brother-dcpl3550cdw-ppd" { } ''
      install -Dm444 ${./brother-dcpl3550cdw.ppd} $out/share/cups/model/brother-dcpl3550cdw.ppd
    '')
  ];
  hardware.printers = {
    ensurePrinters = [{
      name = "Brother_DCP-L3550CDW";
      description = "Brother DCP-L3550CDW";
      location = "Office";
      deviceUri = "ipp://192.168.1.100/ipp/print";
      model = "brother-dcpl3550cdw.ppd";
      ppdOptions = {
        PageSize = "A4";
        ColorModel = "Gray";
        Duplex = "None";
      };
    }];
    ensureDefaultPrinter = "Brother_DCP-L3550CDW";
  };

  # The release of the installer it is set up from (26.05). Never change it
  # after install: it pins stateful defaults such as database data layouts.
  system.stateVersion = "26.05";
}
