# Multi-agent coding setup

How AI coding agents are set up on these machines, why the tools were chosen, and
how to replicate the stack on a non-NixOS box (the Arch work machine, until it's
migrated to NixOS). Written 2026-07.

## Constraints

- **Subscription-only — never an API key.** Everything runs on subscriptions:
  - Claude **20x Max** → drives Claude Code.
  - OpenAI **Codex Pro/Team** → drives the Codex CLI.
- Goal: run multiple coding agents in parallel locally; use Claude Code **and**
  Codex together; later drive agents remotely (SSH/tmux, eventually from a phone).

## The stack (and why)

- **Native Claude Code** — the foundation, on the Max sub. Two parallelism modes:
  - *Subagents / context firewalls* (native) — one session fans out to child
    agents that each spend their own context and return a conclusion.
  - *Git worktrees* — isolated parallel sessions.
- **Claude Squad (`cs`)** — the orchestrator TUI. Gives each agent its own tmux
  session + git worktree, and runs Claude Code **and** Codex (also Gemini/Aider)
  side by side, each on its own subscription login. Linux-native Go binary.
- **tmux** — required by claude-squad; also keeps an agent alive across a
  disconnect (the basis for the future remote-from-phone workflow).
- **gh**, and the **codex** CLI.

Rejected:

- **cmux** — macOS-only (native Swift/AppKit); no Linux build. Waitlisted.
- **Cursor** — its agent cannot use the Claude Max subscription; it bills through
  Cursor's own plan or a bring-your-own Anthropic **API key**. The unofficial
  OAuth workaround was blocked by Anthropic in Jan 2026. Fails the subscription rule.

## How parallel multi-model works

Environment variables are **per-process**, so each tmux/agent session can carry
its own `ANTHROPIC_BASE_URL` / `ANTHROPIC_AUTH_TOKEN` / `ANTHROPIC_MODEL` with no
collision between sessions:

- Claude on Max = plain `claude`.
- Codex = `codex` (separate ChatGPT auth namespace; ignores `ANTHROPIC_*`).
- A third model (e.g. GLM) = the **same** `claude` binary with a per-session
  base-URL override, ideally wrapped in a small launcher script.

**Gotchas:**

- Keep `ANTHROPIC_API_KEY` **unset** — if set, Claude Code silently bills the key
  instead of the Max subscription.
- Never put `ANTHROPIC_BASE_URL` in global/shell env (e.g. `home.sessionVariables`
  in [`../home/home.nix`](../home/home.nix)) — it would hijack every `claude`.
  Keep overrides per-launch only.

## Alternate models (subscription-only)

- **GLM 5.2 — viable on a subscription** via Zhipu's "GLM Coding Plan": point
  Claude Code at `ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic` plus the plan
  token. *Pending: GLM account not yet provisioned.* When it lands, add a
  `claude-glm` wrapper (`writeShellScriptBin`) reading the token from an env var;
  it's inert until invoked and does not interfere with Claude/Codex.
- **Grok — not viable.** A consumer SuperGrok / X Premium subscription grants no
  API access; every coding-agent path is pay-per-token. Skip under the
  subscription-only rule.

## Repo realities for parallel agents

- **proasync-monorepo** (side project): pnpm/Turbo/Biome, **hermetic** (embedded
  PGlite/sqlite, no services). Gate = `pnpm check`. Ideal for parallel agents; the
  only friction is fixed dev ports if running multiple *live* apps at once.
- **pagoda / wisdom-monorepo** (work): Yarn 1 / Node 18, shared single Postgres
  `portal` + fixed ports 3000–5000. Parallel *code* work + static gates
  (`yarn build` / `lint` / `tsc`) are fine; running the *live* app in parallel is
  not (shared DB). Worktree helper: `scripts/dev-copy-env-files-to-worktree.sh`.

See [`dev-environments.md`](dev-environments.md) for the full per-repo toolchain audit.

## Shared agent brain

- Global practices + the `/onboard` and `/audit` commands live in the
  **proasync-dotfiles** repo, symlinked to `~/.claude/CLAUDE.md` and
  `~/.codex/AGENTS.md` via its `bootstrap.sh`. Clone + bootstrap on any machine
  for identical behavior.
- proasync-monorepo carries its own `AGENTS.md` (= `CLAUDE.md`) plus
  `docs/agent-setup.md` and `docs/loops.md`.

## Install

### NixOS (this repo)

Declared in [`../home/home.nix`](../home/home.nix):

- `claude-code`, `codex`, and `tmux` (via `programs.tmux`) are packages/modules.
- `claude-squad` is built from source in
  [`../home/packages/claude-squad.nix`](../home/packages/claude-squad.nix) (not in
  nixpkgs) and added via `callPackage`; it provides `cs`.

Apply with `nrs` (`nixos-rebuild switch`).

### Arch / other Linux (native)

The same binaries, packaged differently:

```
sudo pacman -S tmux github-cli
curl -fsSL https://claude.ai/install.sh | bash                                             # claude-code
npm install -g @openai/codex                                                               # codex
curl -fsSL https://raw.githubusercontent.com/smtg-ai/claude-squad/main/install.sh | bash   # cs (static Go binary)
```

## First run

```
claude          # log in → Claude Max sub
codex login     # log in → Codex Pro/Team sub
cs              # claude-squad TUI; press `n` for a new agent session (own worktree + tmux)
```

Auth is account-based, so nothing is copied between machines — just log in on each.
