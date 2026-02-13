{ config, pkgs, ... }:

{
  # Tillåt unfree (du valde detta i installern)
  nixpkgs.config.allowUnfree = true;

  # Xorg + Awesome (din stabila baseline)
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "amdgpu" ];
  services.xserver.windowManager.awesome.enable = true;

  # Minimal login manager
  services.displayManager.sddm.enable = true;
  services.libinput.enable = true;

  # Bra att ha direkt
  environment.systemPackages = with pkgs; [
    git
    curl
    google-chrome
    alacritty
    xclip
  ];

  # Polkit behövs ofta för “desktopiga” saker även utan DE
  security.polkit.enable = true;
}
