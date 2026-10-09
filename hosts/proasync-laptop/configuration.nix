{ config, pkgs, ... }:

# proasync-laptop — ASUS Zenbook S 13 UX5304MA
# (Intel Core Ultra 7 155U "Meteor Lake", Intel Arc iGPU, 2880x1800 OLED).
# Everything shared lives in modules/common.nix (system) and
# modules/dev-services.nix (databases/WordPress). Only genuinely
# laptop-specific settings belong here.

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/dev-services.nix
    ../../modules/remote-access.nix   # Tailscale + tailnet-only SSH
    ../../modules/lan-dev-ports.nix   # Expo/Metro + training API for the phone
  ];

  # Enable full Magic SysRq for emergency recovery (Alt+SysRq+REISUB)
  boot.kernel.sysctl."kernel.sysrq" = 1;

  # ── USB root protection ────────────────────────────────
  # Root filesystem is on a USB SSD. Without this, USB power management
  # can suspend the drive during sleep, killing the root fs and freezing.
  boot.kernelParams = [ "usbcore.autosuspend=-1" ];

  # ── Intel Integrated Sensor Hub (ISH) — disabled ──────
  # ISHTP firmware times out every ~30s, wedging i915 IPC paths and
  # causing UI lag (esp. in Chrome's gpu-process). Sensors aren't used.
  boot.blacklistedKernelModules = [
    "intel_ishtp_hid"
    "intel_ishtp_loader"
    "intel_ish_ipc"
    "intel_ishtp"
    # xe: the other driver matching the GPU (8086:7d45). It refuses Meteor Lake
    # anyway, and keeping it out removes the i915/xe load race (see initrd below).
    "xe"
  ];

  # ── WiFi: force iwlwifi to load at boot ────────────────
  # The Meteor Lake CNVi wifi (Intel 8086:7e40) isn't always ready when
  # udev coldplugs, so its modalias auto-load event can be missed and the
  # interface never comes up (manual `modprobe iwlwifi` works fine — proof
  # it's a load-timing race, not firmware/hardware). Loading it explicitly
  # via systemd-modules-load makes it deterministic. Merges with kvm-intel
  # from hardware-configuration.nix.
  boot.kernelModules = [ "iwlwifi" ];

  # ── GPU: load i915 in the initrd ───────────────────────
  # 2026-09-30: a boot came up with no i915 at all — same modalias-race class
  # as iwlwifi above. The GPU's PCI id resolves to both i915 and xe; only xe
  # (which refuses Meteor Lake without force_probe) got loaded. X then started
  # on a dummy 800x600 "None-1" output with llvmpipe: unusable, hung-looking
  # session. Loading i915 from the initrd makes it deterministic (+ early KMS).
  # See docs/external-display.md for the symptoms.
  boot.initrd.kernelModules = [ "i915" ];

  # ── GPU / hardware acceleration (Intel Core Ultra / Xe) ─
  services.xserver.videoDrivers = [ "modesetting" ];
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver  # iHD VA-API driver (Broadwell+, required for Meteor Lake)
    ];
  };
  environment.variables.LIBVA_DRIVER_NAME = "iHD";
  environment.systemPackages = with pkgs; [ libva-utils ];

  # Custom SDDM wallpaper (modules/sddm-theme.nix)
  proasync.sddmBackground = ./sddm-background.jpeg;

  # ── Bluetooth ──────────────────────────────────────────
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # ── Power management ───────────────────────────────────
  services.thermald.enable = true;          # Intel thermal daemon — prevents throttling/overheating
  services.power-profiles-daemon.enable = true;  # Balanced/performance/power-save switching

  # ── Lid switch — let Hyprland handle it ───────────────
  services.logind.settings.Login.HandleLidSwitch = "ignore";
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";
  services.logind.settings.Login.HandleLidSwitchDocked = "ignore";

  # ── SDDM HiDPI (2880x1800 display) ────────────────────
  services.displayManager.sddm.settings = {
    General.EnableHiDPI = true;
    Wayland.EnableHiDPI = true;
  };
  systemd.services.display-manager.environment.QT_SCALE_FACTOR = "2";
  # Awesome is this laptop's desktop. SDDM remembers the last session by its
  # /nix/store path, which changes on updates; then it fell back to another
  # session (2026-10-09 it logged into niri). This makes the fallback Awesome.
  services.displayManager.defaultSession = "none+awesome";

  # ── X11 HiDPI (for Awesome WM on 2880x1800) ──────────
  # Xft.dpi 160 itself comes from home/home.nix xresources (merged by the
  # xrdb call in modules/common.nix sessionCommands).
  services.xserver.displayManager.sessionCommands = ''
    export QT_AUTO_SCREEN_SCALE_FACTOR=1
  '';

  system.stateVersion = "25.11";
}
