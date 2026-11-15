# CampusConnect College Administration Workspace — Product and Workflow Specification

**Status:** Product/UX architecture only. This document does not create database objects, RLS policies, migrations, UI code or production workflows.

## 1. Purpose and product boundary

The College Administration Workspace is the operational control centre for each college tenant. It lets authorised college staff configure their institution, manage academic delivery and oversee students and staff within that college.

CampusConnect has three operating modes:
- **Existing portal / integration mode:** CampusConnect handles discovery, enquiries, consent-led applications, admissions follow-up and authorised hand-off/status synchronisation. The college's existing system remains the system of record for official applications, admission decisions, fees and registration unless a separately approved integration agreement says otherwise.
- **Full portal mode:** CampusConnect provides the institution's application and admissions workspace, protected document workflow, offers and registrar-approved registration.
- **Hybrid mode:** the college enables selected CampusConnect modules while retaining other processes in its existing system.

The workspace must display the college's configured operating mode and clearly identify which system owns each record or action. Do not show a CampusConnect action as completed in an external college portal unless an authorised API response or verified staff hand-off confirms it.

## 2. Workspace entry and tenant context

After authentication:
1. Resolve the user's active college memberships from trusted server-side records.
2. If the user belongs to one college, open that college workspace.
3. If the user belongs to multiple colleges, show a college switcher with only their active memberships.
4. If there is no active college membership, show the student workspace (if applicable), pending invitation state, or a neutral access-denied/help state. Never infer staff access from signup metadata.
5. Suspended colleges and suspended/revoked memberships cannot enter operational workspaces.

Every page must keep the active college context visible. Changing college context must refresh data and permissions, not merely change a label. Deep links must re-check access on the server.

## 3. Navigation structure

### Primary navigation
- Overview
- Admissions
- Students
- Academic Management
- Staff & Access
- Integrations
- Reports
- College Settings
- Billing & Plan (where enabled)

### Academic Management sub-navigation
- Campuses
- Academic Terms
- Courses & Offerings
- Class Groups
- Timetable & Sessions
- Enrolments
- Learning Delivery (future module)
- Attendance (future module)

Menu items are permission-filtered, but hiding a menu item is not a security control. Every API and database operation must independently enforce tenant and capability checks.

## 4. Overview dashboard

The overview is an operational summary, not a source of unrestricted student data. Show aggregate metrics scoped to the active college and the user's permissions:
- New enquiries and applications in selected date range.
- Applications awaiting review and more-information requests.
- Offers awaiting response (where the module is enabled).
- Registration tasks awaiting registrar action.
- Active offerings, class groups and sessions.
- Staff invitations awaiting acceptance.
- Integration health and unresolved sync exceptions.
- Subscription/usage notices for authorised billing users.

Dashboard cards link to the relevant filtered work queue. Suppress metrics and records the current user is not authorised to view. Use date range, academic term and campus filters only where those dimensions exist.

## 5. College onboarding and setup

### 5.1 Platform-controlled onboarding
- A prospective college submits a registration request.
- Platform operations verify the organisation, authorised representative and requested operating mode.
- Platform approves, declines or requests more information; every decision is audited.
- Platform creates the tenant and provisions the initial college administrator through a controlled invitation.
- The initial administrator accepts the invitation and verifies their account before accessing the workspace.
- The college is not publicly searchable as an active institution until its status and public profile are approved.

### 5.2 First-run setup checklist
Display a guided checklist with completion state and responsible role:
1. Confirm institution name, legal/contact details and public profile.
2. Select/confirm existing, full or hybrid operating mode.
3. Add campuses and timezone.
4. Configure academic year/terms and registration dates.
5. Review/import course catalogue and entry requirements.
6. Create course offerings and delivery modes.
7. Invite staff and assign approved roles.
8. Configure application workflow and required documents.
9. Configure authorised integrations (if applicable).
10. Review privacy notice, consent wording, retention and support contacts.
11. Run a test application and verify the relevant hand-off/registration process.
12. Confirm readiness for student onboarding.

Do not block all setup on optional modules such as attendance hardware or online classrooms. Show dependencies and readiness clearly.

## 6. College profile and settings

Settings sections:
- Institution identity: display name, legal name, approved logo/brand assets, slug and contact details.
- Public profile: approved description, website, contact channels and campuses.
- Operating mode: existing/full/hybrid with explicit module ownership.
- Timezone and locale defaults; campus-specific timezone overrides.
- Application workflow: stages, required fields, document checklist, response targets and notification templates.
- Consent and privacy: purpose-specific sharing, marketing consent separation, retention and student rights contact.
- Integration settings: authorised system, scope, status, last successful sync and support contact.
- Notification preferences: email/SMS/WhatsApp provider configuration as enabled.
- Audit and data export controls for authorised roles.

High-impact changes (tenant status, operating mode, integration credentials, privacy/consent language and data exports) require appropriate capability, confirmation and audit. Never expose secrets in the browser after initial configuration.

## 7. Admissions workspace

### 7.1 Pipeline
A configurable board/list with defined stages, for example:
- New enquiry
- Contact attempted
- Application started
- Submitted
- Under review
- More information required
- Accepted
- Rejected
- Withdrawn
- Registered / handed off

The stages must map to the authoritative source for the college's operating mode. In integration mode, distinguish CampusConnect lead/application status from the official external portal status.

### 7.2 Applicant record
Display only fields necessary for the user's admissions task:
- Applicant identity and contact details.
- Selected course/intake and campus (where relevant).
- Consent record and purpose.
- Application status and event history.
- Required document checklist and protected document links.
- Assigned admissions owner and follow-up tasks.
- Communication history and appointment details, where enabled.

Do not place national ID numbers, sensitive documents or full academic records in broad list views, exports or dashboard cards. Use masked values and purpose-limited access.

### 7.3 Actions
- Assign/reassign an admissions case.
- Record contact attempt and next action.
- Request missing information with a clear checklist.
- Review submitted information and record an authorised decision.
- Issue an offer only if the college's configured workflow permits it.
- Route/hand off to the external system in integration mode.
- Record a verified external reference/status update.
- Escalate exceptions to registrar or integration support.

All status transitions must be validated against a configured state machine and logged with actor, timestamp, old/new state and reason where required. No client-side status field may bypass the workflow.

## 8. Student workspace for college staff

Provide search and filters appropriate to the staff role:
- Name/email or institution student number.
- Course offering, term, campus, class group and enrolment status.
- Application status and registration state.

Student profile sections:
- Basic profile (minimum necessary).
- College-specific applications.
- College-specific enrolments.
- Group allocations.
- Documents (permission-checked, private storage).
- Consent and data-sharing history relevant to the college.
- Support cases (only if assigned/authorised).
- Audit/access history for authorised compliance roles.

A college may only see student records shared with it through a valid consent or other documented lawful basis and permitted workflow. Student identity remains global; do not create duplicate college-owned copies of the global student profile. Separate global profile data from college-specific notes and records.

## 9. Academic Management

### 9.1 Campuses
College admin/authorised registrar can create and update campus records:
- Code, name, type (physical/virtual), timezone, address and active status.
- Avoid deleting a campus with historical offerings/sessions; archive or deactivate it.
- Validate campus belongs to active college context.

### 9.2 Academic terms
Registrar manages terms:
- Name, type (semester, trimester, quarter, year, custom).
- Start/end dates and registration opening/closing dates.
- Lifecycle: planned, open, active, completed, cancelled.
- Prevent invalid date ranges and unsafe edits after enrolment/assessment activity.
- Term closure is an audited action; historical results remain available under policy.

### 9.3 Courses and course offerings
Keep catalogue course separate from a course offering:
- Catalogue course describes the programme/qualification.
- Offering is a specific delivery instance in a term, delivery mode and optional campus.
- An offering has code, dates, capacity, status, course, term and delivery mode.
- Modes include campus, online, distance, correspondence and hybrid.
- Publishing a catalogue course does not automatically publish or open an offering.
- Existing-portal mode must not claim CampusConnect is the authoritative enrolment system unless configured integration ownership explicitly says so.

### 9.4 Class groups
Registrar or delegated authorised role creates groups under an offering:
- Lecture, tutorial, practical/lab or cohort groups.
- Group code/name, capacity (if used), status and effective dates.
- A student enrolment can belong to multiple groups within the same offering (e.g. lecture group and tutorial group).
- Group assignment is a separate operation from course enrolment.
- Prevent assignment to a group from another college or offering.
- Preserve ended/revoked allocation history; do not erase history to correct a mistake.

### 9.5 Timetable and class sessions
Create sessions for a class group:
- Session type, start/end, campus/room or online mode, attendance window and status.
- Detect timetable overlaps and warn; allow exceptions only with explicit authorised override and audit.
- Cancelled sessions must not generate absences.
- Meeting links and provider secrets are not exposed to unauthorised users.
- Student and lecturer calendars show only sessions they are eligible to access.

### 9.6 Enrolment operations
Registrar workflow:
1. Verify accepted application or authorised external registration evidence.
2. Confirm offering and registration requirements.
3. Create/activate the course enrolment through a trusted server operation.
4. Assign the student to one or more relevant class groups.
5. Notify the student and make timetable/learning access available.
6. Record any later suspension, transfer, completion or withdrawal as an audited transition.

An application status of accepted or registered does not automatically create a live enrolment unless the configured source-of-truth workflow confirms it. In existing-portal mode, CampusConnect may receive a synchronised registration event or store a verified reference; it must not silently duplicate the college's official registration.

## 10. Staff & Access workspace

Tabs:
- Staff directory
- Invitations
- Role grants
- Teaching assignments
- Access review / audit

Staff directory displays membership status, assigned roles, invitation/activation dates and permitted actions. Do not expose private invitation token values.

Actions:
- Invite staff member using verified email.
- Cancel/reissue pending invitation.
- Grant/revoke approved role (with required second approval).
- Suspend/reinstate membership.
- Assign lecturer/TA to one or more class groups.
- Review access history.

Rules:
- One membership per user per college; multiple role grants per membership.
- No public self-assignment to staff roles.
- Staff cannot grant themselves access or approve their own elevated grant.
- Teaching roles require group/offering assignments.
- Attendance officer scope must be explicit (campus/device/session).
- Revocation must invalidate access from all dependent assignments.
- Initial college admin is platform-provisioned; additional college admin grants use two-person approval.

## 11. Integrations workspace

For colleges with existing portals or external services:
- Integration directory and approved connector type.
- External system name, institution tenant, permitted data scopes and contract/authorisation status.
- Connection health, last successful sync, pending queue and failed events.
- Field mapping and status mapping versions.
- Manual hand-off/export history where APIs are unavailable.
- Retry/reconcile queue for idempotent sync events.

Security:
- Written authorisation and agreed data-sharing purpose before connection.
- API/webhook preferred; secure file exchange or staff-managed hand-off as fallback.
- Credentials stored server-side in a secret manager; never returned to browser.
- Signed webhooks, replay protection, idempotency and event audit.
- No portal scraping or automation without explicit written permission.
- Failures are visible and recoverable; do not silently mark records synchronised.

## 12. Reports and exports

Role-filtered reports may include:
- Enquiry-to-application conversion.
- Admissions pipeline ageing and outstanding tasks.
- Applications by course, term, campus and status.
- Registration and enrolment counts.
- Group capacity and allocation.
- Integration sync health and exceptions.
- Attendance and learning reports only when those modules are enabled and user is authorised.

Exports:
- Require explicit export capability and a reason where appropriate.
- Apply the same tenant, consent, row and field restrictions as on-screen views.
- Mask or omit sensitive identifiers by default.
- Record requester, filters, purpose, timestamp and export result.
- Use short-lived secure download links; do not create public file URLs.
- Avoid bulk exports for roles that only need case-level access.

## 13. Billing and subscription workspace

Display the college's current plan, billing contact, renewal state, usage and invoices only to authorised billing users. The earlier Starter/Growth/Professional prices are indicative proposals, not approved live pricing.

Plan entitlements should be enforced server-side and versioned. Do not make subscription status a substitute for RLS: a paid tenant still cannot access another tenant's data. Define grace periods, suspension rules, data export and retention before implementing non-payment restrictions. Never delete student or academic records automatically because a subscription lapses.

## 14. Permissions and page/action matrix

| Area/action | College admin | Admissions | Registrar | Lecturer | TA | Attendance officer |
|---|---|---|---|---|---|---|
| College profile/settings | Manage | None | Limited if delegated | None | None | None |
| Staff invitations/roles | Manage within approval rules | None | None | None | None | None |
| Course catalogue | Manage | Manage if delegated | Read/manage if delegated | Read assigned | Read assigned | None |
| Applications | Read/manage | Manage assigned cases | Limited registration context | None | None | None |
| Student profile | Minimum authorised view | Admissions scope | Registration scope | Assigned students, minimum fields | Assigned students, minimum fields | Register identity only |
| Terms/offerings | Manage | Read | Manage | Read assigned | Read assigned | Session context only |
| Enrolments/groups | Manage under policy | Read admissions status | Manage | Read assigned roster | Read delegated roster | Attendance eligibility only |
| Timetable/sessions | Manage | Read where relevant | Manage | Manage assigned | Limited assigned | Read assigned sessions |
| Attendance | Oversight under policy | None | Read/correct under policy | Assigned sessions | Delegated register | Assigned sessions/devices |
| Reports/export | Scoped | Case/admissions scope | Academic scope | Assigned classes | Delegated scope | Attendance scope |
| Billing | If designated | None | None | None | None | None |

This is a product-level target. Final capabilities and RLS policies must be specified per table, operation and field before implementation.

## 15. Audit, privacy and operational controls

Record privileged actions including:
- College profile and operating-mode changes.
- Course, term, offering, group and timetable changes.
- Staff invitations, role grants, approvals and revocations.
- Applicant status decisions and external hand-offs.
- Enrolment activation, group allocation, suspension and withdrawal.
- Student record access where required, document views/downloads and exports.
- Integration credential changes, sync retries and manual reconciliation.
- Billing plan and entitlement changes.

Use append-only event history for decisions and corrections. Apply least privilege, purpose limitation, retention schedules, student rights workflows, incident response and operator/college responsibility agreements. Obtain legal/privacy review before live student onboarding.

## 16. UX states and accessibility

Every list and workflow needs:
- Loading, empty, filtered-empty, error and permission-denied states.
- Clear confirmation for irreversible/high-impact actions.
- Undo or reversal workflow where safe; otherwise explain why an action is final.
- Keyboard navigation, labelled form controls, visible focus and accessible status announcements.
- Responsive layouts for desktop, tablet and mobile.
- Low-bandwidth-friendly pages and progressive loading.
- Date/time displayed in the relevant campus timezone.
- Plain-language explanations for external-system hand-offs and sync failures.

## 17. MVP delivery sequence

### Admin MVP (before academic LMS)
1. Secure tenant context and permission-aware navigation.
2. College profile and onboarding checklist.
3. Staff invitations, multi-role grants and access review (after role model approval).
4. Campuses, terms, course offerings and class groups.
5. Registrar enrolment and multiple group assignment.
6. Admissions pipeline appropriate to each portal mode.
7. Audit trail and basic operational reports.

### Subsequent modules
8. Timetable/class sessions.
9. Integrations and sync exception management.
10. Private documents and secure messaging.
11. Attendance devices, QR and manual registers.
12. Learning modules, lessons, classroom integration and progress.
13. Billing, usage metering and automated subscription lifecycle.

Do not build attendance or LMS controls as decorative screens before their underlying permission model, event processing and audit requirements are ready.

## 18. Acceptance criteria before implementation

1. A user with memberships in two colleges can switch only between active memberships and sees distinct tenant data.
2. A suspended college or revoked membership cannot access operational pages or APIs.
3. Existing, full and hybrid modes clearly identify system-of-record ownership.
4. Admissions staff cannot activate official course enrolments unless explicitly delegated.
5. Registrar can activate an authorised enrolment and allocate a student to multiple groups in one offering.
6. A student cannot self-activate an enrolment or allocate themselves to a class group.
7. Lecturer and TA only see assigned groups and minimum necessary student fields.
8. Staff invitations are verified, single-use, expiring and auditable.
9. No user can grant or approve their own elevated access.
10. Integration failures remain visible and are safely retryable without duplicate records.
11. Exports respect the same scope and consent restrictions as the UI.
12. High-impact actions create durable audit events.
13. Subscription lapse does not silently delete academic/student records.
14. All routes and APIs enforce permissions independently of frontend navigation.
15. Accessibility, mobile and low-bandwidth acceptance checks pass.

## 19. Open decisions before implementation

1. Confirm the first pilot college and whether it uses existing, full or hybrid mode.
2. Confirm which campus and academic-term fields are mandatory for its operations.
3. Confirm who may review applications, issue offers and approve registrations in that college.
4. Confirm whether offering-level lecturer assignments are needed in addition to class-group assignments.
5. Confirm whether college administrators can export student-level records or only aggregate reports by default.
6. Confirm the billing roles and subscription entitlements; current displayed prices are proposals only.
7. Confirm approved integrations and written authorisation for each external system.

## 20. Implementation boundary

This is a product and workflow specification. It is not a claim that any dashboard, API, database schema, role workflow, integration or billing feature is currently implemented. No database changes are authorised by this document.
