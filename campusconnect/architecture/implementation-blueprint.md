# CampusConnect — Implementation Blueprint

**Status:** Execution plan derived from the current CampusConnect README and architecture specifications. This is a planning document, not a production implementation or approval to change the database. No Supabase changes are made by this document.

## 1. Purpose and execution rules

This blueprint converts the master architecture into an ordered, testable delivery plan. It is the working source for sequencing engineering tasks, recording implementation status and deciding when a module is ready to move forward.

### Non-negotiable execution rules

1. Keep the product multi-college from the first production release, even when the first pilot is one college.
2. Preserve the three operating modes: existing portal, full portal and hybrid. Record system-of-record ownership per workflow/domain.
3. Keep global student identity separate from college-scoped applications, enrolments, academic records and notes.
4. Enforce tenant, role, capability, consent and assignment checks in server/database layers, not just the UI.
5. College-controlled teaching is the default. CampusConnect supplies the learning and classroom technology; colleges approve lecturers, content, assessments, marking and academic outcomes.
6. A course enrolment can belong to multiple class groups in the same course offering through the many-to-many `class_group_enrolments` relationship.
7. Devices and external connectors never write directly to public database tables.
8. Keep private documents/resources in protected storage; never use public URLs for confidential records.
9. Keep billing entitlements separate from database authorisation and RLS.
10. Do not use real student information in the current localStorage prototype.
11. Do not deploy database changes until the live baseline, RLS plan, tests, rollback plan and explicit approval are complete.
12. Do not mark a task complete merely because a design, screen mock-up or localStorage demonstration exists.

## 2. Current baseline and verified implementation status

### 2.1 Current prototype

The repository README records the following demonstration features:
- Responsive course finder with province and study-mode filters.
- Student enquiry/application form with application-sharing consent and separate optional marketing consent.
- Demo application list and college admissions dashboard.
- Applicant search, status pipeline and CSV export.
- Campus appointment queue demonstration.
- Ekhaya platform institution directory and portal-mode configuration.
- Indicative subscription display.
- Student account page connected to Supabase Auth and the student profile table for registration, email verification redirects, sign-in, password reset, sign-out and own-profile editing.

### 2.2 Limitations that must remain visible

The README states that demo applications, college workspace and platform administration use browser localStorage. The course finder and application submission are not production application routing. There is no production college tenant access, messaging, document upload, payment processing or queue service. The account page's Supabase connection is limited to Auth and the profile table. Production SMTP must be configured before real invitations.

Therefore:
- Existing screens are prototype references, not proof of backend functionality.
- Demo application status is not an official admission decision.
- Demo registration is not official college registration.
- Demo tenant settings are not secure tenant configuration.
- No confidential student records should be entered into the demo.

### 2.3 Existing backend baseline

The dedicated Supabase project has previously been inspected with nine public tables: `colleges`, `college_memberships`, `student_profiles`, `courses`, `student_consents`, `applications`, `application_documents`, `audit_events`, and `college_registration_requests`. RLS was reported enabled on inspected tables. The current membership role constraint was observed to allow `college_admin`, `admissions_staff` and `registrar`.

The migration history did not capture the original nine-table baseline. Reconcile the live schema and migration history before production DDL. Re-inspect the live state immediately before implementation; historical observations are not a substitute for a current inventory.

## 3. Delivery model and status vocabulary

Use these statuses consistently in GitHub issues/project board and release notes:

| Status | Meaning |
|---|---|
| Not started | No implementation work has begun |
| Designed | Requirements/architecture documented; no working implementation |
| In progress | Code or configuration work underway |
| Implemented — unverified | Code exists but required tests have not passed |
| Verified in test | Acceptance/security tests passed in a controlled test environment |
| Pilot ready | Operational, privacy, support and rollback checks passed for a named pilot |
| Production live | Explicitly released and verified in production |
| Blocked | A named dependency or decision prevents progress |
| Deferred | Deliberately moved to a later phase |

A PR merged is not equivalent to production live. A database table existing is not equivalent to secure access. A screen rendering is not equivalent to a completed workflow.

## 4. Workstreams and dependency map

| Workstream | Depends on | Primary output |
|---|---|---|
| A. Product and pilot decisions | Architecture review | Approved pilot scope and system-of-record map |
| B. Backend baseline and security | A | Reconciled schema, migration baseline, RLS/capability plan |
| C. Identity and access | B | Secure student/staff/platform identities and tenant context |
| D. Student admissions | C | Consent-led applications and college admissions workflow |
| E. College administration | B, C | Staff, course catalogue, campuses, terms and administration |
| F. Registration and academic structure | D, E | Registrar-approved enrolments and multiple group allocations |
| G. Student experience | C, D, F | Student dashboard, application tracking and academic access |
| H. Integrations and communications | C, D, E | Approved connectors, notifications and reconciliation |
| I. Learning delivery | F, G | LMS modules, lessons, resources and classroom sessions |
| J. Attendance | F, I, hardware assessment | Secure attendance evidence and register |
| K. Platform control plane | B, C | Tenant governance, platform roles, support and audit |
| L. Billing and operations | K | Plans, entitlements, metering, monitoring and support operations |

The workstreams may be developed in parallel only where dependencies are satisfied. Security design and test planning run throughout.

## 5. Phase 0 — Product decisions and pilot readiness

**Goal:** Confirm exactly what the first college pilot will own and what CampusConnect will do.

### Tasks

- [ ] Confirm the first pilot college and authorised project contact.
- [ ] Confirm its mode: existing portal, full portal or hybrid.
- [ ] Create a domain-by-domain system-of-record matrix: course catalogue, enquiry, application, admission decision, offer, fee, registration, enrolment, timetable, learning and attendance.
- [ ] Confirm official course, qualification, intake, campus and entry-requirement data with the college.
- [ ] Confirm admissions stages, required documents, decision authorities and escalation path.
- [ ] Confirm which staff roles are needed for the pilot.
- [ ] Confirm the first pilot's student-facing scope and support process.
- [ ] Confirm written authorisation for each external system/API/file exchange.
- [ ] Identify responsible-party/operator roles, privacy contact and legal review owner.
- [ ] Define pilot success measures and support hours.

### Exit criteria

- Named pilot and authorised college contact.
- Signed-off operating mode and system-of-record matrix.
- Approved course/intake data source.
- Admissions workflow and responsible roles agreed.
- Integration permissions documented.
- Privacy/legal review path identified.

### Blockers if not completed

Do not build production integration logic against assumed portal ownership, scrape external portals, publish unapproved college content or treat prototype course data as official.

## 6. Phase 1 — Backend baseline, tenant security and migration readiness

**Goal:** Establish a reproducible and secure foundation before adding production workflows.

### Tasks

- [ ] Re-inspect the dedicated CampusConnect Supabase project and confirm project reference/environment.
- [ ] Inventory tables, columns, data types, primary/unique/foreign keys, check constraints, indexes, triggers, functions, grants, storage buckets, RLS enablement and policies.
- [ ] Reconcile the original nine-table schema baseline with the three recorded migrations and any live objects missing from migration history.
- [ ] Produce a reviewed baseline migration or documented reconciliation approach.
- [ ] Define the authoritative tenant key as `college_id` for college-owned data and document naming conventions.
- [ ] Define global student identity versus tenant-owned records.
- [ ] Define staff membership lifecycle and verified invitation flow.
- [ ] Define role catalogue and capability map; do not merely expand the existing role CHECK.
- [ ] Define platform roles separately from college roles.
- [ ] Specify SELECT/INSERT/UPDATE/DELETE policies per table and operation.
- [ ] Specify UPDATE SELECT visibility, USING and WITH CHECK conditions.
- [ ] Specify private storage bucket access and short-lived file access.
- [ ] Define append-only audit requirements and sensitive-data redaction.
- [ ] Add cross-tenant and role-negative tests before feature development.
- [ ] Run schema/security advisors and review query/index requirements.
- [ ] Prepare backup, restore test and rollback plan.

### Required integrity constraints to validate

- Composite tenant keys for every parent/child relationship where cross-college references are possible.
- `courses` needs `UNIQUE(college_id, id)` before the proposed composite course-offering foreign key.
- `college_memberships` needs `UNIQUE(college_id, id)` before tenant-safe staff assignment references; staff assignment must use a composite FK including college_id.
- Group enrolment must enforce same college and same course offering for both the group and enrolment.
- Review uniqueness scope for student numbers.
- Confirm whether a course offering belongs to exactly one campus or may span multiple campuses.

### Exit criteria

- Current schema inventory reviewed and version-controlled.
- Migration baseline reproducible and reviewed.
- Role/capability catalogue approved.
- Table-level RLS matrix complete.
- Cross-tenant negative tests pass in a non-production test environment.
- Rollback and restore procedure tested.
- Explicit approval obtained before any schema deployment.

### Deployment gate

No production database changes until the user explicitly approves a specific reviewed migration plan. This blueprint itself does not authorise deployment.

## 7. Phase 2 — Identity, membership and access foundation

**Goal:** Securely identify students, college staff and platform operators, and resolve access scope.

### Student identity

- [ ] Verify student registration and email confirmation.
- [ ] Verify sign-in, sign-out and password reset redirects.
- [ ] Confirm profile bootstrap and own-profile update policies.
- [ ] Validate profile fields and minimise sensitive information.
- [ ] Implement account recovery and session handling.
- [ ] Provide student privacy notice and account/data-rights contact.

### College staff identity

- [ ] Create staff invitation workflow with high-entropy single-use token.
- [ ] Store only token hash; enforce expiry, cancellation and reissue.
- [ ] Verify invited email before accepting.
- [ ] Create/activate membership only through trusted server operation.
- [ ] Support one membership per user per college and multiple approved role grants.
- [ ] Add membership states (invited, active, suspended, revoked or equivalent approved lifecycle).
- [ ] Require second approval for elevated college administrator grants.
- [ ] Support role revocation and session/access invalidation.

### Platform identity

- [ ] Define individual platform operator accounts.
- [ ] Require MFA/strong authentication for privileged platform roles.
- [ ] Separate platform role grants from college memberships.
- [ ] Add requester/approver separation and access reviews.
- [ ] Define time-limited break-glass procedure.

### Tenant context

- [ ] Resolve active college membership server-side.
- [ ] Allow switching only among the user's active memberships.
- [ ] Clear tenant-scoped client state when switching.
- [ ] Reject forged tenant IDs in requests.
- [ ] Verify tenant scope again in server/data layer.

### Exit criteria

- Student, staff and platform identity tests pass.
- No public self-assignment to staff/platform roles.
- Cross-tenant access attempts fail.
- Revoked/suspended membership loses access.
- Invitation replay, expiry and wrong-email tests pass.
- Platform operator cannot access tenant content by default.

## 8. Phase 3 — College administration foundation

**Goal:** Provide the college's secure operational workspace.

### Navigation and shell

- [ ] Active college context and tenant switcher.
- [ ] Capability-filtered navigation.
- [ ] Overview dashboard with permission-scoped aggregates.
- [ ] Loading, empty, error and permission-denied states.
- [ ] Accessible responsive layout.

### College setup

- [ ] College profile and approved branding.
- [ ] Operating mode and module ownership.
- [ ] Public profile and publication approval.
- [ ] Timezone and locale settings.
- [ ] Privacy and consent configuration.
- [ ] Onboarding readiness checklist.

### Staff & Access

- [ ] Staff directory.
- [ ] Invitations and acceptance status.
- [ ] Multiple role grants.
- [ ] Teaching assignments.
- [ ] Membership suspension/revocation.
- [ ] Access history and audit view.

### Academic configuration

- [ ] Campuses and physical/virtual type.
- [ ] Academic terms and registration windows.
- [ ] Course catalogue management.
- [ ] Course offerings by term, mode and campus.
- [ ] Offering publication/enrolment lifecycle.
- [ ] Validate dates, capacities and archival rules.

### Exit criteria

- College A cannot see College B settings or staff.
- Staff cannot grant themselves elevated roles.
- Course catalogue and offering are distinct.
- Campus and term changes are audited.
- Public course discovery exposes only approved published data.

## 9. Phase 4 — Admissions and student application workflow

**Goal:** Replace localStorage demo application handling with secure, college-scoped workflows.

### Student-side tasks

- [ ] Course discovery uses approved college/course data.
- [ ] Course details show verified requirements and intake information.
- [ ] Student selects a college and intended course/intake.
- [ ] Application sharing purpose and recipient are explicit.
- [ ] Marketing consent remains separate and optional.
- [ ] Student can review submitted information and track status.
- [ ] Student can respond to requests for more information.
- [ ] Application withdrawal/correction follows policy.

### College-side tasks

- [ ] Admissions pipeline with configured state machine.
- [ ] Applicant case view with minimum necessary information.
- [ ] Assignment to admissions staff.
- [ ] Contact attempts, tasks and follow-up dates.
- [ ] Missing-information request workflow.
- [ ] Decision workflow with authorised roles.
- [ ] Application status event history.
- [ ] Safe exports with capability checks and audit.
- [ ] Distinguish CampusConnect lead/application state from external official portal status.

### Documents

- [ ] Define document checklist and allowed file types/limits.
- [ ] Upload only to private storage.
- [ ] Enforce applicant/college role access.
- [ ] Use short-lived authorised downloads.
- [ ] Audit views/downloads where required.
- [ ] Define retention and deletion workflow.

### Exit criteria

- A student can submit only for an explicitly selected college.
- College A cannot read College B applications.
- Marketing consent is independent from application processing.
- Unauthorised staff cannot make admissions decisions.
- Application transitions are validated and audited.
- Private documents cannot be fetched by guessing object paths.
- Existing-portal mode records hand-off/sync accurately without claiming official registration.

## 10. Phase 5 — Registrar, enrolment and multiple class groups

**Goal:** Separate admissions acceptance from formal academic registration.

### Tasks

- [ ] Define registration requirements and evidence.
- [ ] Confirm accepted application or authorised external registration event.
- [ ] Create registrar-only trusted activation operation.
- [ ] Make registration operation idempotent.
- [ ] Create course enrolment against a specific course offering.
- [ ] Preserve source application or external registration reference.
- [ ] Define student-number uniqueness and lifecycle.
- [ ] Create class groups under an offering.
- [ ] Assign one enrolment to multiple groups using `class_group_enrolments`.
- [ ] Enforce group and enrolment belong to the same college and same offering.
- [ ] Preserve ended/revoked group allocation history.
- [ ] Add lecturer/TA group assignments.
- [ ] Enforce eligible staff role and assignment scope.

### Exit criteria

- Student cannot self-activate enrolment.
- Admissions staff cannot activate enrolment unless explicitly delegated.
- Registrar can create/activate authorised enrolment.
- One enrolment can belong to lecture and tutorial groups in the same offering.
- Cross-offering and cross-college allocations fail at database and API layers.
- Repeated registration requests do not create duplicates.
- Changes are audited.

## 11. Phase 6 — Student workspace and timetable

**Goal:** Give each student a useful view of their own academic relationship with each college.

### Tasks

- [ ] Student dashboard with selected college context.
- [ ] Application status and next action.
- [ ] Offers/registration checklist where enabled.
- [ ] Enrolments and student number.
- [ ] Multiple class-group memberships.
- [ ] Timetable by eligible class session.
- [ ] Campus timezone display.
- [ ] Private learning resources when enabled.
- [ ] Attendance summary when enabled.
- [ ] Student notices and communication preferences.

### Exit criteria

- Student sees only own applications, enrolments, groups and sessions.
- Student can belong to multiple groups in one offering.
- Cancelled sessions do not appear as active attendance obligations.
- Tenant switching does not leak cached data.
- Timetable uses relevant campus timezone.

## 12. Phase 7 — Integrations and communications

**Goal:** Connect approved college systems and communications providers safely.

### Integration foundation

- [ ] Connector registry and version.
- [ ] Tenant-specific connection and permitted scopes.
- [ ] Written authorisation evidence and owner.
- [ ] Server-side secret reference and rotation.
- [ ] Signed webhook verification.
- [ ] Replay protection and idempotency.
- [ ] Durable sync queue and retry/dead-letter handling.
- [ ] Status mapping and field mapping versions.
- [ ] Manual reconciliation and audit history.
- [ ] Pause/revoke controls.
- [ ] Redacted diagnostics and support access.

### Communications

- [ ] Transactional email provider and verified sender.
- [ ] Email templates for verification, application receipt and status updates.
- [ ] Optional SMS/WhatsApp only after provider, consent, cost and opt-out rules are approved.
- [ ] Queue-based sending with retries and delivery status.
- [ ] Avoid exposing sensitive application details in notifications.

### Exit criteria

- Integration events are tenant-bound, signed and idempotent.
- Failed sync is visible and recoverable.
- No portal automation without written authorisation.
- Credentials never reach browser responses or audit logs.
- Notification preferences and legal basis are respected.

## 13. Phase 8 — Learning management and online classroom

**Goal:** Deliver college-managed learning technology without taking academic authority away from the college.

### Tasks

- [ ] Course modules and lesson ordering.
- [ ] Lesson types: live, recorded, reading, activity.
- [ ] Draft/published/archived states.
- [ ] Private lesson resource storage.
- [ ] Student lesson access based on active enrolment and group/session scope.
- [ ] Learning progress records.
- [ ] Online classroom provider adapter.
- [ ] Session meeting references and protected join links.
- [ ] Assessment definitions and submission workflow only after grading/academic rules are approved.
- [ ] Lecturer/TA marking permissions and audit.
- [ ] College control of marks and academic outcomes.

### Exit criteria

- Unenrolled students cannot access protected learning resources.
- Lecturer/TA sees only assigned offerings/groups.
- Provider secrets are not exposed in browser-readable data.
- College retains authority over content, assessment and outcomes.
- Resource access and key academic changes are auditable.

## 14. Phase 9 — Attendance and reader hardware

**Goal:** Implement attendance as a secure evidence-processing service.

### Start with low-complexity methods

- [ ] Manual lecturer register with scoped session roster.
- [ ] QR attendance challenge generation, expiry, hashing and replay controls.
- [ ] Attendance policy for present, late, absent, excused and pending review.
- [ ] Append-only attendance adjustments.

### Hardware assessment and gateway

- [ ] Inventory exact reader/card models at pilot campus.
- [ ] Confirm vendor API or documented local protocol.
- [ ] Confirm card technology/frequency and whether UID handling can be safely fingerprinted.
- [ ] Build adapter interface for vendor cloud, local gateway or approved event feed.
- [ ] Authenticate devices and sign event batches.
- [ ] Validate timestamp, college/device assignment and replay.
- [ ] Resolve credential to current student-card assignment.
- [ ] Confirm active course enrolment and class-group eligibility.
- [ ] Store immutable device evidence with idempotency key.
- [ ] Update derived attendance record under college policy.
- [ ] Add offline buffering, sequence checks, clock-drift reporting and secure sync.
- [ ] Add device health and revocation controls.

### Exit criteria

- Devices cannot connect directly to database tables.
- Duplicate/replayed taps do not create duplicate attendance.
- A device from College A cannot submit for College B.
- Student is eligible for the session at event time.
- Cancelled sessions do not generate absences.
- Corrections preserve original evidence and reason.
- Exact hardware combination has passed a campus pilot before support is promised.

## 15. Phase 10 — Platform control plane

**Goal:** Give Ekhaya Technologies secure platform operations without unrestricted student-data access.

### MVP tasks

- [ ] Platform operator identity and MFA.
- [ ] Platform role/capability catalogue.
- [ ] College registration review queue.
- [ ] Tenant create/activate/suspend workflow.
- [ ] Initial college admin invitation.
- [ ] Tenant directory and metadata-only detail.
- [ ] Platform audit events and access reviews.
- [ ] Platform service configuration and maintenance notices.

### Later tasks

- [ ] Versioned plans and subscriptions.
- [ ] Usage metering and billing reconciliation.
- [ ] Connector catalogue and health.
- [ ] Support tickets and approved time-limited support access.
- [ ] Security incidents and service health.
- [ ] Tenant export/retention/closure process.

### Exit criteria

- College admin cannot access platform admin APIs.
- Billing admin cannot read student records.
- Support access requires approval, is scoped and expires.
- Platform operator cannot self-grant elevated roles.
- Tenant suspension never automatically deletes academic data.
- Platform dashboard defaults to aggregates and metadata.

## 16. Phase 11 — Billing, entitlements and commercial operations

**Goal:** Introduce commercial controls only after tenant and module boundaries are stable.

### Tasks

- [ ] Approve commercial prices and plan catalogue.
- [ ] Define included modules, usage limits and support tiers.
- [ ] Define billing provider and payment reconciliation.
- [ ] Implement idempotent webhook processing.
- [ ] Define trial, active, past-due, grace, suspended and cancelled states.
- [ ] Implement server-side entitlement checks.
- [ ] Define metering event and correction model.
- [ ] Define invoices, credits, refunds and approval workflow.
- [ ] Define non-payment notice and read-only/grace policy.
- [ ] Ensure subscription status never overrides RLS or causes data deletion.

### Exit criteria

- Client cannot manipulate plan or entitlement state.
- Replayed payment webhooks do not duplicate billing records.
- Billing role has no implied student-data access.
- Pricing and usage terms are approved and versioned.
- Tenant data remains protected and export/retention terms are honoured.

## 17. Cross-cutting quality gates

Every phase must pass the following relevant gates before release.

### Security

- [ ] Cross-tenant tests for all CRUD operations.
- [ ] Student own-row and own-relationship tests.
- [ ] Staff role and assignment-scope tests.
- [ ] Negative tests for forged tenant IDs and client-side role changes.
- [ ] UPDATE tests include SELECT visibility, USING and WITH CHECK.
- [ ] Private storage access tests.
- [ ] Invitation/token expiry and replay tests.
- [ ] Secret redaction and audit immutability checks.
- [ ] Dependency and vulnerability review.

### Privacy and governance

- [ ] Purpose and lawful basis documented.
- [ ] Data minimisation and retention defined.
- [ ] Consent and marketing preferences are separate.
- [ ] Student rights and correction processes documented.
- [ ] Operator agreements and support access rules reviewed.
- [ ] No production student data in demo/localStorage.

### Reliability and operations

- [ ] Idempotency and retry tests.
- [ ] Error states and recovery procedures.
- [ ] Backup and restore evidence.
- [ ] Monitoring and alert ownership.
- [ ] Queue/dead-letter operations where applicable.
- [ ] Incident response and rollback runbook.

### User experience

- [ ] Mobile and desktop layout.
- [ ] Keyboard navigation and visible focus.
- [ ] Accessible labels and status announcements.
- [ ] Loading, empty, error and permission-denied states.
- [ ] Low-bandwidth usability.
- [ ] Campus-local date/time presentation.

## 18. Initial end-to-end pilot acceptance scenario

The first pilot should demonstrate this complete journey using synthetic test identities and approved college data:

1. College is approved and its tenant is provisioned.
2. Initial college administrator accepts verified invitation.
3. Administrator configures campus, academic term, course and course offering.
4. Student creates an account and confirms email.
5. Student discovers the approved offering and submits an application to the selected college.
6. College admissions staff reviews the application and records an authorised decision.
7. Registrar verifies registration evidence and activates the course enrolment.
8. Registrar assigns the student to Lecture Group A and Tutorial Group C.
9. Lecturer assigned to Lecture Group A sees only that group's roster and session.
10. Student sees their own enrolment, both group memberships and eligible timetable.
11. Student accesses only permitted learning resources.
12. Attendance is recorded for an eligible session using manual register or QR.
13. Student sees their own attendance; unauthorised staff and other colleges cannot.
14. Audit records capture key transitions and access events.
15. College can export only the records permitted to the requesting role.
16. Platform support sees metadata only unless an approved support session is active.

For an existing-portal pilot, replace steps 6–7 with an authorised hand-off/synchronisation and verified external registration evidence. Do not claim CampusConnect is the official system of record where the college portal remains authoritative.

## 19. Immediate next engineering tickets

Create these as the first execution backlog, in order:

| ID | Ticket | Deliverable | Dependency |
|---|---|---|---|
| CC-001 | Confirm pilot scope and operating mode | Signed-off pilot scope and system-of-record matrix | College decision |
| CC-002 | Re-inventory Supabase baseline | Schema/policy/trigger/grant inventory report | CC-001 |
| CC-003 | Reconcile migration baseline | Reviewed reproducible baseline plan | CC-002 |
| CC-004 | Approve college role/capability catalogue | Role definitions and permission matrix | CC-001 |
| CC-005 | Complete table-level RLS matrix | CRUD policy specification and negative tests | CC-002, CC-004 |
| CC-006 | Define platform role governance | Platform role grants, MFA and separation-of-duties rules | CC-004 |
| CC-007 | Define storage and audit controls | Private bucket matrix and audit event catalogue | CC-005 |
| CC-008 | Approve first college course/intake data | Verified catalogue and entry requirements | CC-001 |
| CC-009 | Define admissions state machine | Statuses, transitions, authorities and hand-off states | CC-001 |
| CC-010 | Build identity/access test plan | Student, staff, platform and tenant test cases | CC-004–CC-006 |

Do not begin production schema deployment from these ticket descriptions alone. Each implementation ticket must include acceptance tests, code review and a specific release/deployment approval.

## 20. Decisions required before implementation can safely proceed

1. Which college is the first pilot, and is it existing portal, full portal or hybrid?
2. Which official course/intake data and authorised integration can the pilot provide?
3. Who will hold the first college administrator and platform owner roles? Use individual accounts, not shared credentials.
4. Does an offering belong to one campus or may it span campuses?
5. What is the student-number uniqueness scope?
6. Which roles may issue offers, approve admissions and activate registration?
7. What document and attendance retention periods should apply?
8. Which attendance methods and exact reader hardware are available at the pilot?
9. Which subscription prices and billing provider are approved? The previously discussed amounts remain proposals only.

## 21. Implementation boundary

This blueprint records the intended execution sequence and acceptance criteria. It does not claim that the planned modules are implemented. The current prototype limitations remain as documented in the project README. No Supabase tables, policies, migrations, production roles, integrations, billing configuration or production deployments were created or changed as part of this blueprint.
