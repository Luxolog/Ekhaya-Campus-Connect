# CampusConnect December MVP — implementation sequence

**Branch:** `campusconnect-december-mvp`  
**Planning baseline:** `main` at `30626abd701d3bcd0c1626ae766cd016e33720f2`  
**Build standard:** launch-ready engineering from day one  
**Build checkpoint:** 30 November 2026  
**Holiday pilot target:** December 2026–January 2027  
**Public introduction target:** early 2027, after pilot exit gates  
**Status:** Working delivery plan; not a production deployment or a claim that listed modules are implemented.

## Delivery posture — build as if launch is tomorrow

Treat every workflow as production-intended from its first implementation: real authentication and authorisation, tenant isolation, privacy by design, validation, accessible responsive UI, failure handling, auditability and automated acceptance tests. Do not create throwaway demo logic for workflows intended for the pilot. Use synthetic data until the pilot environment and participant permissions are approved.

The December/January holiday period is for a controlled pilot and fixing issues found in real use, not an excuse to expose unfinished features publicly. Early-2027 introduction happens only after the pilot exit gates, security review, operational readiness and product-owner sign-off. Vercel is optional; a secured, monitored non-production host is required for an actual pilot.

## 1. Release definition

The first operational release is the Stage 1 Admissions MVP: a tested student-to-college application and admissions workflow. It is not the completion of every module in the long-term CampusConnect platform.

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

### Track B — Student and college onboarding (P1; Stage 1 product core)

1. Verify Supabase Auth site URL and redirect allow-list in a controlled environment.
2. End-to-end test student signup, email verification, sign-in, password recovery, profile read/update and sign-out.
3. Port the college registration request form into the current `main` experience, based on the reviewed PR #3 migration contract.
4. Validate all inputs client-side and server/database-side; show clear success/failure states; add a privacy notice and abuse/rate-limit protection.
5. Keep public college requests private and INSERT-only. Do not expose request rows or reviewer fields to anonymous users.
6. Build a controlled review/provisioning path for authorised platform reviewers; no public self-approval or self-assigned college roles.

**Exit gate:** synthetic student can complete account lifecycle; prospective college can submit a request; only authorised reviewer can process it; no client can assign privileged roles.

### Track C — First end-to-end college workflow (P2; Stage 1 product core)

1. Approved college administrator can access only their tenant.
2. College can maintain its own profile and course catalogue.
3. Student can discover published courses.
4. Student can grant purpose-specific consent and submit an application to the selected college.
5. Student can see only their own application and status.
6. Assigned college staff can see and process only applications for their college.
7. Application transitions are validated and produce trusted audit events.
8. Course/application relationship cannot cross college boundaries.

**Exit gate:** the full college-to-student application journey passes using two colleges and two students, including negative cross-tenant tests.

## 3. Staged product roadmap — launch the admissions product first

### Stage 1 — Admissions MVP (first operational release)

The first release must deliver one complete student-to-college admissions journey for one authorised pilot college, with the architecture supporting additional colleges after tenant-isolation tests pass.

**Student experience**
- Register, verify email, sign in and manage a minimal student profile.
- Browse only approved/published college and course information, including intake, entry requirements and application deadlines where supplied by the college.
- Complete and submit an application to a selected college.
- View their own application and its current status.
- Receive clear next-step instructions when more information is required or an offer/decision is recorded.

**College experience**
- Authorised college staff sign in and see only their college's records.
- Maintain the college profile and published course/intake catalogue.
- Receive, search, filter and review applications.
- Record a controlled set of statuses: received, under review, information required, accepted, declined and withdrawn.
- Record decision notes and registration instructions with appropriate access controls.
- View a simple admissions pipeline and export only records they are authorised to access.

**Platform operations**
- Review and approve college onboarding requests; no public self-provisioning or self-assigned roles.
- Manage college membership and staff roles through a trusted administrative process.
- Maintain audit events for access-sensitive and decision-related actions.
- Provide tested email notifications for submission and status changes; if email delivery is not ready, show in-app status and a clear manual follow-up path.
- Support an authorised manual hand-off/export for a college that has its own official admissions portal. Do not claim an integration unless an approved API has been implemented and tested.

**Stage 1 exclusions**
- No automated admission decisions; colleges retain decision authority.
- No payment collection, fee reconciliation, student finance or subscription billing requirement for the initial pilot.
- No broad LMS, attendance hardware, complex document vault, automated messaging channels, external ATS/HR integrations or deep student-information-system integrations.
- Do not collect ID numbers, sensitive health data or confidential documents unless a separately reviewed and tested requirement makes them essential. Secure document upload/storage is a later stage.
- Do not treat sample institutions or courses as real; pilot catalogue data requires institutional approval.

**Stage 1 exit gate:** a student can register, find an approved course, submit an application, track it, and receive an outcome/next step; authorised college staff can process it; two-tenant positive and negative access tests pass; audit, privacy, backup and operational checks are signed off.

### Stage 2 — Admissions expansion

- Onboard additional colleges using the proven tenant model.
- Add secure document upload, document requirements, protected storage, retention and deletion workflows after security review.
- Add appointments, campus visit booking, queue management and richer admissions reporting.
- Add approved integrations with existing college portals/SIS platforms, with a manual hand-off fallback.

### Stage 3 — Student opportunity services

- Jobs, including a dedicated Holiday Jobs section.
- Work Experience: internships, apprenticeships, learnerships, WIL and job shadowing.
- Funding directory: bursaries, sponsorships and loans with official application links.
- Bookshops and study materials: college booklists, prescribed textbooks, matric rewrite/ASC resources, study guides and past papers, using direct bookshop links.

### Stage 4 — Learning and student support

- Learning Management essentials: course spaces, resources and basic learner progress.
- Wellness referral directory and sponsored counselling referrals, with minimal data collection and no clinical notes or diagnoses stored.
- Expanded Partner Network and approved integrations.

These stages are product sequencing, not promises that every module will be ready for the first holiday pilot. Each stage needs its own scope, acceptance tests and release approval.

## 4. December delivery gates

| Gate | Target | Required evidence |
|---|---|---|
| Foundation review | 22 Nov | Migration provenance decision, verified baseline plan, privilege/tenant design |
| Student and college onboarding | 29 Nov | Auth lifecycle tests and college request submission/review tests |
| Core college workflow | 6 Dec | Tenant-scoped college/course/application workflow passes |
| Opportunities and learning essentials | 13 Dec | Jobs, Holiday Jobs, Work Experience and LMS smoke tests |
| Student services and partner directory | 17 Dec | Funding, wellness, bookshop and partner directory smoke tests |
| Feature freeze | 20 Dec | Agreed MVP scope implemented; no new features without release-owner decision |
| Holiday pilot preparation | 21–31 Dec | Security, functional, responsive, regression and operational checks; pilot environment and synthetic test accounts ready |
| Controlled holiday pilot | Dec 2026–Jan 2027 | Invited testers complete agreed journeys; defects logged, prioritised and fixed |
| Early-2027 introduction gate | After pilot | Security, privacy, operational and product-owner sign-off; no unresolved release-blocking defects |

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
