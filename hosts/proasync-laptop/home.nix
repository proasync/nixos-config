{ ... }:

# Per-host Home Manager overrides for proasync-laptop (imported by flake.nix).

{
  # 2880x1800 @ 1.67× (matches Hyprland). Merged into ~/.Xresources by the
  # xrdb call in modules/common.nix sessionCommands.
  xresources.properties."Xft.dpi" = 160;
}
