{ ... }:

# Hyprland — retired 2026-10-10 (too much breakage on updates). niri is the
# Wayland session now, next to Awesome (X11, the daily driver).
#
# No host imports this. To bring Hyprland back on a host, add
# ../../modules/hyprland.nix to `imports` in hosts/<host>/configuration.nix and
# run `nrs`. home/hyprland.nix keys off programs.hyprland.enable, so the
# ~/.config/hypr links, hyprlock, hypridle and the per-host monitors.conf check
# come back with it. The configs in home/dotfiles/hypr/ and hosts/<host>/hypr/
# were kept for exactly that.

{
  programs.hyprland.enable = true;
}
