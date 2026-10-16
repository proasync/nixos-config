# Global agent practices — Andreas

> **Loaded in every project on this machine** (via `~/.claude/CLAUDE.md`, symlinked
> from `home/dotfiles/claude/CLAUDE.md` in the nixos-config repo). These are *personal,
> cross-repo* habits. Repo-specific rules live in each project's own `CLAUDE.md`/`AGENTS.md`
> and take precedence over these.
>
> This file is the canonical source: edit it in nixos-config. `~/.claude/CLAUDE.md` (Claude
> Code) and `~/.codex/AGENTS.md` (Codex) both link to it — see `home/home.nix`.

## How I want you to work

### Context economy (don't waste the window)
- Keep any root `CLAUDE.md` a **router**, not a manual: overview, commands, hard rules,
  and pointers to deeper docs. Put area-specific detail in nested `CLAUDE.md` files and
  deep detail in `docs/` read on demand.
- Prefer reading the *specific* part of a file you need over whole large files.

### Subagents as context firewalls  ← important
When a task needs reading a large document (e.g. a 2,000-line external-API spec) or
searching across many files, **do it in a subagent, not the main thread.** Spawn a
subagent with a narrow ask ("read the Schenker API spec, return just the auth flow and the
three endpoints I need"), let it spend *its own* context, and hand back only the
conclusion. The main context stays clean and long-lived. Use this for research,
codebase-wide search, and distilling big docs. In Claude Code these are the `Explore`,
`Plan`, and `general-purpose` agents. This is the single biggest lever for not being
limited by context — use it by default for anything wide or deep.

### Definition of done includes docs  ← important
When you change a behavior, **update the relevant doc/runbook in the same change.** Docs
live in the repo and are reviewed in the same branch diff as the code. This is how documentation
stays true without anyone policing it — the agent maintains its own future context. A
stale doc is worse than none; it misleads the next agent.

### Verify by execution, not inspection
Before claiming something works, run the project's real gates (typecheck, lint, tests,
and where possible the actual app/feature) and observe the output. "It should work" is not
evidence. If you can't run a gate, say so — don't assume it passes.

### Safety & reversibility
- Work on a branch; no pull requests — when done, merge the branch into `develop`
  (`git merge --no-ff`), never commit to `main` without being asked. Ask "ready to
  merge into develop?", never "open a PR?".
- Don't touch lockfiles, `node_modules`, or `.env` contents unless explicitly asked.
- For anything irreversible or outward-facing, confirm before acting.

### When ambiguous, ask
If the goal or acceptance criteria are unclear, list the ambiguities and ask rather than
guessing — especially before large or hard-to-reverse work.
