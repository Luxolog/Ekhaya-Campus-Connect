# CampusConnect — Master System Architecture

**Status:** Consolidated architecture proposal for review. This document does not represent a completed implementation, production-ready security certification, or approved database migration. No Supabase database changes are authorised or performed by this document.

## 1. Purpose and product boundary

CampusConnect is an Ekhaya Technologies platform for student discovery, recruitment, applications, admissions workflows, college administration, academic delivery, learning and attendance. It supports colleges with an existing student information/student portal, colleges that need a full admissions portal, and colleges that adopt selected modules in a hybrid arrangement.

The platform is a shared technology service, not a replacement for every college's academic authority or student information system. Each tenant's operating mode and module configuration must identify which system is authoritative for each record and workflow.

### Product principles

- One global authenticated student identity, with college-scoped relationships and records.
- A student chooses which college(s) to engage with; data is not made available to every college by default.
- Purpose-specific consent and other documented lawful bases govern data sharing.
- Tenant isolation applies to every college-owned record and operation.
- Colleges retain control of their academic policies, lecturers, course content, assessment, marking and academic outcomes by default.
- CampusConnect provides shared workflow, learning and attendance technology.
- Platform operations are separate from college operations and use a separately governed control plane.
- Integrations are authorised, scoped, auditable and recoverable.
- Student data is never sold or treated as a monetisable directory.

## 2. Operating modes and system-of-record ownership

| Mode | CampusConnect responsibility | College/external system responsibility |
|---|---|---|
| Existing portal / integration | Course discovery, enquiries, consent-led lead/application routing, admissions CRM and approved status synchronisation or hand-off | College portal remains authoritative for official applications, admission decisions, fees and registration unless an explicit integration agreement defines a narrower boundary |
| Full portal | Branded application journey, catalogue/intakes, applicant records, admissions CRM, document checklist, appointments/queue, offers and registration workflow | College approves admissions rules, official decisions and academic records; CampusConnect may host agreed workflows |
| Hybrid | College selects modules to adopt, with clear ownership for each workflow and data domain | Existing college systems remain authoritative for modules not adopted by CampusConnect |

Every tenant configuration should record, per domain, the system of record, permitted direction of sync, field ownership, conflict-resolution rule and operational owner. Do not infer authority merely from a tenant's overall mode.

No portal scraping or automated interaction without written authorisation. Prefer approved APIs/webhooks; use secure file exchange or staff-managed hand-off where no API exists.

## 3. Users, roles and trust boundaries

### 3.1 User classes

- Student/applicant: owns their global profile and accesses their own applications, enrolments, class groups, learning and attendance.
- College staff: receives tenant membership and role/capability grants.
- Lecturer / teaching assistant: receives access only to assigned offerings, groups and sessions.
- Attendance officer: receives explicit campus/device/session register scope.
- College administrator: manages its own tenant within delegated authority.
- Platform operator: performs only platform-level functions; does not receive standing access to college student records.
- External integration/device: authenticates as a connector/device identity, not as a human user.

### 3.2 College role model

The current live membership role constraint has been observed to allow only `college_admin`, `admissions_staff` and `registrar`. The future model proposes these roles: `college_admin`, `admissions_staff`, `registrar`, `lecturer`, `teaching_assistant`, `attendance_officer`, and `student_support`.

Do not simply widen a role CHECK constraint and treat that as authorisation. The staff governance design proposes one college membership per user per college, membership lifecycle state, verified staff invitations, and multiple role grants per membership through a controlled role/capability catalogue. Teaching assignments are additional scope, not a substitute for a role grant. Attendance scope is explicit.

No public self-assignment to staff roles. No self-approval of elevated access. Additional college administrator grants should use two-person approval or a controlled recovery process.

### 3.3 Platform control-plane roles

Proposed platform roles are `platform_owner`, `platform_admin`, `onboarding_reviewer`, `billing_admin`, `integration_admin`, `support_agent`, `security_auditor`, and `platform_developer`. These roles are distinct from college memberships. Use least-privilege capabilities, strong authentication/MFA, separation of duties, periodic access reviews and audited emergency access.

### 3.4 Trust boundaries

1. Public student discovery and registration pages.
2. Authenticated student workspace.
3. College tenant workspace and its server APIs.
4. Platform administration control plane.
5. Server-side integration gateway and background workers.
6. Private document/object storage.
7. Third-party college systems, messaging/video providers and attendance hardware.

Browser navigation or hidden menu items are never security controls. Every API, server action and database operation must independently enforce identity, tenant, purpose and capability.

## 4. Logical system topology

The recommended target topology is:

- Web application: Next.js surfaces for public discovery, student workspace, college workspace and platform control plane.
- Identity: Supabase Auth or equivalent managed identity; verified email and stronger authentication for privileged operators.
- Data: PostgreSQL with tenant-aware relational constraints and Row Level Security.
- File storage: private object storage with short-lived, permission-checked access.
- Server-side application layer: trusted operations for invitations, consent, registration activation, group allocation, role changes, document access, attendance processing and exports.
- Integration gateway: connector adapters, signed webhook intake, API polling where approved, replay protection and idempotent event processing.
- Background processing: durable queues for notifications, sync, attendance batches, exports and retry/dead-letter handling.
- Secret management: server-side secret store for provider credentials, device keys and signing material.
- Observability: structured logs, metrics, correlation IDs, audit events, alerting, backup and restore verification.

This is a proposed deployment topology, not a statement that these services or workflows have been deployed. Keep privileged keys and provider secrets out of browser code. The browser may use only publishable client credentials where appropriate.

## 5. Core data domains and ownership

### 5.1 Existing core entities

The current CampusConnect Supabase project has been inspected as containing these nine public tables: `colleges`, `college_memberships`, `student_profiles`, `courses`, `student_consents`, `applications`, `application_documents`, `audit_events`, and `college_registration_requests`. RLS was reported enabled on the inspected tables. The existing schema and migration history still require baseline reconciliation before production migrations.

- `colleges`: tenant identity, lifecycle and operating mode.
- `college_memberships`: college/user relationship and current role field.
- `student_profiles`: global student profile keyed to authenticated user.
- `courses`: college-owned catalogue entry.
- `student_consents`: purpose-specific student sharing grants.
- `applications`: college-scoped applicant workflow.
- `application_documents`: application document metadata/reference.
- `audit_events`: audit history.
- `college_registration_requests`: prospective college onboarding requests.

These observations are a snapshot of the inspected schema, not a guarantee that the current live schema has not changed since inspection.

### 5.2 Proposed academic domain

The academic structure proposal adds:

- `campuses`: tenant-owned physical or virtual sites and timezone.
- `academic_terms`: academic periods and registration windows.
- `course_offerings`: a specific delivery of an existing catalogue course in a term, mode and optional campus.
- `course_enrolments`: registrar-confirmed student registration in an offering.
- `class_groups`: cohort, lecture, tutorial or practical groups within an offering.
- `class_group_enrolments`: many-to-many assignment between course enrolments and class groups.
- `class_group_staff`: scoped lecturer/assistant/coordinator assignment.
- `class_sessions`: scheduled lesson, tutorial, lab, workshop or examination.

A catalogue course is not itself an active offering. An accepted application is not itself an enrolment. Registrar-approved registration creates the enrolment through a trusted, idempotent operation.

**Multiple group allocation is required:** one course enrolment may be assigned to multiple class groups within the same offering, such as Lecture Group A and Tutorial Group C. Use `class_group_enrolments` as the source of truth; do not add a single `group_id` to `course_enrolments`.

### 5.3 Proposed learning domain

- `course_modules`: ordered learning modules within an offering.
- `lessons`: live, recorded, reading or activity lesson metadata and publication state.
- `lesson_resources`: resource metadata and private storage object paths.
- `lesson_enrolments`: student access/progress state.
- `online_classroom_sessions`: association between a class session and a supported provider meeting reference.

The college supplies and approves lecturers, teaching materials, assessments, marking and academic outcomes by default. CampusConnect supplies the LMS and classroom technology. Optional Ekhaya delivery support requires an agreed service scope under college academic governance. Ekhaya-managed courses require a separate provider/approval workflow; qualification and accreditation claims need appropriate regulatory checks.

### 5.4 Proposed attendance domain

- `student_cards`: college-issued card assignment, technology, issue/expiry/revocation and keyed credential fingerprint where feasible.
- `attendance_devices`: reader/gateway identity, campus, vendor/model/protocol, capabilities and secret reference.
- `attendance_device_events`: append-only received evidence, idempotency and verification result.
- `qr_attendance_challenges`: hashed, short-lived, session-bound QR challenges.
- `attendance_records`: derived per-student/per-session register state.
- `attendance_adjustments`: append-only correction request and decision history.
- `online_presence_events`: provider join/leave evidence, subject to capability and privacy controls.
- `attendance_device_health_events`: device connectivity and operational events.

CampusConnect is the authoritative attendance ledger. Readers and video services are evidence sources, not the system of record.

### 5.5 Other platform domains

Future domains include staff invitations and role grants, integration connections/events, appointments and queue tickets, subscriptions, invoices/payments, usage meters, support cases and scoped support sessions, security incidents, and platform audit records. These must have explicit ownership, tenant scope, retention and access rules before implementation.

## 6. Student lifecycle and principal workflows

1. Student discovers and compares approved college/course information.
2. Student creates or signs into a global account and manages their own profile.
3. Student selects a college and submits an enquiry/application with clear purpose-specific sharing consent where required.
4. Application is routed only to the selected college and permitted workflow.
5. Admissions staff review, request information and record decisions within the college's configured state machine.
6. In existing-portal mode, official processing remains in the external college system; CampusConnect records only the agreed lead/application state and verified hand-off/synchronisation.
7. In full-portal mode, the college uses the configured admissions workflow; offers and registration checks are performed under college policy.
8. Registrar verifies accepted application or authorised external registration evidence and activates a course enrolment through a trusted server-side operation.
9. Registrar assigns the enrolment to one or more class groups in the same offering.
10. Student receives access to eligible timetable, learning resources and class sessions.
11. Attendance evidence is processed for eligible sessions; student and authorised staff see scoped records.
12. Suspension, transfer, completion, withdrawal, correction and access revocation are audited transitions, not destructive deletion of history.

Marketing consent must remain separate from application processing consent. A submitted application, accepted application or UI status change must not silently create an official enrolment.

## 7. College administration workspace

The college workspace is tenant-scoped and capability-filtered. Proposed navigation:

- Overview
- Admissions
- Students
- Academic Management
- Staff & Access
- Integrations
- Reports
- College Settings
- Billing & Plan (where enabled)

Academic Management includes campuses, academic terms, courses/offerings, class groups, timetable/sessions, enrolments, learning delivery and attendance as modules become available.

Key workflows include tenant setup, course catalogue review, admissions pipeline, applicant case management, registrar registration, multi-group allocation, staff invitations and teaching assignments, integration monitoring, scoped reports/exports and billing visibility for designated roles.

The active tenant context must be explicit. A user with memberships in multiple colleges may switch only between active memberships and must never retain data from the previous tenant in client caches or server responses.

## 8. Platform super-admin workspace

The platform control plane is operated by Ekhaya Technologies and is distinct from each college workspace. Proposed navigation:

- Platform Overview
- Colleges & Tenants
- Onboarding & Verification
- Platform Administrators
- Plans & Billing
- Usage & Entitlements
- Integrations
- Support & Access Requests
- Security & Audit
- Platform Configuration
- Service Health

Platform functions include registration request review, tenant create/activate/suspend/closure, initial college administrator provisioning, platform staff role governance, plans and subscription lifecycle, usage metering, connector governance, support access approvals, security incident handling and service health.

Platform dashboards should use metadata and aggregates, not broad student-level browsing. Support is metadata-only by default. Exceptional tenant content access requires a college-approved, purpose-limited, time-limited session, read-only by default, separate approver, notification where appropriate and immutable audit. A support agent cannot approve their own access.

Subscription status and module entitlements are not authorisation mechanisms and never override tenant RLS. Non-payment must not automatically delete student or academic records.

## 9. Integrations and external systems

Each integration connection must identify the tenant, external system, vendor, authorised purpose, contract/permission evidence, data scope, owner, credential reference, mapping version, sync direction and review/expiry date.

Preferred patterns:
- Approved API integration.
- Signed webhook intake.
- Secure file exchange where API access is unavailable.
- Staff-managed hand-off/export as a controlled fallback.

Required controls:
- Written authorisation and purpose limitation.
- Server-side secret storage and rotation.
- Signed requests/webhooks, timestamp validation and replay protection.
- Tenant binding, stable idempotency keys and duplicate handling.
- Durable queue, retries, dead-letter handling and reconciliation.
- Visible sync status and failure reason without exposing unnecessary payloads.
- Audited pause, revoke, rotate and manual reconciliation operations.

Do not scrape or automate external college portals without written permission. Do not mark a record synchronised until the external system confirms success or a staff member records verified hand-off evidence.

## 10. Attendance and hardware architecture

Support target methods: NFC, RFID, QR, lecturer-managed registers and online-class presence. Existing compatible hardware is the preferred starting point, but compatibility is not assumed.

A reader or gateway submits evidence to a trusted integration gateway over an authenticated encrypted channel. The gateway verifies device identity, signature, timestamp, college/device assignment and replay protection. A credential resolver maps a keyed card fingerprint or valid QR challenge to a student. Eligibility checks confirm active enrolment and class-group membership for the relevant session. The attendance engine records immutable source evidence and updates the derived register under college policy.

A tap proves a check-in event, not continuous attendance. A college may require a second tap, lecturer confirmation or other approved attendance rule.

Hardware pilot checklist: vendor, exact model, firmware, card technology/frequency, protocol, vendor software/API, authentication/encryption, event format, clock synchronisation, network/offline behaviour, duplicate semantics, licensing and support. NFC/RFID are technology families, not universal protocols; test the exact card-reader-software combination before promising compatibility.

Offline-capable campus gateways may buffer signed events and synchronise after reconnection. Events need stable source IDs, device IDs, event timestamps, sequence information where supported and signatures. Delayed events and clock drift must be visible. Devices never receive Supabase user credentials or direct database write permissions.

## 11. Security, privacy and data governance

### 11.1 Tenant isolation and relational integrity

- Every college-owned row has a non-null tenant identifier (`college_id`).
- Enable and verify RLS on every exposed tenant table.
- Derive access from trusted memberships, role grants and explicit assignments; never user-editable user_metadata.
- Students access only their own profile, applications, enrolments, groups, learning and attendance.
- Lecturers/assistants access only assigned groups/sessions and minimum necessary student fields.
- Attendance officers receive only their authorised register/device scope.
- College administrators are restricted to their own tenant.
- Platform operators receive no standing access to tenant content.

Use composite tenant-aware foreign keys so a row cannot reference a parent in another college or offering. The academic SQL draft identifies prerequisites that must be reconciled before use:
- Add/verify `UNIQUE(college_id, id)` on `courses` before the composite course-offering FK.
- Add/verify `UNIQUE(college_id, id)` on `college_memberships` before a tenant-safe membership reference, and use a composite FK from staff assignment to membership.
- Preserve the three-column integrity tying group enrolment to the same college, group and course offering.
- Review unique student-number scope and whether course offerings can span campuses before finalising DDL.

### 11.2 RLS and privileged operations

RLS policy design must specify SELECT, INSERT, UPDATE and DELETE separately. UPDATE requires an appropriate SELECT policy and both USING and WITH CHECK predicates to prevent moving rows across tenants or scopes. Do not treat `TO authenticated` alone as sufficient authorisation.

Use server-side, atomic, idempotent operations for invitation acceptance, role changes, registrar activation, group allocation, attendance processing, exports and other privileged workflows. Students cannot self-activate enrolments or allocate themselves to groups. Lecturers cannot grant themselves group access. Devices cannot write directly to academic tables.

Prefer security-invoker behaviour. Any exceptional privileged database function needs a private/non-exposed schema, explicit caller checks, safe search path and restricted execute grants. Do not use privileged functions as a shortcut around RLS.

### 11.3 Storage, secrets and audit

- Keep application documents and learning resources in private storage.
- Issue short-lived, permission-checked download access; never public URLs for private records.
- Store provider credentials, card/QR signing keys and device secrets server-side; persist references/fingerprints rather than raw secrets.
- QR tokens are unpredictable, short-lived, session-bound, hashed at rest and rate-limited.
- Keep raw attendance evidence immutable and separate from derived register state.
- Audit consent changes, profile access where required, staff grants/revocations, applicant decisions, enrolment/group changes, attendance adjustments, exports, integration changes, billing changes and support sessions.
- Redact passwords, tokens, credentials and unnecessary personal data from logs.
- Define retention, deletion, correction, legal hold, access-request and incident-response processes.

### 11.4 POPIA governance

Before real student onboarding, document responsible-party/operator roles, lawful purpose, minimum necessary data, student notices, sharing grants, retention, data-subject rights, security safeguards, breach response, operator agreements and cross-border processing considerations. Marketing consent is separate from application processing. Obtain legal/privacy review; this architecture is not a compliance certification.

## 12. Billing, plans and entitlements

The previously discussed Starter (R999/month), Growth (R1,999/month) and Professional (R3,999/month) prices are indicative proposals only. They are not approved prices or live billing configuration.

Plans should be versioned and define included modules, limits, support tier, onboarding, overages and effective dates. Subscription states and payment/webhook transitions are server-controlled and idempotent. Usage metrics need explicit definitions, tenant attribution, deduplication, correction and audit. Do not meter or monetise student personal data itself.

Enforce entitlements server-side. Billing roles do not imply access to student records. A subscription lapse must follow agreed notice/grace rules and must not delete academic records.

## 13. Audit, observability and resilience

Audit records should be append-only to ordinary application roles and include server timestamp, actor, tenant context, action, target reference, result, reason/ticket and correlation ID. Sensitive payloads and secrets are redacted.

Operational monitoring should cover application/API availability, database health, authentication/email delivery, storage uploads, background queue depth/retries, integration health, attendance gateway connectivity, backup success, restore-test evidence, errors and deployment status. Define alert thresholds, on-call ownership, backup/restore objectives and disaster recovery procedures before production.

## 14. Migration and implementation readiness

The current migration history does not capture the original nine-table baseline; a live index was also observed outside the listed migration history. Before any production DDL:
1. Inventory the current live schema, constraints, indexes, grants, RLS policies, triggers and functions.
2. Reconcile the original baseline and migration history into a reproducible, reviewed state.
3. Resolve role governance and membership lifecycle design.
4. Finalise composite tenant keys and foreign-key integrity.
5. Finalise unresolved academic decisions (multi-campus offering model, student-number uniqueness, offering-level lecturer assignment and lifecycle rules).
6. Produce RLS policies and grants for every table/operation.
7. Write cross-tenant, student, staff, registrar, attendance and platform security tests.
8. Review advisors, query/index plans, privacy and rollback/restore strategy.
9. Obtain explicit approval before applying migrations or changing production data.

Existing schema observations and draft SQL are not permission to execute the draft. No database changes are included in this work.

## 15. Phased delivery roadmap

### Phase 0 — Foundation and governance
- Reconcile database baseline and migration history.
- Approve tenant model, role/capability catalogue and platform governance.
- Confirm first pilot college and its existing/full/hybrid mode.
- Confirm data ownership, privacy notices, consent language and integration authorisation.

### Phase 1 — Secure identity and admissions
- Production-ready student authentication and profile.
- Purpose-specific consent and college-scoped applications.
- Secure tenant context, staff invitations and role grants.
- Admissions workspace and integration hand-off/sync for the pilot.
- Audit and private document access.

### Phase 2 — College administration and registration
- Campuses, academic terms, course offerings.
- Registrar workflow and course enrolments.
- Multiple class-group allocation and scoped teaching assignments.
- Timetable and class sessions.

### Phase 3 — Learning delivery
- Course modules, lessons, private resources and progress.
- Online classroom provider integration.
- College-managed teaching workflows and optional separately governed Ekhaya delivery support.

### Phase 4 — Attendance
- Manual register and QR pilot.
- Exact existing hardware compatibility assessment.
- Gateway/device identity, immutable events, derived register and correction workflow.
- Offline buffering and operational health monitoring.

### Phase 5 — Platform operations and commercial services
- Platform control plane and tenant lifecycle.
- Subscription billing, entitlements and usage.
- Connector catalogue, support access governance, security operations and service health.
- Reports, exports, retention and closure workflows.

Each phase requires acceptance tests, accessibility checks, security review, operational readiness and explicit release approval before real student data is used.

## 16. Open decisions register

1. Confirm first pilot college and operating mode.
2. Confirm whether a course offering may span multiple campuses or must belong to one campus.
3. Confirm whether student numbers are unique per college, campus, academic year or another scope.
4. Confirm whether lecturers need offering-level assignments in addition to class-group assignments.
5. Confirm staff invitation and role approval authorities, including the initial and subsequent college administrators.
6. Confirm exact integration systems and written authorisations for the pilot.
7. Confirm document and attendance retention periods and student-rights workflows.
8. Confirm attendance rules for late, absent, excused, check-out and online presence.
9. Confirm exact reader/card combinations and whether the vendor provides a supported API/gateway.
10. Approve platform operator identities, MFA, support access approvers and emergency access process.
11. Approve plan prices, usage metrics, billing provider and grace/suspension policy.
12. Confirm service-level, backup, recovery and incident response targets.

## 17. Source specifications

This master document consolidates, but does not replace, the more detailed specifications:

- [CampusConnect project README and prototype status](../README.md)
- [Academic Structure Foundation](academic-structure-foundation.md)
- [Academic Structure Schema Draft — design only](academic-structure-schema-draft.sql)
- [Learning and Attendance Foundation](attendance-learning-foundation.md)
- [Learning and Attendance Schema Draft — design only](attendance-learning-schema-draft.sql)
- [Staff Governance and Permissions](staff-governance-and-permissions.md)
- [College Administration Workspace Specification](college-administration-workspace.md)
- [Platform Super Admin Workspace Specification](platform-super-admin-workspace.md)

## 18. Implementation boundary

This document is a consolidated architecture proposal. It does not mean the described student, college, platform-admin, LMS, attendance, integration, billing or security workflows are implemented. The current website remains a front-end demonstration; only the account page has the previously documented Supabase Auth/profile integration. Do not enter real student personal information into demo workflows. No Supabase tables, policies, migrations, production roles, integrations or billing configuration were created or changed as part of this architecture work.


## Expanded platform scope

The seven-area product expansion and the inspection-based foundation gap assessment are consolidated in [Expanded Platform Architecture and Foundation Gap Assessment](expanded-platform-architecture-and-gap-assessment.md). That document extends this master architecture without replacing the existing college modes, academic structure, multi-group allocation, learning governance, attendance or tenant-isolation decisions.
