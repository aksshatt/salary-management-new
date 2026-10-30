# CLAUDE.md

## Project
Salary management web app for ACME's HR Manager: about 10,000 employees in multiple countries, replacing Excel.
- Scope and business rules live in `docs/requirements.md` (to be written). Read it before feature work.
- Anything not in it needs my ok first.

## How we work together
- Challenge me when something is wrong, too complex or out of scope, and say why.
- Back claims with evidence: read the code or docs, or run it. Don't make up versions, APIs or options.
- Say "I don't know" rather than guess. Ask when unclear; make small obvious calls and tell me.
- Smallest solution that works. No speculative features or abstractions.

## Workflow
- Code changes follow the `build` skill; schema changes follow the `migration` skill.
- Test-first: failing test, minimal code, refactor.
- Show a plan before anything non-trivial. Work in small steps.
- After each change, run the `verify` skill and report the real results, failures included.

## Testing
- Backend: RSpec + factory_bot. Unit specs for models and services, a few request specs for the API.
- Deterministic only: fixed values in assertions, frozen time for dates, seeded randomness in `db/seeds.rb`. No network, no `sleep`.
- Frontend: Vitest. Keep logic in plain JS functions tested without a DOM; use Testing Library only for stateful component behaviour.

## Backend conventions
- Thin controllers; business logic in `app/services`, reporting queries in `app/queries`.
- Money is `decimal(12,2)` / `BigDecimal`, never float.
- Validations are backed by DB constraints (`NOT NULL`, foreign keys, unique indexes).
- Index foreign keys and filter columns. No N+1. Paginate on the server.

## Domain rules (details in docs/requirements.md)
- Salary revisions can't be changed after saving. Employees are never deleted, only terminated.
- Salaries and payroll are in local currency; insights convert to USD at the current rate.
- Payroll entries are the only stored payroll. View and export read them and never recalculate.
- Only the latest payroll month is open; older months are read-only.
- Bank account numbers show the last 4 digits everywhere except the payroll export.
- Every create or update of audited records writes an audit entry.

## Frontend
- React + Vite in plain JavaScript, Ant Design, `react-router`, `@ant-design/charts` (chart pages loaded with `lazy()`). Ask before adding other packages.
- Filters and pagination live in the URL. No business calculations in the UI; the API does all the math.

## Commands
- Requires Ruby 3.4.2 and Node 22 (`frontend/.nvmrc`).
- Setup: `bin/setup --skip-server` and `npm --prefix frontend ci`
- Run: `bin/dev` (Rails on :3000, Vite on :5173 proxying `/api`)
- Backend tests: `bundle exec rspec`. Frontend tests: `npm --prefix frontend test`
- Lint: `bin/rubocop` and `npm --prefix frontend run lint`
- All checks (RuboCop, bundler-audit, Brakeman, RSpec, frontend lint/tests/build): `bin/ci`
- Production image: `docker build .` (builds the frontend into `public/`)

## Git
- Conventional Commits, one line: `type(scope): message` (`feat`, `fix`, `test`, `refactor`, `docs`, `chore`, `ci`, `build`). No trailers.
- One branch per piece of work; no direct commits to `main` after the initial commit.
- Merge PRs with a merge commit so history stays visible.
- Commit only with my approval. Push or open PRs only when I ask (`pr` skill). Never merge.
- Tests pass before every commit, except a `test:` commit whose failing specs the next `feat:`/`fix:` commit fixes.

## Don'ts
- No new gems or npm packages without asking.
- Never edit or commit `.env`, `.private/` or any keys.
