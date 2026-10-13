{ writeShellApplication, libnotify }:

# pSwarm — Andreas's own agent-coding desktop app (proasync-monorepo/apps/pswarm-desktop,
# a Tauri shell around pswarm-server). This is a *launcher*, not a Nix build of the app:
# it runs the release binary from the repo checkout inside the repo's `nix-shell`, which
# supplies the runtime pieces (node/pnpm for the server sidecar, WebKitGTK env, the
# dlopen'ed appindicator lib), via the repo's own launcher script. Build the binary first:
#   cd ~/dev/proasync-monorepo && nix-shell --run 'pnpm --filter @proasync/pswarm-desktop build'
# A proper derivation (vendored cargo + pnpm deps) is a later step — see
# docs/projects/pswarm/roadmap.md § M4 in the monorepo.
writeShellApplication {
  name = "pswarm";
  runtimeInputs = [ libnotify ];
  # The launch logic (project argument, terminal detection, nix-shell) lives in the repo,
  # next to the app it starts, so changing it needs no rebuild here:
  #   pswarm              from a terminal: scoped to the directory you are in
  #   pswarm ~/dev/foo    scoped to that project
  #   (app menu)          all projects
  text = ''
    repo="''${PSWARM_REPO:-$HOME/dev/proasync-monorepo}"
    launcher="$repo/apps/pswarm-desktop/scripts/pswarm"
    if [ ! -x "$launcher" ]; then
      msg="No pSwarm checkout at $repo (set PSWARM_REPO)"
      notify-send "pSwarm" "$msg" || true
      echo "pswarm: $msg" >&2
      exit 1
    fi
    exec "$launcher" "$@"
  '';
}
