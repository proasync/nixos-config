---
description: Onboard to this repo — build a working mental model before being tasked
---

# Onboard to this repository — build a mental model, then stop

You're starting fresh in a repo you don't yet know. Goal: absorb the most important context
efficiently, THEN stop and wait for a task. Do NOT change any code. Be token-aware — do not
read `node_modules`, lockfiles, build output, or entire large files.

> This is the generic onboarding command. A repo may ship its own tuned `onboard` in
> `.claude/commands/` that overrides this — if present, prefer that repo's version.

## Tier 1 — Read fully (small, high-signal)
- `CLAUDE.md` / `AGENTS.md`  — conventions, dev commands, hard rules (treat as binding)
- `ARCHITECTURE.md` if present — apps, packages, boundaries, ownership
- `README.md` — setup, how things run
- Any `docs/agent-setup.md` or equivalent "how we work here" doc

## Tier 2 — Orient to current work (dynamic)
1. Run `git branch --show-current`, `git log --oneline -15`, `git status`.
2. If a `docs/projects/` (or similar) area exists, identify the ACTIVE project from the
   branch name and read its README + the most recent handoff/status doc fully.
3. Skim recent deploy/migration notes to learn what shipped lately and any known quirks.

## Tier 3 — Map, don't read (build an index)
- List `docs/` and each subfolder; note in one line what each contains so you know where to
  look later. Do NOT read these files now.
- Glob `apps/` and `packages/` (or the repo's equivalent) so you know what exists and the
  import map.
- Note the location of any API contract (OpenAPI/schema) — load only when a shape matters.

## Then STOP and report back (concise onboarding summary)
1. **What this system does** — 3 sentences + the app/service topology.
2. **Active work** — what the current branch is doing and where it stands.
3. **Hard rules I must respect** — the non-obvious ones from CLAUDE.md/AGENTS.md, verbatim.
4. **Recent context** — what shipped lately and any quirks.
5. **Where things live** — your one-line index of docs subfolders + which apps/packages own
   what.
6. **Open questions** — anything ambiguous you'd want clarified.

Do not write or edit any code. End by asking what to work on.
