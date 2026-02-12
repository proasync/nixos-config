{ config, pkgs, ... }:

{
  # Tillåt unfree (du valde detta i installern)
  nixpkgs.config.allowUnfree = true;

  # Xorg + Awesome (din stabila baseline)
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "amdgpu" ];
  services.xserver.windowManager.awesome.enable = true;

  # Minimal login manager: greetd + tuigreet
  services.greetd.enable = true;
  services.greetd.settings = {
    default_session = {
      command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --user-menu";
    };
  };

  # Bra att ha direkt
  environment.systemPackages = with pkgs; [
    git
    curl
  ];

  # Polkit behövs ofta för “desktopiga” saker även utan DE
  security.polkit.enable = true;
}
