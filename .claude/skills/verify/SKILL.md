---
name: verify
description: Verify a change actually works before calling it done. Use after every code change (the build skill's TDD step, a fix, a refactor), before asking for commit approval, or when the user says "verify" or "check it". Runs specs, linters and security checks, and checks behaviour in the running app when the change touches the UI or API.
---

# Verify

Never say "done" or "works" without evidence from this run. Report what you ran and what it printed.

## 1. Focused specs
- Run the specs for the files you touched first (`bundle exec rspec spec/path_spec.rb`, `npm --prefix frontend test -- <file>`).
- If none exist for the changed behaviour, stop and tell me. Don't call untested code verified.

## 2. Full checks
- Backend: `bin/ci` (RuboCop, bundler-audit, Brakeman, RSpec).
- Frontend: `npm --prefix frontend test` and `npm --prefix frontend run lint`.
- If a command doesn't exist yet, say so and skip it. Don't invent a replacement.

## 3. Behaviour
Only when the change touches the API or UI:
- API: start the app and hit the endpoint with `curl` (log in first). Check the status code and the JSON shape, including that bank account numbers are masked.
- UI: open the page, try the main path and one edge case, and check the browser console for errors.
- Payroll or salary math: compare one real result against the formulas in `docs/requirements.md` by hand.

## 4. Report
- A short table: check, command, pass/fail.
- Quote failures exactly. Never hide, skip or weaken a failing spec to get green.
- List anything you couldn't verify and why.
