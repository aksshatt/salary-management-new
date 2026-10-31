# Salary Management — Requirements

## Goal
ACME's HR Manager manages salaries for about 10,000 employees across several countries in Excel. This app moves that work into a web app: keep salary records accurate, run monthly payroll, and answer "how do we pay people?" without spreadsheets.

## User
The HR Manager, with one login. No other roles.

## Features
1. **Login.** One HR account. Session cookie with CSRF protection. Login attempts are rate-limited. Every page and endpoint requires login.
2. **Employees.**
   - HR can add and edit an employee: name, email, country, department, job title, join date and bank account number. The employee code (e.g. `EMP-00042`) is generated automatically, so there are no typos or duplicates. Department and job title are plain text.
   - The join date can't be edited after the employee is created, because the first salary revision is dated on it.
   - Employees are never deleted. HR terminates them with a last working day, which can't fall in a locked payroll month.
   - Bank account numbers show only the last 4 digits everywhere except the payroll export.
   - The list has search by name or code, filters for country, department, job title and status, and server-side pagination. Filters live in the URL.
3. **Salary revisions.**
   - Salaries are annual amounts in the employee's local currency, greater than 0 and at most 1,000,000,000. Each revision stores the currency it was entered in, so changing an employee's country doesn't rewrite past salaries.
   - Each change is a new revision with an effective date and a reason (initial, increment, promotion, correction or other). Revisions can't be changed after saving.
   - The current salary is the latest revision effective on or before today, or on or before the last working day for someone who has left.
   - A revision can't be dated before the join date or after termination, and an employee can't have two revisions on the same date. Future-dated revisions are allowed.
   - Adding an employee requires an initial salary.
4. **Salary timeline.** The employee page shows the full revision history as a chart, with the % change at each revision.
5. **Currencies.** Each country has a currency; each currency has a rate to USD (units per 1 USD), which HR can edit. USD is fixed at 1. Insights compare in USD at the current rate. Salaries and payroll stay in local currency.
6. **Insights dashboard.**
   - Shown in USD, as of the end of any past month, or as of today for the current month.
   - Headcount, annual and monthly salary cost, and average, median, lowest and highest salary.
   - Filters for country, department and job title.
   - A donut chart of salary cost by country or department.
   - 12-month trends for salary cost and for joiners against leavers.
7. **Raise trends.** Average raise % and the number of raises per month over the last 12 months, filterable by country. Only increment and promotion revisions count.
8. **Filtered export.** Exports the employee list, with its current filters, to CSV. Includes current salary in local currency and in USD.
9. **Tax.** One flat tax rate per country, which HR can edit.
10. **Monthly payroll.**
    - A run covers one month, and each month has at most one run.
    - The first run is for the current or the previous month. Each later run must be for the month right after the latest run, and never a future month.
    - Only the latest month is open. HR can recalculate it after confirming, which keeps the bonuses, deductions and notes HR entered and adds newly eligible employees. Older months are locked.
    - The run has one entry per employee who worked at least one day that month. Pay is prorated by calendar days for joiners and leavers.
    - The salary used is the revision in effect on the employee's last day worked that month.
    - Entries store their amounts in local currency, plus the revision, tax rate and days worked they used. Viewing and exporting read the stored entries and never recalculate.
    - In the open month only, HR can enter a one-time bonus, deduction and note per entry. Negative net pay is allowed and flagged, for loan recovery.
    - An "Outdated" badge appears when a revision, termination, tax rate or employee change happened after the open month was last calculated.
    - The month's payroll exports to Excel with the full bank account numbers and a currency column.
11. **Audit trail.** Every create or update of an employee, revision, termination, exchange rate, tax rate, payroll run or payroll adjustment (bonus, deduction, note) is recorded with what changed and when. Bank account numbers are stored masked in the audit. The employee page shows that employee's changes, and an audit page lists all changes.
12. **Seed data.** 10,000 employees across 7 countries and 6 departments with realistic salaries per role, level and country, a yearly salary review history, and a mix of active, upcoming and departed employees. Uses a fixed random seed.

## Definitions
- **Status:** active if joined on or before today and not terminated before today. Upcoming if the join date is in the future. Terminated if the last working day is before today.
- **Raise %:** (new amount − previous amount) / previous amount.
- **Proration factor:** days worked in the month / calendar days in the month.
- **Payroll:**
  - Monthly gross = annual salary / 12 × proration factor.
  - Taxable = monthly gross + bonus.
  - Tax = rate × taxable.
  - Net = taxable − tax − deduction.
  - Monthly gross and tax are rounded to 2 decimal places, half up. Money is `decimal(12,2)`.

## Deliberately out of scope
| Item | Reason |
|---|---|
| Excel import | The seed covers the data needs for this exercise. Employees are added in the UI. |
| Historical exchange rates | One current rate keeps insights simple. Payroll is in local currency, so it doesn't need rates. |
| Real tax rules (brackets, exemptions) | They differ by country. A flat rate is enough to show gross against net. |
| Proration by working days | Would need a holiday calendar for each country. |
| Automatic back pay for backdated raises | Locked months stay as paid. HR adds the difference as a one-time bonus. |
| Payslips, approvals, leave | These belong to a full HR system. |
| Multiple users and roles | One HR user, as confirmed with the recruiter. |
| Deleting employees or revisions | Salary and payroll history must stay intact. |

## Known limitations
- Exchange rates have no history: editing a rate changes every USD figure, past months included.
- The "Outdated" badge can flag a change that doesn't affect the month's numbers (e.g. a name edit or a raise dated next year); recalculating is harmless then.
- A backdated raise into a locked month isn't paid automatically; HR adds the difference as a one-time bonus.
- The latest month can be recalculated even after it was paid; the confirmation step is the only safeguard until the next month exists.
- The audit trail has no "who" column, because there is one HR login.

## Technical decisions
- Rails API with Postgres. The React (Vite) frontend with Ant Design is served by the same app.
- Built test-first with RSpec and Vitest.
- Deployed on Render (Docker, free tier). There is a video walkthrough of 3 to 5 minutes.
- Architecture, data model and trade-offs: `docs/architecture.md`. Measured performance: `docs/performance.md`.
