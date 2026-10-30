---
name: pr
description: Push the current branch and create or update its GitHub PR against main. Use ONLY when the user explicitly says "create PR" or "update PR" or runs /pr. Never on your own initiative.
---

# PR

## 1. Preconditions (stop and report if any fail)
- Not on `main`.
- `git status` is clean.
- The `verify` skill passes.

## 2. Push
`git push -u origin <branch>`

## 3. Write the PR
- `git fetch origin`, then read `git log origin/main..HEAD` and, where needed, `git diff origin/main...HEAD`.
- Check for an existing PR with `gh pr view --json number,title,body`.
- Title: conventional style, `type(scope): short message`.
- Body:
  - **What:** the behaviour added or changed, from HR's point of view.
  - **Why:** link to the relevant section of `docs/requirements.md`.
  - **How:** key design decisions and trade-offs.
  - **Tests:** what's covered, including edge cases.
  - **Notes:** anything left out or follow-ups.
- Show me the title and body before creating or editing the PR.

## 4. Create or update
- New: `gh pr create --base main --title ... --body ...`
- Existing: `gh pr edit <n> --title ... --body ...`
- Give me the PR link. Never merge.
