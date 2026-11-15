# CampusConnect Admissions MVP — live schema readiness and build contract

**Status:** Engineering assessment based on read-only inspection of the live Supabase catalog and RLS policies. This is not a migration and does not authorise production changes.
**Repository branch:** `campusconnect-december-mvp`
**Inspected project:** `campusconnect-platform` (`owaiysaotqxtqfystigc`)
**Inspection date:** 15 November 2026

## 1. Product slice to build

Stage 1 is the student-to-college admissions journey:

1. A student creates and verifies an account.
2. The student browses approved colleges and published courses/intakes.
3. The student reviews the institution-specific application information and explicitly consents to share their application with that college.
4. The student submits an application.
5. The student can see only their own application and meaningful status/next-step updates.
6. Authorised staff at the selected college can review only that college's applications and record a decision.
7. The student sees the outcome and registration instructions.

The college remains the decision-maker and system of record for its official admissions outcome and registration.

## 2. Verified current foundation

The inspected public schema contains nine tables, all with RLS enabled and zero rows at inspection:

- `colleges`: institution name, slug, status, portal mode and timestamps.
- `college_memberships`: college/user/role membership.
- `student_profiles`: own-account profile fields (name, email, phone, province, city, highest qualification).
- `courses`: college, title, qualification, description, study mode, duration, application_open and published.
- `student_consents`: student, college, purpose, granted_at and revoked_at.
- `applications`: student, college, optional course, status, submitted_at and timestamps.
- `application_documents`: application, storage path, document type, uploader and timestamp.
- `audit_events`: actor, college, event/entity identifiers, JSON details and timestamp.
- `college_registration_requests`: prospective institution request and review metadata.

Existing RLS policies provide a starting point:
- Students can read their own profile and applications.
- Students can create applications only for their own user ID and where an active consent exists for that college.
- College staff can read applications for colleges where they have a membership; staff roles are checked for application updates.
- Courses are publicly readable only when published and their college is active; college members can read their own college's courses.
- Students can grant and revoke college-specific consent.
- Audit events have a college-staff read policy, but no client insert policy was found.

## 3. Important gaps before wiring the current form to live data

### 3.1 Institution and course data is empty
All nine tables had zero rows during inspection. The current public course finder contains hard-coded demonstration institutions and courses. It must not be presented as live catalogue data. A participating college must approve its profile, course names, qualifications, study modes, duration, intake dates, deadlines and application availability before publication.

### 3.2 Applications are too thin for the intended admissions workflow
The current `applications` table has no application reference number, applicant-supplied motivation/notes, intake identifier, decision note, student-facing next-step instructions or explicit status-change history. Do not overload `audit_events.details` as a substitute for a student-visible application timeline.

Proposed design for review:
- Add a stable, non-sequential public application reference.
- Add a minimal application payload for the fields genuinely required by the pilot college; keep the authoritative identity/contact profile in `student_profiles`.
- Add a dedicated append-only `application_status_events` table for status, actor, timestamp and student-visible message/next-step instruction. Keep sensitive internal staff notes separate and restricted.
- Define permitted status transitions and role permissions in a trusted database-side workflow, not only in browser JavaScript.
- Add a tenant-safe composite relationship ensuring the selected course belongs to the same college as the application.

### 3.3 Application status model needs a product decision
The database currently permits: `draft`, `submitted`, `under_review`, `more_information_required`, `accepted`, `rejected`, `registered`, `withdrawn`.
The Stage 1 user interface should map these consistently to plain-language labels. "Received" can be the student-facing label for `submitted`; "Declined" can be the label for `rejected`. Do not add new database status values without a reviewed migration and transition rules.

### 3.4 College provisioning is not yet an operational workflow
A public college registration request table exists and is INSERT-only for anon/authenticated users. It deliberately does not expose request rows to the public. A trusted reviewer process is still needed to approve a request, create/activate the college and assign memberships. Never let a public form create its own college administrator.

### 3.5 Security grants need reconciliation before pilot writes
The earlier read-only baseline audit found broad direct table ACLs and broad default privileges for some object owners, despite RLS. RLS is not a replacement for least-privilege grants. Reconcile effective table/sequence/function grants and default privileges in a disposable non-production environment before enabling real student application writes.

### 3.6 Migration provenance remains unresolved
The live migration ledger contains two versions whose SQL source was not found in the inspected repository refs:
- `20261115120143_auth_profile_bootstrap_and_consent_controls`
- `20261115120200_consolidate_consent_read_policy`

Do not invent their source, replay them, or manually fabricate migration ledger entries. Recover the original files or prepare a reviewed forward baseline from a verified live schema export.

## 4. Front-end work required

The current `campusconnect/index.html` is a localStorage demonstration:
- Application submission creates a browser-local lead.
- Student applications are read from browser localStorage.
- College admissions dashboard reads the same browser-local lead list.
- The course catalogue is hard-coded demonstration data.
- The status dropdown updates localStorage only.
- The account page is the only described browser workflow connected to Supabase Auth and `student_profiles`.

Build the Stage 1 screens as separate authenticated experiences:
- Public catalogue: published active-college courses only.
- Student: profile, consent explanation, application form, own application list/detail and status timeline.
- College: membership-gated dashboard, tenant-scoped applicant list/detail, controlled review actions and decision instructions.
- Platform reviewer: separately authorised college request review/provisioning; no self-assigned roles.

Do not merely replace localStorage calls with direct Supabase calls until the schema, grant matrix, tenant-safe constraints and status workflow have passed non-production tests.

## 5. Required non-production acceptance tests

Use synthetic accounts and at least two colleges:

1. Anonymous visitor sees only published courses belonging to active colleges.
2. Student A can create/read their own profile and cannot read Student B's profile.
3. Student A cannot submit an application without active consent for the selected college.
4. Student A cannot submit an application to a course belonging to a different college.
5. Student A can read their own applications and cannot read Student B's applications.
6. College A staff can see and process College A applications only.
7. College A staff cannot see or change College B applications or courses.
8. A student cannot update their own application status to accepted/rejected/registered.
9. Only authorised staff can perform permitted status transitions; every transition creates a trusted event.
10. A student can read the student-visible timeline but cannot read internal staff-only notes.
11. A college registration request submitter cannot read, update, approve or provision their request.
12. Anonymous/authenticated roles have no unnecessary DELETE/TRUNCATE/REFERENCES/TRIGGER or privileged function grants.
13. Signup, email verification, sign-in, password reset and sign-out work end to end.
14. Failed requests, expired sessions, duplicate submissions and network errors produce safe, understandable UI states.

## 6. Immediate implementation sequence

1. Recover migration source or formally record the provenance gap and produce a verified baseline.
2. Establish a disposable non-production Supabase project and replay/validate the baseline there.
3. Review and implement least-privilege grants, tenant-safe course/application constraints, application event model and trusted status transition/audit workflow.
4. Seed only synthetic college/course/student fixtures in non-production.
5. Complete the student application journey and college admissions workspace against the tested schema.
6. Run all positive and negative tests above, then run responsive/browser regression and backup/restore checks.
7. Only after pilot sign-off, prepare a separately reviewed production rollout plan.

## 7. Guardrails

- No production database changes, Auth setting changes, storage setup, real student records or public launch from this assessment.
- No privileged key in browser code.
- No real ID numbers or sensitive records in demo/pilot fixtures.
- No false claim that the hard-coded demo institutions or courses are participating colleges.
- No unapproved external portal scraping or integrations.
- No merge to main or deployment as a side effect of this document.
