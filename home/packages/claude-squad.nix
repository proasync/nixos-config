{ lib, buildGoModule, fetchFromGitHub }:

# claude-squad — TUI to run several terminal coding agents (Claude Code, Codex,
# Gemini, Aider …) in parallel, each isolated in its own tmux session + git
# worktree. Not in nixpkgs, so built from source here. Command is `cs`.
#
# Bump procedure when a new tag lands:
#   1. version = "<new>";
#   2. hash → set to lib.fakeHash, rebuild, paste the "got:" value
#   3. vendorHash → same fakeHash → rebuild → paste (only if go.sum changed)
buildGoModule rec {
  pname = "claude-squad";
  version = "1.0.19";

  src = fetchFromGitHub {
    owner = "smtg-ai";
    repo = "claude-squad";
    rev = "v${version}";
    hash = "sha256-9XjixCztPh+VdiFmYWPMC6Cnh2EH70L4eDknteurCkA=";
  };

  vendorHash = "sha256-0EFCao5l9BNX6zdHVziV9ZwJX9v+BNu+e3tcFtYrDJ4=";

  # Upstream's unit tests shell out to `git`/`tmux`, which aren't on PATH inside
  # the Nix build sandbox — skip them (this is a packaging build, not their CI).
  # `git`, `tmux` and the agent CLIs are provided at runtime via home.packages.
  doCheck = false;

  ldflags = [ "-s" "-w" "-X main.version=${version}" ];

  # Upstream installs the binary as `cs`; the Go build produces `claude-squad`.
  # Expose both so either name works.
  postInstall = ''
    ln -s $out/bin/claude-squad $out/bin/cs
  '';

  meta = {
    description = "Manage multiple AI terminal agents (Claude Code, Codex, …) in parallel tmux + git-worktree sessions";
    homepage = "https://github.com/smtg-ai/claude-squad";
    license = lib.licenses.agpl3Only;
    mainProgram = "cs";
  };
}
