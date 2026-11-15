# CampusConnect — Foundation Remediation Plan

**Status:** Proposed implementation plan; documentation only.  
**Prepared:** 15 November 2026.  
**Target:** Existing Supabase project `campusconnect-platform` and repository `Luxolog/Ekhaya-Campus-Connect`.  
**Approval boundary:** This plan does not authorise or perform database changes, migration execution, policy changes, storage creation, account creation, production configuration changes, code deployment or integration activation.

## 1. Purpose and delivery rule

This plan converts the live foundation gap assessment into a controlled sequence for making CampusConnect safe to extend. The immediate goal is not to build all seven product modules. It is to establish a verifiable identity, tenant, membership, consent, permission, audit, storage and migration foundation first.

The existing Supabase project and GitHub repository remain authoritative. Do not create a replacement project, reset the database, discard existing branches or rewrite the current prototype as a prerequisite. Each implementation stage must have a reviewed change set, explicit approval, a rollback/recovery plan and verification evidence.

## 2. Current baseline — observed, not inferred

The 15 November 2026 inspection recorded nine public tables, all with RLS enabled and zero rows: `colleges`, `college_memberships`, `student_profiles`, `courses`, `student_consents`, `applications`, `application_documents`, `audit_events` and `college_registration_requests`.

The live migration history contained three entries:
- `20261115120143_auth_profile_bootstrap_and_consent_controls`
- `20261115120200_consolidate_consent_read_policy`
- `20261115120448_college_registration_requests`

The open PR #3 branch `campusconnect-phase1-auth` contains two migration files, including `20261115130000_college_registration_reviewed_by_idx`, while main does not yet contain the migrations directory. The live database inspection showed the index `college_registration_requests_reviewed_by_idx`, but the recorded migration history did not show the corresponding version. This is a reconciliation item, not proof of a failed migration.

The project had no Storage buckets or Edge Functions at inspection, and no Auth users. Security and health advisor inspections reported no lint findings at that time; this is not a security certification. The repository's main branch remains a static prototype plus architecture documents, not a complete production application stack.

## 3. Migration and schema reconciliation — first gate

**Do not generate or apply a new migration until this gate is complete.**

1. Freeze schema-writing activity while collecting a read-only baseline from the live project.
2. Export the complete live schema definitions, constraints, indexes, triggers, functions, grants, RLS policies, extensions and migration history. Capture project ref and timestamp with the export.
3. Fetch the full contents and commit history of every migration file on PR #3 and compare them with the live database and the three recorded migration entries.
4. Determine whether the reviewed-by index was created by an unrecorded/manual SQL action, a migration not represented in the current history, or another path. Verify the exact index definition and whether it is valid. Do not drop/recreate it merely to make history look tidy.
5. Establish one canonical migration baseline representing the current live schema. The baseline must be reviewed against the live schema and existing history before it is committed.
6. Decide with the project owner how PR #3 is to be handled. Keep it open and untouched until that decision. Do not merge it solely to obtain migration files.
7. After reconciliation, make future migrations sequential, reviewed, source-controlled and applied only through an approved release process. Never edit an already-applied migration to change live history.

**Gate exit evidence:** a schema snapshot, migration-to-live comparison, discrepancy register with resolution for each item, and an agreed canonical baseline strategy. No discrepancy may be silently ignored.

## 4. Target organisation and tenant model

Keep the existing college tenant model. Extend it deliberately to support external organisations without turning every partner into a college.

| Organisation kind | Purpose | Tenant boundary |
|---|---|---|
| College | Admissions, academic administration, learning and attendance | College tenant; college-owned records carry a college scope |
| Employer | Jobs, holiday jobs and work-experience placements | Employer organisation; access only to its own opportunities, applications and placements |
| Funder / sponsor | Bursaries, sponsorships and approved funding programmes | Funder organisation; access only to its own programme and submitted applications |
| Wellness provider | Referral capacity and sponsored counselling service delivery | Provider organisation; minimum referral/service information only |
| Partner / integration provider | Service directory, agreements and technical connections | Partner record and scoped integration identity; no general student-data access |

Recommended logical foundation:
- Keep `colleges` as the college entity; do not overload it to represent employers, funders or wellness providers.
- Introduce a general organisation registry only if cross-organisation workflows need a common identity. If introduced, retain typed organisation profiles and explicit organisation-kind constraints.
- Use separate membership/relationship records for college staff, employer users, funder users, provider users and platform operators. A generic organisation membership may be considered only if it can enforce distinct role catalogues and data scopes without broadening access.
- Every tenant-owned record must have an immutable tenant/owner reference and tenant-safe foreign keys.
- A user's global student identity must not automatically grant that user staff or partner permissions.

## 5. Identity, membership and permission model

### 5.1 Identity rules

- Supabase Auth identifies the authenticated principal. `auth.uid()` is the source for user ownership checks.
- `student_profiles` remains the student's central profile, keyed to the authenticated user.
- Never use user-editable Auth `user_metadata` for role, tenant, approval or permission decisions.
- Staff invitations must be issued and accepted through a verified process; a user cannot self-assign staff, employer, funder, provider or platform roles.
- Keep platform control-plane access separate from college and partner operational access.

### 5.2 Membership lifecycle

Each membership should have an explicit lifecycle such as `invited`, `active`, `suspended` and `revoked`, with timestamps and actor attribution. Inactive memberships must confer no access. Role grants should be independently auditable and revocable. Avoid encoding a growing permission model only as a CHECK constraint on a single role string.

### 5.3 Capability-based authorisation

Use a controlled catalogue of roles and capabilities, with role-to-capability mappings and scoped grants. A role is a convenient bundle; the capability and resource scope are the actual authorisation decision.

Examples of capability groups:
- College governance: manage college profile, staff membership, academic catalogue and configuration.
- Admissions: view assigned applications, request information, record permitted workflow transitions.
- Registrar: manage approved registration/enrolment records.
- Teaching: access assigned course offerings, class groups, sessions, learning materials and assessments.
- Attendance: manage assigned devices/sessions/register exceptions, not general student records.
- Student support: access only the support workflow and minimum information required.
- Employer: manage own job and work-experience opportunities and candidate workflow.
- Funder: manage own funding programmes and eligible application workflow.
- Wellness provider: manage only assigned referrals and service availability.
- Platform operations: manage platform configuration and onboarding, with no standing access to college/student content.

Elevated grants require approval by an authorised independent actor. Self-approval of one's own elevated membership is prohibited. Emergency access, if ever introduced, must be time-limited, reason-coded and audited.

## 6. Table-by-table access design

This is a target policy matrix, not a description of existing deployed policies. Exact SQL predicates must be written only after the canonical schema and capability model are approved.

| Data area | Student | College staff | External organisation | Platform operator |
|---|---|---|---|---|
| `colleges` | Read approved public directory fields | Read own college; manage only with capability | No access unless explicitly public | Manage tenant lifecycle through platform capability |
| `college_memberships` | No staff membership enumeration | Read/manage own college memberships by capability | No access | Restricted onboarding/governance access |
| `student_profiles` | Read/update own permitted fields | Only students linked to a legitimate workflow and permitted purpose | No broad profile access; only minimal submitted application/referral fields | No standing content access |
| `courses` | Read published catalogue | Manage own college catalogue by capability | No access unless explicitly public | Platform-level configuration only |
| `student_consents` | Read/manage own consent choices and history | Read only consent status/purpose necessary for own workflow | No general consent-history access | Restricted compliance operations |
| `applications` | Read own applications; submit and perform permitted applicant actions | Access only within own college and assigned capability | Employer/funder workflows must use separate domain records, not college application access | No standing access |
| `application_documents` | Access own documents | Access only when assigned to the relevant application workflow | No access to college admission documents | No standing access |
| `audit_events` | No general audit-log access | Limited own-tenant events by governance capability | Only events for own organisation and permitted scope | Restricted audit investigation |
| `college_registration_requests` | Public submission only where designed; no review access | No access until approved college membership exists | No access | Designated onboarding reviewers only |

New domain tables must receive a table-specific matrix before creation. Do not copy one broad “college member can access” policy across all tables.

### 6.1 Minimum policy rules

- Every tenant-owned read and write must prove membership is active, capability is present and resource scope matches the tenant.
- Every UPDATE policy must have both `USING` and `WITH CHECK`, plus a SELECT policy that makes the row visible to the updater.
- Prevent changing tenant IDs, ownership IDs, applicant IDs, organisation IDs, approval fields or status fields through unrestricted client updates.
- Use controlled server-side transition functions or narrowly scoped updates for sensitive lifecycle changes.
- Use explicit role targets such as `TO authenticated`; authentication alone is not authorisation.
- RLS must be enabled on every table in an exposed schema. Evaluate FORCE RLS where appropriate, while documenting trusted owner/service contexts.
- Review table grants independently of RLS. Revoke unnecessary `anon` and `authenticated` privileges; grant only the required table/operation access.
- Do not expose private schemas or privileged functions through the Data API.
- Treat views as security boundaries: use `security_invoker = true` where supported, or keep views inaccessible to untrusted roles.
- Avoid SECURITY DEFINER. If a narrowly justified function is unavoidable, keep it in a non-exposed schema, use a safe fixed search path, explicitly validate the caller and restrict EXECUTE grants.

## 7. Tenant-safe relational constraints

Before expanding the schema, add or verify composite uniqueness and foreign-key constraints so tenant scope is enforced by PostgreSQL, not only by application code.

Known prerequisites from the existing academic drafts:
- A unique key on `courses(college_id, id)` is needed before a course offering can safely reference both course and college.
- A unique key on `college_memberships(college_id, id)` is needed before class-group staff assignments can safely reference both membership and college.
- Course offerings, academic terms, campuses, class groups, enrolments, staff assignments, sessions and attendance records must use consistent college-scoped composite references.
- Class-group enrolment remains many-to-many: a student may belong to multiple groups within the same course offering, subject to college-defined rules.
- Validate that an offering, group, student enrolment, lecturer assignment and session all belong to the same college and the same applicable offering.
- Prevent cross-tenant document attachment by constraining the document's application and college relationship.
- Define uniqueness scopes explicitly: student number (college or campus), course code (college), term code (college), device identity (college), and external provider IDs.

Do not assume the existing attendance SQL draft is ready to apply. It must first be reconciled with the academic structure draft, including the missing `class_group_enrolments` and `class_group_staff` bridge definitions, duplicate table definitions and missing RLS/grant design.

## 8. Consent and data-sharing foundation

The current `student_consents` table is too small to serve as a complete long-term consent evidence model without further design.

Target requirements:
- A controlled purpose catalogue, not arbitrary free-text purposes alone.
- Versioned notice text or immutable notice-version references.
- Separate purposes for application sharing, academic/learning integrations, marketing, referrals, counselling coordination and other optional processing.
- Record who acted, for which student, which organisation/recipient, the purpose, notice version, timestamp, channel and relevant evidence.
- Preserve immutable grant/revoke events; do not overwrite history to make a previous grant appear never to have existed.
- A revocation must stop future optional sharing and trigger downstream propagation where required; it cannot erase a lawful record-retention obligation.
- Consent is not assumed to be the only lawful basis. The controller must document the applicable POPIA lawful basis and purpose for each processing activity.
- Provide a data-subject request and correction workflow, retention schedule and deletion/anonymisation rules.

A college may see only the consent or lawful-basis evidence needed for its own relationship and processing. A partner must not browse a student's global consent history.

## 9. Private document storage

No Storage buckets existed at inspection. Before enabling uploads:

1. Define document classes, data owners, purpose, allowed MIME types, maximum size, malware scanning requirement, retention and deletion rules.
2. Use private buckets by default. Do not create public buckets for identity, admissions, academic, funding, employment or wellness documents.
3. Use server-issued object paths that encode tenant and record scope without exposing sensitive identifiers.
4. Validate ownership, active membership, capability, tenant and parent-record relationship for every upload, download, list, move and delete.
5. Keep bucket policies and database metadata constraints aligned. A storage path alone is not proof of authorisation.
6. Use short-lived signed URLs only after server-side authorisation. Avoid long-lived public URLs.
7. Do not allow one college, employer, funder or provider to enumerate another organisation's objects.
8. Log document access and lifecycle actions without copying document contents into logs.
9. Define quarantine/scanning and failed-upload cleanup before accepting real documents.

Suggested logical separation: admissions documents; academic/learning resources; employment/work-experience documents; funding evidence; and any wellness referral attachment only if a documented necessity exists. Wellness clinical notes and therapy records must not be stored in CampusConnect.

## 10. Audit and operational evidence

The existing `audit_events` table needs an explicit trusted write path and event contract.

Minimum event fields should identify event type, actor principal/type, organisation/tenant scope, target resource type/id, timestamp, request/correlation ID, outcome and safe metadata. Avoid recording secrets, full identity numbers, document contents, counselling details or unnecessary personal data.

- Clients must not be able to fabricate privileged audit events.
- Prefer a trusted server-side append-only path; deny ordinary UPDATE/DELETE.
- Record membership grants/revocations, role changes, consent events, profile sharing, application decisions, document access, exports, integration actions, attendance adjustments and privileged support access.
- Restrict who can read audit events; tenant administrators see only their permitted tenant events.
- Protect retention, integrity and export processes.
- Define how system-generated and device-originated events are authenticated and attributed.

## 11. Sensitive domain boundaries for future modules

These domains are intentionally not included in the first foundation remediation release, but their access boundaries must shape the shared foundation.

### Jobs and Holiday Jobs
Jobs is an employer-owned opportunity and recruitment domain. Holiday Jobs is a dedicated section/category within Jobs with its own discovery and filtering experience. Employers manage only their own listings and candidate workflow. Student applications are separate from college admissions applications.

### Work Experience
Work Experience is a distinct domain for internships, apprenticeships, learnerships, work-integrated learning (WIL) and job shadowing. It needs placement agreements, supervision, approvals, attendance/progress and completion outcomes. It must not be collapsed into ordinary job listings or applications. College WIL coordinators may see only placements linked to their students/programmes and assigned responsibilities.

### Student Funding
Keep bursaries, sponsorships and loans as distinct programme types with separate eligibility, evidence, decision and disbursement states. The initial platform does not perform credit scoring, loan underwriting, loan origination or debt collection. Funders see only applications submitted to their own programmes.

### Student Wellness
Support free referrals and sponsored counselling with minimum necessary information. Do not store diagnoses, therapy notes or clinical records. Providers receive only assigned referral details and the information required to deliver the service. Sponsors receive aggregate utilisation reporting by default, not named student-level clinical or referral data.

### Partner Network and Integrations
This is a partner/service directory, agreement register and integration catalogue, not a consumer shopping marketplace. Integrations use scoped credentials, explicit data contracts, minimum permissions, event logging, retries, idempotency, revocation and health monitoring. No unauthorised portal scraping or direct device writes.


## 11.1 Education bookshop and study-material partners

The Partner Network must support verified bookshops, campus bookstores, textbook suppliers, publishers and approved education-material providers.

Required use cases:
- College/course booklists with prescribed title, edition and ISBN references.
- Student discovery of suppliers able to fulfil required textbooks and reading lists.
- Provider-submitted availability, indicative pricing, collection/delivery information and student discounts.
- Direct order/contact links to the provider's own sales channel; optional affiliate referral tracking only under an agreed transparent arrangement.
- Matric rewrite / Amended Senior Certificate study materials, including textbooks, study guides and past-paper resources, discoverable as a dedicated education-support category.
- Separate college-prescribed booklists from general matric rewrite preparation materials so students can find the correct curriculum and examination pathway.

This is a Partner Network directory/referral capability, not a retail marketplace. No general product catalogue, stock ownership, checkout or payment processing is proposed for CampusConnect. Begin with free listings and direct provider links. Do not represent stock or prices as live unless the bookshop supplies a current verified feed/update.

The data model should keep provider identity, booklist references, ISBN/edition metadata, curriculum/exam relevance, listing validity and referral events distinct from college admissions, student academic records and any payment data held by the provider.

## 12. Security verification matrix

Create automated tests and repeat them against a non-production environment before every release. Use at least two colleges, two students, two staff members, two external organisations and one platform operator in the fixtures.

| Test | Expected result |
|---|---|
| College A staff requests College B application | Denied / no row returned |
| College A staff changes a record's college_id to College B | Rejected by policy and/or database constraint |
| Student A reads Student B profile, application or document | Denied |
| Student submits application to a college | Only that college receives the permitted application record |
| Revoked/inactive college membership accesses tenant data | Denied |
| Staff member self-assigns registrar/admin role | Denied |
| Staff member updates a role or approval field outside capability | Denied |
| Lecturer reads an unassigned course group/session | Denied |
| Attendance officer reads unrelated academic/financial data | Denied |
| Employer A reads Employer B candidates or placements | Denied |
| Funder A reads Funder B applications | Denied |
| Wellness provider reads an unassigned referral | Denied |
| Sponsor requests named counselling records | Denied; only approved aggregate reporting |
| Anonymous user accesses private documents or internal tables | Denied |
| User revokes optional sharing | Future optional access/dispatch stops as designed; history remains |
| Client attempts to insert/update/delete audit event | Denied |
| User uploads document under another tenant's path | Denied |
| Expired or revoked signed URL is reused | Denied/expired as configured |
| Integration replays an event | Idempotent handling; no duplicate business action |
| Device submits event for another college/device | Denied and recorded as a security event |

Tests must include positive cases as well as negative cases; a system that denies all access is not a passing implementation.

## 13. Delivery sequence and gates

| Phase | Work | Exit gate |
|---|---|---|
| 0. Read-only baseline | Capture live schema, grants, policies, functions, triggers, indexes and migration history | Signed-off baseline and discrepancy register |
| 1. Migration reconciliation | Compare live state, main, PR #3 and migration history; agree canonical baseline | Reproducible migration history with no unexplained drift |
| 2. Identity and tenant foundation | Confirm organisation boundaries, membership lifecycle, role/capability catalogue and ownership model | Approved entity model and role/capability matrix |
| 3. RLS and grants | Design table-specific policies, grants, trusted functions and cross-tenant constraints | Reviewed policy matrix and passing security tests |
| 4. Consent and audit | Versioned purpose model, immutable event history and trusted audit path | Consent and audit acceptance tests pass |
| 5. Storage foundation | Private bucket plan, object-path scheme, scanning, retention and policies | Cross-tenant storage tests pass |
| 6. Application foundation | Move demo workflows to server-backed application services incrementally | Pilot workflows verified without breaking existing account onboarding |
| 7. Academic/attendance foundation | Reconcile academic and attendance drafts, then implement offerings, multiple groups, sessions and attendance | Academic and device security tests pass |
| 8. Product domains | Add Jobs, Work Experience, Funding, Wellness and Partner Network separately | Each domain has its own approved data contract, policies and tests |

Do not start phase 6 or later while phases 0–5 contain unresolved critical tenant-isolation or authorisation defects.

## 14. Release, backup and rollback requirements

Before each approved schema release:
- Take and verify a recoverable database backup/snapshot using the project's supported process.
- Record the target project ref, migration list and current schema snapshot.
- Review SQL and generated migration diff; run Supabase security/performance advisors.
- Test migration on a non-production copy with representative data and RLS enabled.
- Confirm forward and rollback/recovery steps. For destructive or data-transforming changes, prefer additive migration plus controlled backfill and delayed removal.
- Apply only to the explicitly named CampusConnect project after approval.
- Verify migration history, schema, policies, grants, triggers, advisor output and security tests after release.
- Keep secrets out of GitHub, browser bundles, logs and documentation.

No production student data should be introduced until retention, support, incident response, access review, backup recovery and data-subject request processes are operational.

## 15. Decisions required before implementation

The following are product/governance decisions, not matters to guess in SQL:
1. Should the organisation registry be a common parent entity, or should employer/funder/provider organisations remain separate typed tables linked through a shared directory?
2. Which staff roles and capabilities are required for the first pilot college, and who approves each grant?
3. Which data domains are authoritative in existing-portal and hybrid colleges, and which integration direction is allowed for each field?
4. What are the approved retention periods and lawful bases for admissions, academic, employment, funding and wellness referral data?
5. Which document classes are genuinely required in the first pilot?
6. Which college(s) and external organisations form the first controlled pilot?
7. What is the agreed decision for PR #3 and its migration files?

## 16. Immediate next action

Complete Phase 0 as a read-only evidence-gathering exercise, then produce a migration reconciliation report and a final tenant/role decision record. Only after those are reviewed should a separate implementation proposal be prepared for approval. This document itself performs no schema or production action.


## 17. PR #3 reconciliation review — 15 November 2026

A fresh comparison was performed against the then-current `main` branch and live Supabase catalog.

### 17.1 Branch status

PR #3 (`campusconnect-phase1-auth`) remains open and unmerged. At the comparison point:
- PR head: `38b6552f1100e82fad00a9ab0765d4aded0416b7`.
- Main head: `b3c0bb3ca72b075c4c43bb1ff4a66aeb68c49a7a`.
- Branch comparison: 7 commits ahead, 34 commits behind, status `diverged`.
- Changed paths: `campusconnect/README.md`, `campusconnect/account.html`, `campusconnect/index.html`, and two migration files.

The PR's README is stale relative to current main: it points to an older GitHub Pages project path, describes account access as absent from the prototype, and omits the architecture and governance documentation added to main. It must not replace the current README.

### 17.2 Frontend findings

The current main branch already contains:
- A student account page at `campusconnect/account.html` with signup, sign-in, password reset, profile editing and sign-out.
- A navigation link to that account page from `campusconnect/index.html`.

The PR branch's account page is a different, older implementation and should not overwrite the current main version. The PR's index navigation addition is already present on main in a different location/style. Therefore, those two changes are superseded rather than candidates for blind cherry-picking.

The current main account page reads and writes fields that were confirmed in the live `student_profiles` table: `first_name`, `last_name`, `email`, `phone`, `province`, `city`, and `highest_qualification`. This is a schema compatibility check only; hosted Auth redirect, SMTP, signup, verification, recovery and profile-write flows have not yet been end-to-end tested.

The PR account page also contains the college registration request form. The corresponding table exists live and its public policy is INSERT-only with server-enforced pending/unreviewed fields. That useful form capability should be separately ported into the current main account experience only after a focused review and test plan. Do not replace the better current student account implementation with the older PR page.

### 17.3 Migration findings

- `20261115120448_college_registration_requests.sql` is recorded in the live migration ledger and the resulting table/policy/indexes exist. The source file is useful evidence, but it must be incorporated into a canonical repository migration chain only after the missing earlier migrations are recovered.
- `20261115130000_college_registration_reviewed_by_idx.sql` is present on the PR branch, and the index exists in the live database, but migration version `20261115130000` is absent from the live migration ledger.
- The first two live migration versions (`20261115120143` and `20261115120200`) are not present in the PR branch's migration directory. Their exact SQL and provenance remain unverified.
- The live database has broad direct grants and broad public-schema default privileges, as documented in the live baseline audit. The PR migration does not remediate those grants or defaults.

Do not merge the PR to obtain the migrations. Do not rerun either migration merely because its file is present in Git. Do not manually insert a migration ledger row for the index until deployment provenance and canonical migration workflow are established.

### 17.4 Recommended disposition

1. Keep PR #3 open and unmerged while its useful college-request form and migration evidence are retained.
2. Do not rebase the seven-commit branch directly onto main. It has diverged materially and contains stale documentation/frontend changes.
3. Use current main as the source of truth for the student account page and navigation.
4. Recover the exact source/deployment evidence for the first two recorded migrations. If the original SQL cannot be recovered, explicitly document that gap and establish a reviewed baseline strategy from the verified live schema; do not fabricate historical migrations.
5. Port only the college registration form capability into the current main account page in a clean, separately reviewed branch. Keep it limited to INSERT-only submission; review spam/rate limiting, input validation, privacy notice and abuse monitoring before public promotion.
6. Prepare a dedicated migration reconciliation change set after the baseline and provenance review. It must not mix UI changes with migration-ledger repair.
7. Once replacement work is reviewed and any useful changes are preserved, close the stale PR with a clear superseded explanation. Until then, leave its state unchanged.

### 17.5 Current implementation boundary

This review and the associated repository documentation are read-only with respect to Supabase. No database grants, default privileges, RLS policies, schema objects, migration records, Auth settings, Storage buckets, users or production data were changed. No PR was merged, rebased or closed.


## 18. PR migration-source inspection — 15 November 2026

A follow-up read of the exact SQL files on the PR #3 head (campusconnect-phase1-auth) was completed. This is repository-source inspection only; it does not establish that either file was deployed exactly as written.

### 18.1 College registration request migration

The PR branch contains supabase/migrations/20261115120448_college_registration_requests.sql. Its SQL:
- Creates public.college_registration_requests if absent.
- Defines bounded institution/contact fields, a South African province allow-list, portal-mode values (existing, full, hybrid), and request states (pending, under_review, approved, declined).
- Adds reviewer and review timestamp fields, including reviewed_by referencing auth.users(id).
- Enables RLS, revokes all table privileges from anon and authenticated, then grants INSERT to those roles.
- Adds an INSERT policy requiring a pending, unreviewed request.
- Creates indexes on (status, created_at DESC) and lower(contact_email).
- Adds a table comment describing manual review and provisioning.

This source aligns with the observed live table shape and intended public submission boundary at a high level. The live catalog inspection remains the authority for the currently deployed state; source-file presence is not proof of deployment provenance.

### 18.2 Reviewer index migration

The PR branch also contains supabase/migrations/20261115130000_college_registration_reviewed_by_idx.sql, whose complete statement is:

```sql
create index if not exists college_registration_requests_reviewed_by_idx
  on public.college_registration_requests(reviewed_by);
```

The live catalog already contains this index, while the live migration ledger does not contain version 20261115130000. The statement's idempotent form does not resolve the provenance gap. Do not replay it or insert a migration-history record solely on the basis of this file.

### 18.3 Repository-chain gap confirmed

The exact paths supabase/migrations/20261115120143_auth_profile_bootstrap_and_consent_controls.sql and supabase/migrations/20261115120200_consolidate_consent_read_policy.sql were not found on the inspected PR branch. The expected migration paths were also not found on current main. The live ledger records those versions, but their source SQL is still not available in the inspected repository refs.

This confirms a repository migration-chain completeness gap. It does not prove that the source never existed elsewhere, was deleted, or was not deployed from another location.

### 18.4 Decision

- Preserve the two PR migration files as evidence; do not merge the PR just to import them.
- Keep the live ledger, live catalog and repository migration directory as three separate evidence sets until provenance is resolved.
- Recover original migration source from the original authoring environment, CI/deployment artifacts, backups or another verified repository ref.
- If source recovery fails, document the missing provenance and establish a reviewed forward baseline from the verified live schema. Do not fabricate historical SQL or retroactively claim a baseline is replayable.
- No live database or PR state was changed by this inspection.


## 19. RLS-to-grant alignment review — 15 November 2026

A read-only query of pg_policies was run against the live project after the ACL review. The following is a preliminary minimum-operation design derived from the current policies. It is not an executable grant script and must be tested in a non-production environment before approval.

### 19.1 Operations evidenced by current policies

| Table | Anonymous client | Authenticated client | Notes / required caution |
|---|---|---|---|
| colleges | No access indicated | SELECT | Membership-scoped SELECT policy |
| college_memberships | No access indicated | SELECT | Own-membership SELECT policy |
| student_profiles | No access indicated | SELECT, INSERT, UPDATE | Own-profile and active-consent college read policies; signup trigger separately inserts via SECURITY DEFINER |
| courses | SELECT | SELECT, INSERT, UPDATE, DELETE | Public SELECT only for published courses at active colleges; writes limited by current staff-role policies |
| student_consents | No access indicated | SELECT, INSERT, UPDATE | Student-owned consent grant/revoke; college members can currently read relevant college consents |
| applications | No access indicated | SELECT, INSERT, UPDATE | Student-owned create/read and college membership read; staff UPDATE role list is explicit |
| application_documents | No access indicated | SELECT, INSERT | Applicant/college-member reads; applicant-owned inserts |
| audit_events | No access indicated | SELECT | Relevant college staff SELECT only; no client INSERT/UPDATE/DELETE policy observed |
| college_registration_requests | INSERT | INSERT | Public request submission constrained to pending and unreviewed state |

The table is a policy-derived starting point, not a statement that each role already has only these privileges. Existing direct ACLs and default privileges remain broader than this proposed operational shape.

### 19.2 Required review before converting this into SQL

1. Confirm whether profile creation should remain exclusively in the trusted signup trigger or whether authenticated direct INSERT is still needed. The current profile INSERT policy exists, but the trigger already performs bootstrap creation.
2. Confirm whether any client-side workflow performs physical DELETE on any table. No current DELETE RLS policy was observed except courses; do not grant DELETE merely because a broad ACL currently includes it.
3. Confirm whether college staff need direct application UPDATE or whether status transitions should move to a trusted server-side operation with an explicit state machine and audit event.
4. Decide how audit events are appended. The current policy set exposes relevant events for SELECT but provides no client append policy. Prefer a trusted, narrowly scoped append path; do not grant clients broad INSERT/UPDATE/DELETE on the audit table.
5. Review column-level exposure and mutation risks. Table-level grants plus row-level policies do not prevent a user from changing sensitive columns that the current UPDATE policy does not separately protect. Evaluate column grants or trusted RPC/server operations for profile fields, application state, consent metadata and course ownership.
6. Confirm the exact function and trigger privilege behaviour for the signup bootstrap before changing function grants or ownership.
7. Review public course SELECT fields for data minimisation; RLS filters rows but does not hide sensitive columns in a selected row.

### 19.3 Default-privilege remediation

The existing default ACLs must be corrected for each actual object owner that creates application objects. The change plan must explicitly cover future tables, functions and sequences in public. A change to defaults does not retroactively repair existing objects, and a table-level REVOKE does not automatically fix future-object defaults.

Before applying defaults, inventory object ownership and migration execution roles. Test creation of a representative table, function and sequence under each relevant owner in a non-production environment, then inspect effective privileges for anon, authenticated and service_role.

### 19.4 Acceptance tests for the grant plan

The non-production test suite must assert both allowed and denied operations:
- Anonymous: published active-college course SELECT and pending college-request INSERT succeed; unpublished course reads, internal table reads and request reads fail.
- Student: own profile read/update, own consent grant/revoke, own application submission/read and own document metadata insert/read succeed; another student's rows and unrelated college data fail.
- College staff: only assigned college rows are visible; role-specific course writes and permitted application actions succeed; cross-college reads/writes fail.
- Audit: authorised relevant staff can read scoped events; client attempts to forge or mutate events fail; trusted append path records actor, tenant, action and timestamp.
- Service role: trusted server workflows work, while service credentials remain absent from browser bundles and client logs.
- Defaults: newly created objects do not grant unnecessary client privileges.

Do not treat a successful advisor run as a substitute for these role-based tests.

### 19.5 Status

This section records a proposed design based on live policy definitions. No GRANT, REVOKE, ALTER DEFAULT PRIVILEGES, RLS policy, function, trigger or schema change was executed. The proposal remains subject to product-owner review, implementation review and non-production validation.
