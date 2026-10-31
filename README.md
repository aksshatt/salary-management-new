# Salary Management

A web app for ACME's HR Manager to manage salaries for ~10,000 employees across countries: employee records and salary history, pay insights in USD, monthly payroll with Excel export, and an audit trail.

- Live: _add Render URL_
- Requirements: [docs/requirements.md](docs/requirements.md) · Architecture: [docs/architecture.md](docs/architecture.md) · Performance: [docs/performance.md](docs/performance.md) · AI prompts: [docs/ai-prompts.md](docs/ai-prompts.md)

## Stack
Rails 8.1 (API) + Postgres · React (Vite) + Ant Design + @ant-design/charts · RSpec + factory_bot · Vitest + Testing Library · Docker on Render.

## Run locally
Requires Ruby 3.4.2, Node 22 and Postgres.

```bash
bin/setup --skip-server
npm --prefix frontend ci
HR_EMAIL=hr@acme.test HR_PASSWORD=choose-one bin/rails db:seed   # 10,000 employees (SEED_EMPLOYEES=500 for fewer)
bin/dev                                                          # http://localhost:5173
```

## Tests and checks
```bash
bin/ci                      # RuboCop, bundler-audit, Brakeman, RSpec, frontend lint/tests/build
bundle exec rspec           # backend
npm --prefix frontend test  # frontend
```

## How it was built
Test-first (red → green per behaviour), small PRs with test/feat commit pairs, CI on every PR. See the AI prompt log for how AI tools were used.
