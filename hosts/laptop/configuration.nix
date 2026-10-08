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
  ];

  networking.hostName = "proasync-laptop";

  # ── Tailscale — mesh VPN for remote dev ────────────────
  # Joins the tailnet (work-desktop, phone). After `nrs`, one-time:
  #   sudo tailscale up      (opens browser login — same account as work box)
  # MagicDNS then gives stable names: `ssh proasync@work-desktop` from
  # anywhere — no LAN, no DHCP-address roulette.
  services.tailscale.enable = true;
  networking.firewall = {
    # Trust the tailnet interface (it's only ever our own devices)…
    trustedInterfaces = [ "tailscale0" ];
    # …and allow Tailscale's WireGuard port for direct (non-relayed) links.
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  # ── SSH — reachable ONLY over the tailnet ──────────────
  # openFirewall = false keeps port 22 closed on every real network
  # (home/work/café); tailscale0 being trusted is the sole way in.
  # Keys-only, no root, no passwords.
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

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
  ];

  # ── WiFi: force iwlwifi to load at boot ────────────────
  # The Meteor Lake CNVi wifi (Intel 8086:7e40) isn't always ready when
  # udev coldplugs, so its modalias auto-load event can be missed and the
  # interface never comes up (manual `modprobe iwlwifi` works fine — proof
  # it's a load-timing race, not firmware/hardware). Loading it explicitly
  # via systemd-modules-load makes it deterministic. Merges with kvm-intel
  # from hardware-configuration.nix.
  boot.kernelModules = [ "iwlwifi" ];

  # ── GPU / hardware acceleration (Intel Core Ultra / Xe) ─
  services.xserver.videoDrivers = [ "modesetting" ];
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver  # iHD VA-API driver (Broadwell+, required for Meteor Lake)
    ];
  };
  environment.variables.LIBVA_DRIVER_NAME = "iHD";
  environment.systemPackages = with pkgs; [
    libva-utils
    # Override the SDDM theme to include our custom wallpaper
    (catppuccin-sddm-corners.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        cp ${./sddm-background.jpeg} $out/share/sddm/themes/catppuccin-sddm-corners/backgrounds/custom.jpeg
        substituteInPlace $out/share/sddm/themes/catppuccin-sddm-corners/theme.conf \
          --replace-fail 'Background="backgrounds/flatppuccin_macchiato.png"' 'Background="backgrounds/custom.jpeg"'
      '';
    }))
  ];

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

  # ── X11 HiDPI (for Awesome WM on 2880x1800) ──────────
  # Xft.dpi 160 itself comes from home/home.nix xresources (merged by the
  # xrdb call in modules/common.nix sessionCommands).
  services.xserver.displayManager.sessionCommands = ''
    export QT_AUTO_SCREEN_SCALE_FACTOR=1
  '';

  system.stateVersion = "25.11";
}
