{ config, lib, pkgs, ... }:

# SDDM theme package for every host (common.nix selects the theme by name).
# A host can swap in its own background:
#   proasync.sddmBackground = ./sddm-background.jpeg;

let
  bg = config.proasync.sddmBackground;
in
{
  options.proasync.sddmBackground = lib.mkOption {
    type = lib.types.nullOr lib.types.path;
    default = null;
    description = "Custom SDDM background for catppuccin-sddm-corners (null = theme default).";
  };

  config.environment.systemPackages = [
    (if bg == null then pkgs.catppuccin-sddm-corners
     else pkgs.catppuccin-sddm-corners.overrideAttrs (old: {
       postInstall = (old.postInstall or "") + ''
         cp ${bg} $out/share/sddm/themes/catppuccin-sddm-corners/backgrounds/custom.jpeg
         substituteInPlace $out/share/sddm/themes/catppuccin-sddm-corners/theme.conf \
           --replace-fail 'Background="backgrounds/flatppuccin_macchiato.png"' 'Background="backgrounds/custom.jpeg"'
       '';
     }))
  ];
}
