{ lib, symlinkJoin, makeWrapper, waypaper, xwallpaper }:

# waypaper with its backend chosen by the session: awww under Wayland (SomeWM,
# niri), xwallpaper under X11 (Awesome). Both set a wallpaper per monitor or
# for all of them. One config, ~/.config/waypaper/config.ini, serves every
# session: an "All" pick shows everywhere; a per-monitor pick only where that
# monitor name exists (X11 calls them DisplayPort-0, HDMI-A-0, …; Wayland DP-1,
# HDMI-A-1, …). Each session's login restores it (wm-scripts/wallpaper-restore.sh
# on Wayland, awesome/scripts/wallpaper-restore.sh on X11).
# Not feh on X11: waypaper offers no monitor choice for feh.
# A --backend given on the command line still wins (argparse takes the last).
# The app-menu entry runs plain `waypaper`, so it gets this wrapper too.

let
  # Two fixes to waypaper 2.8:
  # - It builds the --monitor choices from the backend saved in its config,
  #   before the command line's --backend applies. With awww saved (a pick made
  #   under Wayland), every run under X11 would start an awww-daemon that
  #   crashes without Wayland. Accept any monitor name instead; the GUI still
  #   lists the monitors of the backend in use.
  # - Its file list for xwallpaper has .jpeg and .png but not .jpg, so a folder
  #   of .jpg wallpapers looked empty. xwallpaper reads them fine.
  patched = waypaper.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace waypaper/__main__.py \
        --replace-fail 'choices=get_monitor_options(cf.backend))' ')'
      substituteInPlace waypaper/options.py \
        --replace-fail "BACKEND_OPTIONS[4]: ['.jpeg', '.png']," "BACKEND_OPTIONS[4]: ['.jpg', '.jpeg', '.png'],"
    '';
  });
in
symlinkJoin {
  name = "waypaper-${waypaper.version}";
  paths = [ patched ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/waypaper --prefix PATH : ${lib.makeBinPath [ xwallpaper ]} --run \
      'if [ -n "$WAYLAND_DISPLAY" ]; then set -- --backend awww "$@"; else set -- --backend xwallpaper "$@"; fi'
  '';
}
