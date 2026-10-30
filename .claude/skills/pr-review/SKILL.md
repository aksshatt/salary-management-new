---
name: pr-review
description: Strict pre-merge review of a GitHub PR. Use ONLY when the user explicitly asks ("review PR" for the current branch, or "review PR 3"). Reports findings only; never fixes, merges or comments on GitHub.
---

# PR Review

Act as a strict senior reviewer. Only report issues worth my time.

## Setup
1. `git status` must be clean, otherwise stop.
2. Remember the current branch.
3. `git fetch origin`. With a number: `gh pr checkout <n>`. Without: use the current branch's PR.
4. Compare against `origin/main`: `git log origin/main..HEAD` and `git diff origin/main...HEAD`.
5. Re-read `docs/requirements.md` and `CLAUDE.md`.

## Check (only areas the diff touches)
1. **Scope:** matches the requirements; nothing extra or missing; no broken domain rule (revision changed, locked month written, unmasked bank number, missing audit entry).
2. **Logic:** payroll, proration, tax, rounding, currency conversion and raise % against the formulas. Try edge cases: month end, leap-year February, first or last day joins and leaves, negative net, first run, recalculation.
3. **Tests:** every `feat`/`fix` has behaviour-focused, deterministic specs with edge cases. Run `verify`.
4. **Database:** reversible migrations, `NOT NULL`, foreign keys, unique indexes, indexed filter columns, `decimal` money.
5. **Performance:** no N+1, no loading all 10k rows into memory, server-side pagination, aggregates in SQL.
6. **Security:** auth on every endpoint, strong params, CSRF, rate limit on login, no secrets in code, masked bank numbers, safe CSV output (no formula injection).
7. **Readability:** clear names, thin controllers, no dead code, no premature abstraction.

## Report
- Group by severity: **Must fix**, **Should fix**, **Nit**.
- Each item: `file:line`, the problem, why it matters, a suggested fix.
- End with a verdict: ready to merge or not.
- Switch back to the original branch.
