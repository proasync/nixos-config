{ writeShellApplication, libnotify }:

# pSwarm — Andreas's own agent-coding desktop app (proasync-monorepo/apps/pswarm-desktop,
# a Tauri shell around pswarm-server). This is a *launcher*, not a Nix build of the app:
# it runs the release binary from the repo checkout inside the repo's `nix-shell`, which
# supplies the runtime pieces (node/pnpm for the server sidecar, WebKitGTK env, the
# dlopen'ed appindicator lib). Build the binary first:
#   cd ~/dev/proasync-monorepo && nix-shell --run 'pnpm --filter @proasync/pswarm-desktop build'
# A proper derivation (vendored cargo + pnpm deps) is a later step — see
# docs/projects/pswarm/roadmap.md § M4 in the monorepo.
writeShellApplication {
  name = "pswarm";
  runtimeInputs = [ libnotify ];
  text = ''
    repo="''${PSWARM_REPO:-$HOME/dev/proasync-monorepo}"
    bin="$repo/apps/pswarm-desktop/src-tauri/target/release/pswarm"
    if [ ! -x "$bin" ]; then
      msg="No release build at $bin — run: pnpm --filter @proasync/pswarm-desktop build"
      notify-send "pSwarm" "$msg" || true
      echo "pswarm: $msg" >&2
      exit 1
    fi
    cd "$repo"
    exec nix-shell --run "PSWARM_REPO='$repo' exec '$bin'"
  '';
}
