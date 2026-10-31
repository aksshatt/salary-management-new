# AI Prompts Log

This document records the prompts used with Claude Code while planning
and building the Salary Management project.

## Summary

-   **Tool:** Claude Code
-   **Project:** Salary Management System
-   **Tech Stack:** Ruby on Rails, PostgreSQL, React, Ant Design
-   **Deployment:** Render
-   **Development Approach:** Requirements-first development with
    structured implementation, verification, migration, and PR
    workflows.
-   **Project Setup:** `CLAUDE.md`, `docs/requirements.md`, and reusable
    development skills for build, verification, migrations, PRs, and PR
    reviews.

## Prompt History

  ----------------------------------------------------------------------------------
  \#             Prompt             Actions Taken           Result
  -------------- ------------------ ----------------------- ------------------------
  **1**          Create a new       Initialized the project Initial project
                 Salary Management  structure and defined   structure and workflow
                 project and define the basic development   established.
                 the initial        approach, coding        
                 development        workflow, and project   
                 workflow.          conventions.            

  **2**          Add a rule to      Added requirements to   Verification became a
                 verify and test    run related tests, full required part of the
                 code after making  test suites, linters,   development workflow.
                 changes.           and verify behaviour in 
                                    the running application 
                                    after changes.          

  **3**          Create `CLAUDE.md` Added project           `CLAUDE.md` created as
                 for the project.   instructions, coding    the primary AI
                                    conventions, workflow   development guide.
                                    rules, and verification 
                                    expectations.           

  **4**          Create supporting  Added the documentation Base documentation and
                 project            structure and initial   reusable workflows
                 documentation and  `build`, `pr`, and      created.
                 reusable           `pr-review` skills.     
                 development                                
                 skills.                                    

  **5**          Suggest additional Reviewed the existing   Verification and
                 skills that would  workflow and added      migration workflows
                 improve the        `verify` and            added.
                 development        `migration` skills.     
                 workflow.          Also identified         
                                    possible future         
                                    workflows for seed      
                                    data, deployment,       
                                    payroll edge cases, and 
                                    frontend development.   

  **6**          Integrate the new  Connected migration     Development workflow
                 skills into the    checks with             became more structured
                 main development   implementation planning and reusable.
                 workflow.          and verification checks 
                                    with development and    
                                    commit steps.           

  **7**          Define a clean and Established a           AI usage could be
                 step-wise approach consistent format for   documented consistently
                 for documenting    recording prompts,      throughout development.
                 AI-assisted        actions, results, and   
                 development.       developer decisions.    

  **8**          Review the         Analyzed the assessment Initial implementation
                 assessment         scope, identified       strategy prepared.
                 requirements and   important product       
                 suggest the best   decisions, and broke    
                 implementation     the project into        
                 approach.          functional and          
                                    technical areas.        

  **9**          Define a           Defined development     Project workflow aligned
                 project-specific   rules around employees, with the Salary
                 workflow for the   salary records,         Management domain.
                 Salary Management  payroll, currencies,    
                 System.            reporting, testing, and 
                                    frontend development.   

  **10**         Help decide the    Evaluated employee      Core product direction
                 product scope and  management, salary      established.
                 suggest useful     history,                
                 core features.     authentication,         
                                    reporting, exports,     
                                    payroll, tax, audit     
                                    history, and dashboard  
                                    features.               

  **11**         Create the first   Defined the project     Initial
                 version of the     goal, intended users,   `docs/requirements.md`
                 project            core features,          created.
                 requirements.      technical decisions,    
                                    salary rules, and       
                                    initial out-of-scope    
                                    items.                  

  **12**         Review an expanded Evaluated feature       Feature scope refined
                 feature list       value, complexity,      before implementation.
                 including payroll, overlap, and assessment 
                 tax, reporting,    scope. Identified       
                 and data import.   features that should be 
                                    included or excluded.   

  **13**         Finalize the       Finalized requirements  Final project
                 feature scope with for employee            requirements
                 employee           add/edit/termination,   established.
                 management, salary salary timeline, raise  
                 history, payroll,  trends, local currency  
                 tax, exports,      with USD view, filtered 
                 audit trail, and   CSV exports, payroll,   
                 reporting.         tax, audit history,     
                                    authentication,         
                                    dashboard insights, and 
                                    masked bank details.    

  **14**         Finalize the       Completed domain rules, Project setup became
                 development setup  frontend guidelines,    implementation-ready.
                 before starting    build workflow,         
                 implementation.    verification rules,     
                                    migration checks, CSV   
                                    safety rules, currency  
                                    handling, and audit     
                                    requirements.           

  **15**         Configure Git for  Configured              Initial project setup
                 the project and    repository-level Git    committed successfully.
                 create the initial identity and committed  
                 commit.            the initial project     
                                    documentation and       
                                    development             
                                    configuration.          

  **16**         Simplify the AI    Removed unnecessary     AI documentation process
                 logging workflow.  automatic logging       simplified.
                                    behaviour and kept AI   
                                    prompt documentation as 
                                    a manually maintained   
                                    project document.       
  ----------------------------------------------------------------------------------

## Key Product Decisions

  ---------------------------------------------------------------------
  Area                               Decision
  ---------------------------------- ----------------------------------
  **Backend**                        Ruby on Rails

  **Database**                       PostgreSQL

  **Frontend**                       React + Ant Design

  **Deployment**                     Render

  **Currency**                       Store salaries in local currency
                                     with an optional USD view

  **Employees**                      Add, edit, view, and terminate
                                     employees

  **Salary History**                 Maintain salary revision history
                                     and timeline

  **Dashboard**                      Monthly insights, trends, and
                                     salary distribution

  **Payroll**                        Payroll calculations based on
                                     employee salary data

  **Tax**                            Include tax-related payroll
                                     calculations

  **Exports**                        Filtered CSV exports

  **Security**                       Authentication, CSRF protection,
                                     and rate limiting

  **Sensitive Data**                 Mask bank account information

  **Auditability**                   Maintain audit history for
                                     important employee and salary
                                     changes

  **Testing**                        Verify related tests, full suite,
                                     linting, and application behaviour
                                     after changes
  ---------------------------------------------------------------------

## AI Development Approach

Claude Code was used throughout the project for:

-   Requirements analysis and feature planning.
-   Project architecture and development workflow.
-   Implementation planning.
-   Code generation and refactoring.
-   Database migration planning.
-   Testing and verification.
-   Debugging.
-   Pull request preparation and review.
-   Documentation.

All generated changes were intended to be reviewed and verified before
being considered complete.

## 16. Start: GitHub repo and app setup

**Prompt:** Logged in to GitHub as the candidate; start.

**Steps:** 1. Confirmed the GitHub login and checked the toolchain (Ruby
3.2.2, Rails 8.1.4, Node 20, Postgres 14, Docker). 2. Found that the
account already has a public `salary-management` repo with earlier work;
stopped before creating or pushing anything. 3. Drafted the app setup
plan for approval.

**Result:** Nothing pushed or scaffolded. Waiting for a repo decision
and plan approval.

**What I changed or rejected:** Pending.

## 17. Enforce strict TDD and development standards

**Prompt:** Follow strict Test-Driven Development for all implementation
work. Write a failing test first, implement the minimum code required to
make it pass, then refactor while keeping the suite green. Follow the
project conventions and quality standards defined in `CLAUDE.md` and the
reusable development skills.

**Steps:** 1. Used the Red → Green → Refactor cycle for backend,
frontend, services, APIs, models, and business logic. 2. Added tests for
expected behaviour, validations, failure cases, authorization, boundary
conditions, and important business rules. 3. Kept test and
implementation changes clearly separated where practical. 4. Followed
Rails, React, database, security, migration, and project-specific coding
conventions. 5. Avoided considering a feature complete until its tests
passed.

**Result:** TDD became the standard implementation approach across the
project, with automated tests accompanying the major application
features.

**What I changed or rejected:** Rejected implementation-first
development followed by tests written only for coverage.

## 18. Apply TDD to critical business and security flows

**Prompt:** Continue the same TDD workflow for the critical Salary
Management features, with additional attention to financial correctness,
data integrity, security, and edge cases.

**Steps:** 1. Covered employee creation, editing, termination, salary
revisions, and salary history. 2. Tested payroll generation,
recalculation, adjustments, locked payroll months, tax calculations, and
financial rounding. 3. Tested exchange rates, USD salary conversion,
reporting, dashboard calculations, CSV/Excel exports, and audit history.
4. Verified authentication, sessions, CSRF handling, rate limiting,
authorization, and masking of sensitive bank information. 5. Added
regression tests for bugs and edge cases before or alongside their
fixes. 6. Kept database constraints, migrations, API behaviour, frontend
behaviour, and business rules consistent with project requirements.

**Result:** Critical financial, employee, reporting, and security
workflows were protected by automated tests and regression coverage.

**What I changed or rejected:** Avoided weakening business rules or
existing tests simply to make a new implementation pass.

## 19. Run complete quality and verification checks

**Prompt:** Before considering a feature or pull request complete, run
the required verification workflow and ensure the implementation meets
the project's testing and quality standards.

**Steps:** 1. Ran focused tests during each Red → Green cycle. 2. Ran
the complete backend and frontend test suites after implementation. 3.
Ran linting, static checks, and production build checks. 4. Verified
database migrations and schema consistency. 5. Reviewed failures and
fixed the underlying implementation instead of bypassing tests. 6.
Manually verified important user workflows in the running application
where automated tests alone were insufficient. 7. Checked for
regressions, security issues, sensitive-data exposure, debug code, and
accidental secrets.

**Result:** Features were considered complete only after automated
tests, quality checks, and relevant application-level verification
passed.

**What I changed or rejected:** A passing isolated test was not treated
as sufficient if the full verification workflow exposed regressions or
standards violations.

## 20. Final code and test review

**Prompt:** Perform a final review of the implementation and test suite
against the project requirements, TDD rules, and engineering standards
before deployment.

**Steps:** 1. Reviewed whether important requirements had meaningful
automated coverage. 2. Checked tests for false positives, weak
assertions, duplication, and missing edge cases. 3. Reviewed financial
calculations, employee lifecycle rules, exports, authentication,
auditability, and sensitive-data handling. 4. Confirmed the complete
test suite and required quality checks remained green. 5. Verified
deployment configuration and production readiness.

**Result:** The application received a final requirements, test-quality,
code-quality, and deployment-readiness review.

**What I changed or rejected:** Did not use test count or coverage
percentage alone as proof of quality; tests had to validate meaningful
application behaviour.
