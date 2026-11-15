# CampusConnect learning and attendance foundation

**Status:** Architecture and schema proposal only. This is not an approved production specification or a database migration. No Supabase objects have been created or changed.

## Decisions

- College-managed teaching is the default. The college owns lecturers, teaching materials, academic standards, assessments, marking and academic outcomes.
- CampusConnect supplies course delivery, timetable, classroom integration, attendance, student records, reporting and integration services.
- Leave room for optional Ekhaya-supported delivery and separately governed Ekhaya courses.
- Support NFC, RFID and QR attendance, plus lecturer-managed and online-class attendance.
- Integrate existing compatible reader hardware first. Compatibility must be assessed per vendor/model/protocol and piloted.
- CampusConnect is the authoritative attendance ledger. Readers and video services are evidence sources, not the system of record.
- Devices never write directly to public database tables. Reader traffic passes through a trusted gateway or server-side integration endpoint.

## 1. Logical architecture

1. College systems and channels: existing NFC/RFID readers, QR check-in, lecturer register and online classroom providers.
2. Integration gateway: vendor-specific adapters, API/webhook intake, device identity, request signing, replay protection and offline queue synchronisation.
3. Attendance engine: resolve credential to student, verify active college enrolment, match an eligible class session, apply attendance windows, deduplicate events and calculate attendance state.
4. CampusConnect records: immutable source events, derived attendance records, adjustments and audit history.
5. College workspaces: student, lecturer, registrar, attendance officer and college administrator views.

## 2. Teaching responsibility and learning delivery

Default: each college supplies and approves its lecturers, course structure, teaching material, timetable, assessments, marking and academic outcomes. CampusConnect supplies the LMS and classroom technology.

Optional operating modes:
- College-managed: college controls all teaching.
- College with Ekhaya delivery support: Ekhaya provides agreed technical or delivery services under the college's academic governance.
- Ekhaya-managed course: separate provider ownership and approval workflow; qualification and accreditation claims require appropriate regulatory checks.

A course catalogue entry is not automatically an active teaching course. Delivery uses college-owned course offerings, class groups and scheduled sessions.

## 3. Proposed database domains

All college-owned records carry college_id and must be protected by tenant-aware RLS. The existing global student identity remains auth.users / student_profiles. A student's relationship with a college is represented by a college-scoped enrolment, not by copying the student profile into each college.

### Institution and academic delivery
- campuses — college campus/site, timezone, address and status.
- academic_terms — college academic year/term and date boundaries.
- course_offerings — a college's delivery instance of an existing catalogue course, linked to campus/term and delivery mode.
- class_groups — cohort, class or tutorial group within an offering.
- class_sessions — scheduled teaching event: group, start/end, room or online mode, attendance window and session status.
- course_enrolments — student-to-offering enrolment, status and effective dates. This is the attendance eligibility source; an application marked registered must be reconciled to an actual enrolment.

### Learning delivery
- course_modules — ordered modules within a course offering.
- lessons — lesson metadata, type (live, recorded, reading, activity), order and publication state.
- lesson_resources — private resource metadata and storage object path; files live in private storage, not public URLs.
- lesson_enrolments — access/progress state for students enrolled in a course offering.
- online_classroom_sessions — link a class session to a supported video provider and external meeting reference. Never store provider passwords or long-lived meeting secrets in a browser-readable row.

### Identity and attendance hardware
- student_cards — college-issued card record, student, technology (NFC/RFID), display label, status, issue/expiry/revocation dates. Store a keyed credential fingerprint, not the raw card UID, where hardware allows it.
- attendance_devices — reader/gateway identity, campus, vendor, model, connector type, external device ID, capabilities, status and last-seen time. Store only a reference to a secret held in a secure secret store.
- attendance_device_events — append-only received evidence: source event ID, idempotency key, device, timestamp, resolved student/session where available, verification result and sanitised metadata. Do not retain unnecessary raw credential values.
- qr_attendance_challenges — hashed, short-lived, session-bound QR challenge/token state. Tokens are single-use or tightly rate-limited and cannot be reused across colleges or sessions.

### Attendance register and audit
- attendance_records — derived register row, one per student per class session, with status (present, late, absent, excused, pending_review), first/last verified check-in and calculation metadata.
- attendance_adjustments — append-only correction request/decision, previous and new values, reason, actor and timestamp.
- online_presence_events — provider join/leave evidence and session duration, subject to provider capabilities and privacy settings.
- attendance_device_health_events — device connectivity, sync and fault observations for operations/support.

## 4. Attendance event processing

1. Reader or QR client submits an event to the integration gateway over an authenticated encrypted channel.
2. Gateway authenticates the device/connector, verifies signature and timestamp, checks replay protection and validates the college/device assignment.
3. Credential resolver maps a card fingerprint or QR token to a current student-card assignment. QR tokens are short-lived and session-bound.
4. Eligibility check confirms active enrolment for the college/course offering and that the session is open for attendance.
5. Event is recorded immutably with a stable idempotency key. Retries must not create duplicate events.
6. Attendance engine updates the derived register row according to college policy and the session's attendance window.
7. Corrections use a separate adjustment workflow with reason and audit history. Never edit or delete the original device event.

A tap is evidence of a check-in, not proof of continuous attendance. Colleges may require a second tap, lecturer confirmation or another policy for departure/attendance duration.

## 5. Hardware integration strategy

Build an adapter interface rather than hard-code a reader brand:
- Vendor cloud API / webhook connector.
- Local campus gateway for LAN/serial/USB readers where the vendor supports a documented protocol.
- Standardised event intake contract for approved third-party systems.
- Manual CSV import only as a controlled migration/reconciliation path, never as a silent source of verified live taps.

Each connector pilot must document vendor, model, firmware, card technology/frequency, protocol, encryption/authentication, event format, clock synchronisation, network behaviour, offline buffering, duplicate behaviour and vendor API/licensing restrictions.

**Compatibility caveat:** NFC and RFID are technology families, not one universal reader protocol. A reader may read a card but still not expose events to CampusConnect. Test exact card + reader + vendor software combinations before promising support.

## 6. Security and tenant isolation

- Enable RLS on every exposed college-owned table.
- Tenant access derives from trusted college membership records and server-controlled roles; never trust user-editable user_metadata for authorisation.
- Students see only their own enrolments, lessons and attendance.
- Lecturers access only assigned offerings/groups/sessions and their students' academic records.
- Attendance officers receive scoped register/device permissions, not broad academic administration by default.
- College administrators are restricted to their college. Ekhaya platform operations use separately controlled support permissions and audited access.
- Reader devices receive neither Supabase user credentials nor direct database write permissions.
- Device secrets, QR signing keys and video-provider credentials live in a secret manager/server-side environment.
- QR tokens are unpredictable, short-lived, hashed at rest, session-bound and rate-limited.
- Keep immutable device evidence separate from mutable derived register state.
- Log administrative access, card issue/revocation, device changes, attendance corrections and exports.
- Define retention, access, student notice and lawful purpose for attendance data under POPIA before rollout.

## 7. Offline and resilience design

A campus gateway may temporarily queue signed device events during an internet outage. Each event needs a globally unique source event ID, device ID, event time, monotonic sequence where supported and signature. On reconnection, the server validates and deduplicates the batch. Device clock drift and delayed uploads must be visible to administrators. Local queue encryption and secure deletion/retention belong in the gateway design.

## 8. Roles to plan for

The current college_memberships role constraint is narrower than the future LMS/attendance model. Before implementation, review and extend the role model deliberately. Proposed scoped roles:
- college_admin
- admissions_staff
- registrar
- lecturer
- teaching_assistant
- attendance_officer
- student_support
- student (student identity is primarily represented by authenticated user and enrolment records)

Prefer explicit capability tables or well-defined role permissions if colleges need combinations or custom roles. Do not rely on a single broad role string for every permission.

## 9. Current-project dependencies

The current Supabase project already has colleges, college_memberships, student_profiles, courses, applications and other core tables, all reported with RLS enabled. student_profiles is global identity/profile data. courses is a college-owned catalogue. The new design builds on these entities, not duplicates them.

The current database migration history does not capture the original nine-table baseline. Before production DDL, reconcile the live schema with a reproducible baseline and existing migrations. Do not assume this draft can be applied directly.

## 10. Implementation sequence

1. Inventory and reconcile existing schema, policies, constraints, indexes and migration history.
2. Approve the role/capability model and tenant RLS matrix.
3. Build institution delivery structures: campuses, terms, offerings, groups, enrolments and class sessions.
4. Build attendance core: card registry, device registry, immutable events, derived registers and correction workflow.
5. Build one hardware adapter pilot with a real college's exact reader/card model.
6. Add QR and lecturer register flows.
7. Add online classroom attendance integration.
8. Add learning modules, lessons, resources and progress tracking.
9. Run cross-tenant, replay, duplicate, offline, revoked-card, lost-card, clock-drift and audit tests before deployment.

## 11. Acceptance tests before production

- College A cannot read or change College B's students, cards, devices, sessions, events or attendance.
- Student can read only their own attendance and learning access.
- A revoked/lost card cannot create a valid new attendance event.
- Replayed or retried device events do not duplicate attendance.
- A device cannot submit events for another college or an unassigned reader.
- Student cannot mark themselves present by calling the database API.
- QR code expires and cannot be reused outside its session.
- Lecturer corrections require a reason and are fully audited.
- Offline event batches reconcile once, preserve original event time and expose clock drift.
- Existing reader integration passes a vendor-specific pilot and security review.
