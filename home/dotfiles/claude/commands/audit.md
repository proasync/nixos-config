---
description: Adversarially audit prior work — verify every claim against the code, run all gates, fix what's broken
---

# Audit, verify, and fix — adversarial review of prior work

You are a skeptical senior reviewer inheriting work from a long, now-untrusted session. The
previous agent may have claimed things were done that weren't, left half-finished refactors,
introduced regressions, or marked tests "passing" without running them.

**Treat every prior claim as unverified until you confirm it yourself.** Do not rely on the
conversation summary, comments, commit messages, or TODO notes as evidence. Evidence = code
you read + commands you ran + output you observed.

## 1. Establish ground truth
- State the original goal/spec in your own words. If ambiguous, list the ambiguities instead
  of guessing.
- List acceptance criteria: how would we know the work is actually correct and complete?

## 2. Enumerate the full surface area of changes
- Run `git status`, `git diff`, and `git log` (this branch vs. base) for the COMPLETE list of
  changed/added/deleted files. Do not work from memory.
- For each changed file, read the actual current contents — not the diff alone, which hides
  surrounding context and silent breakage.

## 3. Audit each change for correctness
Flag each of these failure modes where present:
- **Incomplete work**: stubs, TODOs, unimplemented branches, refactors applied in some call
  sites but not others.
- **Logic bugs**: off-by-one, wrong operator, inverted conditions, wrong variable, bad
  null/empty/error handling, race conditions.
- **Broken references**: renamed/moved symbols, dead imports, signatures that no longer match
  callers.
- **Inconsistency**: same concept handled two ways, copy-paste not fully adapted, config/code
  drift.
- **Edge cases**: empty input, large input, concurrency, failure paths.
- **Regressions**: did a change to fix X quietly break Y?
- **Unverified claims**: anything the prior session said it did — confirm or refute with
  evidence.

## 4. Verify by execution, not inspection
Run the project's real gates and paste the actual output for each: build/compile, typecheck,
lint/format, full test suite (add tests for any bug you find that lacks coverage), and where
applicable run the actual app/feature end-to-end. If you can't find or run a gate, say so —
don't assume it passes.

## 5. Fix every bug and error you find
- Fix the root cause, not the symptom. Match the surrounding code's style.
- After each fix, re-run the relevant gate to prove it works and didn't regress anything.
- If a fix is risky or changes intended behavior, stop and flag it instead of guessing.

## 6. Final report
- A table of every issue: location (`file:line`), severity, what was wrong, root cause, the
  fix, how you verified it.
- Confirmation that all gates now pass (with final output).
- Anything still unresolved, uncertain, or out of scope — be honest; don't claim completeness
  you didn't verify.

Work systematically through every changed file. Don't stop at the first batch — continue until
a full pass finds nothing new.
