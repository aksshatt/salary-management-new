# Performance notes

Measured locally on the full seed: 10,000 employees, 39,779 salary revisions, 7 countries
(development server, Postgres 14, median of 5 requests, logged in).

| Request | Time |
|---|---|
| Seed (`bin/rails db:seed`, 10k employees + revisions via `insert_all`) | 5.0 s |
| `GET /api/employees` (page 1, with current salary + USD) | 18 ms |
| `GET /api/employees?page=200` (last page) | 31 ms |
| `GET /api/employees?q=nair` (name/code search, `ILIKE`) | 18 ms |
| `GET /api/employees?country_id=1&department=Sales&status=active` | 11 ms |
| `GET /api/insights` (stats + donut, all employees) | 39 ms |
| `GET /api/insights?group_by=department&department=Engineering` | 11 ms |
| `GET /api/insights/trends` (12 months, incl. raises) | ~570 ms (360 ms before raise trends) |
| `GET /api/filter_options` | 7 ms |
| `GET /api/employees/export.csv` (all 10,000 rows, 1.45 MB) | 1.1 s |

## What keeps it fast
- Pagination and filtering in SQL; every list and dashboard request runs a fixed number of queries (tested with 3 vs 30 employees).
- Current salary per employee comes from one `LEFT JOIN LATERAL` using the unique index on `salary_revisions (employee_id, effective_on)`, read backwards to get the latest revision on or before a date.
- Aggregates (sum, average, median, min, max, group by) run in Postgres in `numeric`; nothing loads 10k rows into Ruby.
- Filter and sort columns on `employees` are indexed.

## Trends
`EXPLAIN ANALYZE`: each of the 12 months aggregates ~7,600 active employees, each doing one backward index scan for the salary in effect (~91,700 index lookups at ~0.001 ms) — about 15 ms per month, plus ~2.5 ms per month for joiners/leavers. The time is the amount of work, not a missing index. Fine for a dashboard chart at this size; if it grew 10x, the next step would be a monthly snapshot table.

## Raise trends
Raise % needs each revision's previous one, so `LAG` runs over all ~40k revisions once (a materialized CTE limited to raises in the 12-month window); each month then reads only its own raises. First version recomputed the window inside every month's lateral join: 824 ms; the CTE brought it to ~570 ms. Measured uncached with `ActiveRecord::Base.uncached` — the query cache made a first timing look like 1 ms.

## Not done (yet)
- No trigram index for search: a full `ILIKE` scan over 10k names takes a few ms.
- Frontend: pages and charts are lazy-loaded chunks (main entry ~98 kB before compression); the charts library (~1.4 MB) loads only on pages with charts.
