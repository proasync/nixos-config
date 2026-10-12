{ config, lib, pkgs, ... }:

# SDDM login screen for every host: the catppuccin-sddm-corners theme (common.nix
# selects it by name), patched here, plus the user avatar.
#
# - Font: the theme asks for "Liga SFMono Nerd Font", which is not installed, so
#   it silently fell back to DejaVu Sans Mono. Use Mononoki Nerd Font, as the
#   other themes here do.
# - GeneralFontSize 9 -> 12 (points): the text in the user/password boxes and the
#   session popup. The boxes scale with the screen, the text does not; at 9 it
#   was small even once the laptop greeter got its 2x scale (hosts/proasync-laptop).
# - Background: a host can set its own:
#     proasync.sddmBackground = ./sddm-background.png;
# - Avatar: SDDM checks FacesDir/<user>.face.icon before ~/.face.icon and
#   AccountsService, and FacesDir is /run/current-system/sw/share/sddm/faces, so
#   a package providing that file is enough.

let
  bg = config.proasync.sddmBackground;
  themeDir = "$out/share/sddm/themes/catppuccin-sddm-corners";
  theme = pkgs.catppuccin-sddm-corners.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      substituteInPlace ${themeDir}/theme.conf \
        --replace-fail 'Font="Liga SFMono Nerd Font"' 'Font="Mononoki Nerd Font"' \
        --replace-fail 'GeneralFontSize="9"' 'GeneralFontSize="12"'
    '' + lib.optionalString (bg != null) ''
      cp ${bg} ${themeDir}/backgrounds/${baseNameOf bg}
      substituteInPlace ${themeDir}/theme.conf \
        --replace-fail 'Background="backgrounds/flatppuccin_macchiato.png"' 'Background="backgrounds/${baseNameOf bg}"'
    '';
  });
  avatar = pkgs.runCommand "sddm-face-proasync" { } ''
    install -Dm444 ${../assets/sddm-avatar-proasync.png} $out/share/sddm/faces/proasync.face.icon
  '';
in
{
  options.proasync.sddmBackground = lib.mkOption {
    type = lib.types.nullOr lib.types.path;
    default = null;
    description = "Custom SDDM background for catppuccin-sddm-corners (null = theme default).";
  };

  config.environment.systemPackages = [ theme avatar ];
}
