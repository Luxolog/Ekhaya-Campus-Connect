# CampusConnect Academic Structure — Foundation Design

**Status:** Design only. No Supabase tables, policies, migrations or production data have been changed.

## Design principles
- Reuse existing colleges, courses, applications, student_profiles and college_memberships.
- Keep courses as the college's programme/course catalogue. A course offering is a specific delivery of that course in a term, campus and study mode.
- Keep student identity global. Enrolment is a college-scoped relationship to a specific course offering.
- A submitted or accepted application is not itself an enrolment. A registrar-approved registration workflow creates the enrolment record.
- Every college-owned record carries college_id and has tenant-aware RLS.
- Lecturers and teaching assistants receive access through explicit assignments, not broad college-wide student access.
- Store event timestamps as timestamptz; use campus timezone for timetable display and local academic dates.

## Existing live schema observations
- colleges has id, name, slug, status and portal_mode.
- college_memberships has college_id, user_id and role. Its current role check permits only college_admin, admissions_staff and registrar.
- courses has college_id, title, qualification, description, study_mode, duration, application_open and published.
- applications links student_id, college_id and optional course_id; statuses include submitted, under_review, accepted, rejected and registered.
- student_profiles is a global profile keyed by auth user.
- RLS is enabled on the existing tables inspected.
- Current course staff policies allow college_admin/admissions_staff to manage courses; registrar is not included in those course policies.
- The current schema/migration history still needs baseline reconciliation before production migrations.

## Academic model and relationships
1. College has one or more Campuses.
2. College defines Academic Terms (semester, trimester, year or custom period).
3. Course is the catalogue programme.
4. Course Offering is one delivery instance of a course in a term, mode and optional campus.
5. Course Enrolment links a student to an offering after registration is approved.
6. Class Groups divide an offering into cohorts, lecture groups, tutorials or practical groups.
7. A student may belong to **multiple class groups within the same course offering**.
8. Class Group Staff Assignment grants a lecturer/teaching assistant access to specific groups and their sessions.
9. Class Session is a scheduled lecture, tutorial, lab, workshop or examination.
10. Learning modules and lessons attach to the course offering; attendance attaches to a class session.

## Proposed entities
### campuses
College-owned site records: code, name, timezone, address, status and physical/virtual type.

### academic_terms
College-owned academic period: name, start/end dates, type, status and optional registration dates. Supports semesters, trimesters, quarters, years or custom periods.

### course_offerings
A concrete delivery instance of an existing courses row. Includes offering code, academic term, optional campus, delivery mode (campus, online, distance, correspondence, hybrid), start/end dates, capacity and status. A course may have multiple offerings across campuses, terms and modes.

### course_enrolments
Formal student registration in an offering. Includes college, offering, student auth user, student number, status, effective dates and source application reference. Statuses: pending, active, suspended, completed, withdrawn. One student has one enrolment record per offering; group membership is handled separately.

### class_groups
A cohort, lecture, tutorial or lab group within an offering. Includes name/code and status. Groups are children of one course offering.

### class_group_enrolments
Required many-to-many bridge between course_enrolments and class_groups. A course enrolment can be assigned to multiple groups (for example, Lecture Group A and Tutorial Group C). A group can contain many course enrolments. Include college_id, course_enrolment_id, class_group_id, status, assigned_at, assigned_by, effective dates and optional end date. Enforce that the group and enrolment belong to the same college and same course offering using composite foreign keys/constraints. Avoid storing group_id directly on course_enrolments as a second source of truth.

### class_group_staff
Assignment of a college membership to a group with scoped role (lecturer, teaching_assistant, class_coordinator). Include start/end dates and assignment status. Membership role must be eligible for the assignment.

### class_sessions
Scheduled lesson/meeting with group, title, type, delivery mode, start/end timestamps, room/meeting reference and attendance window. A session is associated with one class group; students eligible for its register are active class_group_enrolments for that group at session time. Cancelled sessions must not generate absences.

## Application-to-enrolment workflow
- Application is submitted and processed by admissions.
- College decides acceptance under its admissions policy.
- Registrar verifies registration requirements and confirms actual registration.
- A server-side, idempotent registration action creates course_enrolments from the accepted application and records source_application_id.
- Do not let a student set their own enrolment status to active.
- Group assignment is a separate authorised action, allowing one enrolment to be added to multiple class groups.
- Reversal/cancellation preserves the audit trail and updates status rather than deleting historical registration.

## Roles and permissions
Proposed membership roles to add only after approval:
- college_admin
- admissions_staff
- registrar
- lecturer
- teaching_assistant
- attendance_officer
- student_support

Role meaning:
- college_admin: college configuration and staff membership.
- admissions_staff: course catalogue, applications and admissions pipeline; no unrestricted academic grade editing.
- registrar: academic terms, offerings, official enrolment and group allocation.
- lecturer: assigned offerings/groups, learning materials, sessions, marks and class registers.
- teaching_assistant: limited assigned-group access; marking/attendance only where delegated.
- attendance_officer: scoped attendance device and register operations, no broad academic record access.
- student_support: limited support access under explicit policy, no default access to all student records.

Students remain authenticated users with own profile and enrolment policies; do not create a college_membership row for each student just to represent enrolment.

## Security and RLS plan

### Tenant isolation
- Enable RLS on every new table in public.
- Every tenant-owned row has college_id NOT NULL.
- Parent-child relationships use composite unique keys and composite foreign keys containing college_id, preventing cross-college references even if an application bug submits mismatched IDs.
- Policies derive college access from trusted college_memberships rows and, for teaching access, active class_group_staff assignments. Never use user-editable user_metadata for authorisation.
- A user who belongs to two colleges receives only the rows allowed by each membership and assignment.

### Proposed access matrix
| Resource | Student | Lecturer / TA | Registrar | Attendance officer | College admin |
|---|---|---|---|---|---|
| Campus and term | Published/relevant read only | Assigned course context read | Manage | No access by default | Manage |
| Course offering | Own enrolled offerings read | Assigned offering read | Manage | Session context read | Manage |
| Course enrolment | Own read | Assigned group students read, minimum fields | Manage | Minimum identity needed for register | Manage |
| Class groups | Own assigned groups read | Assigned groups read; no tenant-wide listing | Manage | Assigned campus/session scope | Manage |
| Group enrolment | Own memberships read | Assigned group roster read | Manage | Roster fields required for attendance | Manage |
| Staff assignments | No access | Own assignment read | Read/coordinate if authorised | No access | Manage |
| Class sessions | Own eligible sessions read | Assigned sessions manage | Manage | Read and operate assigned registers | Manage |
| Attendance records | Own read | Assigned groups read/write only through approved register workflow | Read/correct under policy | Record attendance for assigned sessions | Read/manage under policy |
| Staff/college configuration | No access | No access | Limited | Device operations only | Manage |

This matrix is a target, not current live permissions. Final policy details must be tested per SQL operation.

### RLS policy patterns
- Student SELECT: row must join through course_enrolments where student_user_id = (select auth.uid()), status permits access, and college_id matches the row.
- Staff SELECT: active membership in same college plus role/capability; teaching roles additionally require a current class_group_staff assignment for the group's offering/session.
- Lecturer/TA INSERT/UPDATE: restrict to assigned groups and explicit delegated capabilities. UPDATE needs a matching SELECT policy and both USING and WITH CHECK so rows cannot be moved to another college/group.
- Registrar writes: only approved lifecycle operations for enrolments, groups, terms and offerings.
- Attendance officer writes: only attendance events/register workflow for assigned devices/campuses/sessions; no course grade or enrolment status changes.
- College admin: tenant-scoped configuration and membership management.
- No anon writes to academic tables. Public course discovery remains limited to existing published-course policies.
- Do not rely on TO authenticated alone; every policy must include ownership, tenant or assignment predicates.
- Prefer SECURITY INVOKER. If SECURITY DEFINER is genuinely required, keep it in a non-exposed schema, explicitly check auth.uid(), set a safe search_path and restrict EXECUTE grants. Do not use it as a shortcut around RLS.

### Privileged workflows
- Student registration activation, group assignment, staff-role changes and sensitive attendance corrections should be server-side operations with explicit permission checks and audit events.
- Students must not self-activate enrolments or assign themselves to groups.
- A lecturer cannot grant themselves access to a group.
- No device or reader receives Supabase user credentials or direct table write access.
- Keep audit events for staff assignment, enrolment transitions, group allocation, timetable changes and administrative corrections.

### Verification matrix before deployment
Test at least two colleges:
1. College A staff cannot SELECT/INSERT/UPDATE/DELETE College B academic rows.
2. Student A cannot read another student's enrolment or group allocation.
3. A lecturer assigned to Group A cannot access Group B roster, even in the same offering.
4. A lecturer assigned to two groups can access both, but no unassigned groups.
5. A teaching assistant cannot perform actions not explicitly delegated.
6. Registrar can activate an enrolment and assign it to multiple groups; student cannot.
7. A student can see their own group timetable and learning resources only.
8. Attendance officer cannot change grades, enrolment status or staff roles.
9. UPDATE attempts changing college_id, offering_id or group_id fail.
10. Revoked/ended assignments immediately deny future access after token/session refresh as appropriate.
11. Anonymous requests cannot enumerate private academic records.
12. Audit trail captures privileged changes and corrections.

## Integrity constraints and indexes
- Composite tenant FKs prevent cross-college references.
- Existing courses needs UNIQUE(college_id,id) before tenant-safe composite FK from course_offerings.
- class_group_enrolments must ensure class group and course enrolment refer to the same course offering. Enforce through a shared offering_id column with composite FKs or a carefully validated constraint trigger; prefer declarative composite FKs.
- Unique (college_id, campus_code), (college_id, offering_code), (college_id, group_code).
- Unique active group membership per (course_enrolment_id, class_group_id); retain ended assignment history if rejoining is allowed.
- Index college_id plus common joins: offering_id, student_user_id, term_id, group_id, membership_id, starts_at.
- Validate term dates, offering dates, assignment dates and status transitions.
- Add indexes only after query patterns and constraints are agreed.

## Decisions still open before SQL migration
1. Can an offering span multiple campuses? If yes, use offering_campuses join table instead of one campus_id.
2. Can lecturers be assigned to the whole offering as well as individual groups? Add offering-level assignments if required.
3. Official student number uniqueness: recommendation is per college.
4. Define term models, enrolment transitions and group assignment lifecycle per college.
5. Confirm who may create and approve staff memberships. No public self-assignment.

## Implementation order
1. Reconcile existing schema and migration baseline.
2. Approve academic model and group-allocation rules.
3. Finalise staff role/capability matrix and RLS test matrix.
4. Prepare migration plan with composite keys, constraints, indexes, policies and audit hooks.
5. Test with at least two colleges, multiple groups per offering, two students, lecturer assignments, registrar and attendance officer.
6. Only after review, deploy a small migration and verify cross-tenant isolation before building UI.
