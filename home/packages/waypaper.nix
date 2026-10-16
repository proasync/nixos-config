{ symlinkJoin, makeWrapper, waypaper }:

# waypaper with its backend chosen by the session: awww under Wayland (SomeWM,
# niri), feh under X11 (Awesome). One config, ~/.config/waypaper/config.ini,
# then serves every session: the same folder and the same wallpaper. Each
# session's login restores it (wm-scripts/wallpaper-restore.sh on Wayland,
# awesome/scripts/wallpaper-restore.sh on X11).
# A --backend given on the command line still wins (argparse takes the last).
# The app-menu entry runs plain `waypaper`, so it gets this wrapper too.

let
  # waypaper builds the --monitor choices from the backend saved in its config,
  # before the command line's --backend applies. With awww saved (a pick made
  # under Wayland), every run under X11 would start an awww-daemon that crashes
  # without Wayland. Accept any monitor name instead; the GUI still lists the
  # monitors of the backend in use.
  patched = waypaper.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace waypaper/__main__.py \
        --replace-fail 'choices=get_monitor_options(cf.backend))' ')'
    '';
  });
in
symlinkJoin {
  name = "waypaper-${waypaper.version}";
  paths = [ patched ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/waypaper --run \
      'if [ -n "$WAYLAND_DISPLAY" ]; then set -- --backend awww "$@"; else set -- --backend feh "$@"; fi'
  '';
}
