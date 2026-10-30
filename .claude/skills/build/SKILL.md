---
name: build
description: Required workflow for every code change in this repo (feature, fix, refactor, migration, spec or setup). Use it before writing or editing code, even for small changes and even if the user doesn't mention it.
---

# Build

Goal: each step is small, correct and proven by tests, so I don't have to re-check it.

## 1. Read
- Read the parts of `docs/requirements.md` and `CLAUDE.md` this change touches.
- Gaps or contradictions in the requirements: stop and ask. Payroll and money mistakes are expensive.
- Setup and infra work isn't in the requirements; plan it from CLAUDE.md and get my ok.

## 2. Reuse
Search for existing models, services, scopes, factories and components before writing new ones. Extract shared code only when there's a second real caller.

## 3. Plan, then wait
Short plan covering:
- models, services, endpoints and screens touched
- existing code reused
- migrations (use the `migration` skill)
- edge-case specs you'll write
- anything needed that I didn't ask for (flag it, don't build it)

No code until I say ok.

## 4. Branch
Clean `git status`, then `git fetch origin` and `git switch -c <type>/<short-name> --no-track origin/main` (type matches the commit type). Stay on the current branch if it already fits.

## 5. Test-first, one behaviour at a time
Strict red-green-refactor. Repeat this cycle for each behaviour:
1. Write ONE failing spec for ONE behaviour. Never write a whole layer's specs up front.
2. Run it and show it fails for the right reason (wrong value or missing method, not a load error).
3. Write only enough code to make that spec pass. Nothing for the next behaviour yet.
4. Run it green, refactor, then move to the next behaviour.

When the piece is done, run the `verify` skill.

No code without a failing test first. That includes UI components, hooks and seeds. Generators are allowed only for empty scaffolding (e.g. an empty migration); any logic they add must be removed and rebuilt test-first. If a spec has to change after the code passes, say so and why.

Cover edge cases that apply: month end, leap-year February, joining or leaving on the 1st or the last day, negative net, locked months, currency conversion, nil or empty data.

## 6. Commit
- Pairs per meaningful piece: `test:` with the failing specs, then `feat:`/`fix:` that makes them pass.
- Before committing, run `verify` and show me its report, the diff and a one-line conventional message with no trailer.
- Commit only after my ok.

## 7. Finish
- Update CLAUDE.md commands or docs if they changed.
- Tell me it's ready for "create PR".

## Rules
- Build only what was asked. Tell me about anything else.
- No new gems or packages without asking.
- If a test is hard to write, say so. Don't skip it or weaken it.
