{ rofi, rofi-unwrapped }:

# rofi with one fix to 2.0.0. Themes' @media rules (min-width etc.) are checked
# against the monitor rofi opens on, but the Wayland backend cannot tell which
# that is (its monitor_active() is a stub that returns FALSE), and the monitor
# size stays uninitialised: whatever is on the stack. So under SomeWM and niri
# the big-screen rule in rofi/launcher.rasi and powermenu.rasi (min-width:
# 2800px, meant for the laptop's panel under X11) applied at random: a launcher
# small one time, huge the next. Starting from zero, it never applies on
# Wayland, as those themes intend; X11 is unchanged.
rofi.override {
  rofi-unwrapped = rofi-unwrapped.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace source/theme.c --replace-fail 'workarea mon;' 'workarea mon = { 0 };'
    '';
  });
}
