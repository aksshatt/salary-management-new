# AI Prompts Log

This document records the prompts used with Claude Code while planning and building the Salary Management project.

## Summary

- **Tool:** Claude Code
- **Project:** Salary Management System
- **Tech Stack:** Ruby on Rails, PostgreSQL, React, Ant Design
- **Deployment:** Render
- **Development Approach:** Requirements-first development with structured implementation, verification, migration, and PR workflows.
- **Project Setup:** `CLAUDE.md`, `docs/requirements.md`, and reusable development skills for build, verification, migrations, PRs, and PR reviews.

## Prompt History

| # | Prompt | Actions Taken | Result |
|---|---|---|---|
| **1** | Create a new Salary Management project and define the initial development workflow. | Initialized the project structure and defined the basic development approach, coding workflow, and project conventions. | Initial project structure and workflow established. |
| **2** | Add a rule to verify and test code after making changes. | Added requirements to run related tests, full test suites, linters, and verify behaviour in the running application after changes. | Verification became a required part of the development workflow. |
| **3** | Create `CLAUDE.md` for the project. | Added project instructions, coding conventions, workflow rules, and verification expectations. | `CLAUDE.md` created as the primary AI development guide. |
| **4** | Create supporting project documentation and reusable development skills. | Added the documentation structure and initial `build`, `pr`, and `pr-review` skills. | Base documentation and reusable workflows created. |
| **5** | Suggest additional skills that would improve the development workflow. | Reviewed the existing workflow and added `verify` and `migration` skills. Also identified possible future workflows for seed data, deployment, payroll edge cases, and frontend development. | Verification and migration workflows added. |
| **6** | Integrate the new skills into the main development workflow. | Connected migration checks with implementation planning and verification checks with development and commit steps. | Development workflow became more structured and reusable. |
| **7** | Define a clean and step-wise approach for documenting AI-assisted development. | Established a consistent format for recording prompts, actions, results, and developer decisions. | AI usage could be documented consistently throughout development. |
| **8** | Review the assessment requirements and suggest the best implementation approach. | Analyzed the assessment scope, identified important product decisions, and broke the project into functional and technical areas. | Initial implementation strategy prepared. |
| **9** | Define a project-specific workflow for the Salary Management System. | Defined development rules around employees, salary records, payroll, currencies, reporting, testing, and frontend development. | Project workflow aligned with the Salary Management domain. |
| **10** | Help decide the product scope and suggest useful core features. | Evaluated employee management, salary history, authentication, reporting, exports, payroll, tax, audit history, and dashboard features. | Core product direction established. |
| **11** | Create the first version of the project requirements. | Defined the project goal, intended users, core features, technical decisions, salary rules, and initial out-of-scope items. | Initial `docs/requirements.md` created. |
| **12** | Review an expanded feature list including payroll, tax, reporting, and data import. | Evaluated feature value, complexity, overlap, and assessment scope. Identified features that should be included or excluded. | Feature scope refined before implementation. |
| **13** | Finalize the feature scope with employee management, salary history, payroll, tax, exports, audit trail, and reporting. | Finalized requirements for employee add/edit/termination, salary timeline, raise trends, local currency with USD view, filtered CSV exports, payroll, tax, audit history, authentication, dashboard insights, and masked bank details. | Final project requirements established. |
| **14** | Finalize the development setup before starting implementation. | Completed domain rules, frontend guidelines, build workflow, verification rules, migration checks, CSV safety rules, currency handling, and audit requirements. | Project setup became implementation-ready. |
| **15** | Configure Git for the project and create the initial commit. | Configured repository-level Git identity and committed the initial project documentation and development configuration. | Initial project setup committed successfully. |
| **16** | Simplify the AI logging workflow. | Removed unnecessary automatic logging behaviour and kept AI prompt documentation as a manually maintained project document. | AI documentation process simplified. |

## Key Product Decisions

| Area | Decision |
|---|---|
| **Backend** | Ruby on Rails |
| **Database** | PostgreSQL |
| **Frontend** | React + Ant Design |
| **Deployment** | Render |
| **Currency** | Store salaries in local currency with an optional USD view |
| **Employees** | Add, edit, view, and terminate employees |
| **Salary History** | Maintain salary revision history and timeline |
| **Dashboard** | Monthly insights, trends, and salary distribution |
| **Payroll** | Payroll calculations based on employee salary data |
| **Tax** | Include tax-related payroll calculations |
| **Exports** | Filtered CSV exports |
| **Security** | Authentication, CSRF protection, and rate limiting |
| **Sensitive Data** | Mask bank account information |
| **Auditability** | Maintain audit history for important employee and salary changes |
| **Testing** | Verify related tests, full suite, linting, and application behaviour after changes |

## AI Development Approach

Claude Code was used throughout the project for:

- Requirements analysis and feature planning.
- Project architecture and development workflow.
- Implementation planning.
- Code generation and refactoring.
- Database migration planning.
- Testing and verification.
- Debugging.
- Pull request preparation and review.
- Documentation.

All generated changes were intended to be reviewed and verified before being considered complete.
## 16. Start: GitHub repo and app setup
**Prompt:** Logged in to GitHub as the candidate; start.

**Steps:**
1. Confirmed the GitHub login and checked the toolchain (Ruby 3.2.2, Rails 8.1.4, Node 20, Postgres 14, Docker).
2. Found that the account already has a public `salary-management` repo with earlier work; stopped before creating or pushing anything.
3. Drafted the app setup plan for approval.

**Result:** Nothing pushed or scaffolded. Waiting for a repo decision and plan approval.

**What I changed or rejected:** Pending.
