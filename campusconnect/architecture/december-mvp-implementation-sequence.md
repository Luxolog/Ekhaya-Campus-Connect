# CampusConnect December MVP — implementation sequence

**Branch:** `campusconnect-december-mvp`  
**Planning baseline:** `main` at `30626abd701d3bcd0c1626ae766cd016e33720f2`  
**Delivery target:** 31 December 2026  
**First checkpoint:** 30 November 2026  
**Status:** Working delivery plan; not a production deployment or a claim that listed modules are implemented.

## 1. Release definition

The December release is a tested first operational version of the agreed CampusConnect platform. It is not the completion of every advanced feature in the long-term architecture.

A module is not "done" because a page exists. It is done only when its primary user workflow, permissions, failure states and acceptance tests work.

## 2. Critical path — do these in order

### Track A — Database baseline and security (P0)

1. Recover the original source for the two migration versions present in the live migration ledger but absent from the inspected repository refs:
   - `20261115120143_auth_profile_bootstrap_and_consent_controls`
   - `20261115120200_consolidate_consent_read_policy`
2. If original source cannot be recovered, document the provenance gap and prepare a reviewed forward baseline from verified live catalog state. Never fabricate historical migration SQL.
3. Reconcile migration history without manually inserting ledger rows or blindly replaying already-applied migrations.
4. Confirm object owners and effective grants, including default privileges for every owner that creates public objects.
5. Review tenant-safe relational constraints, especially `applications(college_id, course_id)` against the selected course's college.
6. Decide and implement (first in non-production) trusted audit append and controlled application status transitions.
7. Execute the existing `security-and-grant-validation-test-plan.md` in a disposable non-production environment using synthetic identities for at least two colleges.
8. Only prepare production changes after evidence, peer review and explicit product-owner approval.

**Exit gate:** reproducible baseline; approved privilege matrix; passing cross-tenant allow/deny tests; no privileged secret in client code.

### Track B — Student and college onboarding (P1)

1. Verify Supabase Auth site URL and redirect allow-list in a controlled environment.
2. End-to-end test student signup, email verification, sign-in, password recovery, profile read/update and sign-out.
3. Port the college registration request form into the current `main` experience, based on the reviewed PR #3 migration contract.
4. Validate all inputs client-side and server/database-side; show clear success/failure states; add a privacy notice and abuse/rate-limit protection.
5. Keep public college requests private and INSERT-only. Do not expose request rows or reviewer fields to anonymous users.
6. Build a controlled review/provisioning path for authorised platform reviewers; no public self-approval or self-assigned college roles.

**Exit gate:** synthetic student can complete account lifecycle; prospective college can submit a request; only authorised reviewer can process it; no client can assign privileged roles.

### Track C — First end-to-end college workflow (P2)

1. Approved college administrator can access only their tenant.
2. College can maintain its own profile and course catalogue.
3. Student can discover published courses.
4. Student can grant purpose-specific consent and submit an application to the selected college.
5. Student can see only their own application and status.
6. Assigned college staff can see and process only applications for their college.
7. Application transitions are validated and produce trusted audit events.
8. Course/application relationship cannot cross college boundaries.

**Exit gate:** the full college-to-student application journey passes using two colleges and two students, including negative cross-tenant tests.

## 3. Remaining MVP modules — controlled scope

These modules should use simple, auditable workflows and directory/referral patterns where full integrations are unavailable.

| Module | December MVP scope | Defer from first release |
|---|---|---|
| Learning Management | Course spaces, learning resources, basic learner access and progress record | Complex assessments, proctoring, advanced analytics and video infrastructure |
| Jobs | Opportunity listings, filters, student applications/referral links | Employer ATS integrations unless an approved API is available |
| Holiday Jobs | Dedicated Jobs section/category with clear seasonal tagging and closing dates | Automated employer payroll or placement systems |
| Work Experience | Separate listings for internships, apprenticeships, learnerships, WIL and job shadowing | Automated placement contracts and external HR integrations |
| Funding | Bursary, sponsorship and loan information with eligibility details and official application/referral links | Credit scoring, underwriting, loan origination or debt collection |
| Wellness | Referral directory and sponsored counselling referral workflow with minimal data | Storing diagnoses, clinical notes or therapy records |
| Bookshops and study materials | College booklists, prescribed textbooks, matric rewrite/ASC books, study guides and past papers; direct links to bookshops | CampusConnect stock, checkout or payments |
| Partner Network | Provider/service directory and integration catalogue for seller/student support partners | Consumer marketplace or unapproved deep integrations |

## 4. December delivery gates

| Gate | Target | Required evidence |
|---|---|---|
| Foundation review | 22 Nov | Migration provenance decision, verified baseline plan, privilege/tenant design |
| Student and college onboarding | 29 Nov | Auth lifecycle tests and college request submission/review tests |
| Core college workflow | 6 Dec | Tenant-scoped college/course/application workflow passes |
| Opportunities and learning essentials | 13 Dec | Jobs, Holiday Jobs, Work Experience and LMS smoke tests |
| Student services and partner directory | 17 Dec | Funding, wellness, bookshop and partner directory smoke tests |
| Feature freeze | 20 Dec | Agreed MVP scope implemented; no new features without release-owner decision |
| Release verification | 21–31 Dec | Security, functional, responsive, regression and operational checks signed off |

Dates are targets, not evidence of completion. Reforecast immediately if a gate fails.

## 5. Test and release evidence required

- Exact repository commit and migration head tested.
- Non-production project reference and synthetic fixture inventory.
- Auth lifecycle test results.
- Positive and negative role/tenant tests for students, college staff and platform reviewers.
- Consent, application-state and audit-integrity tests.
- Browser/device responsive checks.
- Error handling, empty states and validation checks.
- Backup/restore and operational recovery notes for the selected host.
- Open defect list with severity, owner and disposition.
- Product-owner and technical/security sign-off.

## 6. Hosting independence

Development, code review, database design, automated tests and local browser testing can proceed without Vercel. A complete real-world pilot still requires a deployed non-production environment on an agreed host, with correct Auth redirects, TLS, secrets and observability. Vercel itself is not a prerequisite; a tested hosting target is.

## 7. Non-negotiable guardrails

- Continue from the current repository and architecture; no replacement project or broad rewrite.
- No TinyFish/browser automation dependency.
- No production schema, RLS, grants, default privileges, Auth settings, storage, users or student data changes without explicit approval.
- No real student personal data in demos or test fixtures.
- No claims of feature completion without a working workflow and retained test evidence.
- External integrations requiring partner credentials, APIs or written authorisation must have a safe manual/referral fallback for the first release.

## 8. Current starting position

The inspected live project baseline had nine public tables, all with RLS enabled and zero rows at inspection time. The existing repository README explicitly describes the course finder, application submission, college workspace and administration as demonstration-only/localStorage flows; the student account page is the only described Supabase-connected browser flow. The next implementation work must convert those demo workflows into authenticated, tenant-scoped operations without bypassing the security gates above.
