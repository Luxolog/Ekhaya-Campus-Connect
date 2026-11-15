# CampusConnect Academic Structure — Foundation Design

**Status:** Design only. No Supabase tables, policies, migrations or production data have been changed.

## Design principles
- Reuse existing colleges, courses, applications, student_profiles and college_memberships.
- Keep courses as the college's programme/course catalogue. A course offering is a specific delivery of that course in a term, campus and study mode.
- Keep student identity global. Enrolment is a college-scoped relationship to a specific course offering.
- A submitted or accepted application is not itself an enrolment. A registrar-approved registration workflow creates the enrolment record.
- Every college-owned record must have college_id and tenant-aware RLS.
- Lecturers and teaching assistants receive access through explicit assignments to offerings or class groups, not broad college-wide student access.
- Store all event timestamps as timestamptz; use the campus timezone for timetable display and local academic dates.

## Existing live schema observations
- colleges exists with id, name, slug, status and portal_mode.
- college_memberships exists with college_id, user_id and role. Its current role check permits only college_admin, admissions_staff and registrar.
- courses exists with college_id, title, qualification, description, study_mode, duration, application_open and published.
- applications links student_id, college_id and optional course_id; statuses include submitted, under_review, accepted, rejected and registered.
- student_profiles is a global profile keyed by auth user.
- RLS is enabled on these existing tables.
- Current course staff policies allow college_admin/admissions_staff to manage courses; registrar is not included in those course policies.
- The current schema/migration history still needs baseline reconciliation before production migrations.

## Academic model and relationships

1. **College** has one or more **Campuses**.
2. **College** defines **Academic Terms** (semester, trimester, year or custom period).
3. **Course** is the catalogue programme.
4. **Course Offering** is one instance of a course delivered by a college in a specific term, mode and optional campus.
5. **Course Enrolment** links a student to an offering after registration is approved.
6. **Class Group** divides an offering into cohorts/tutorial groups.
7. **Class Group Staff Assignment** grants a lecturer/teaching assistant access to a specific group and its sessions.
8. **Class Session** is a scheduled lecture, tutorial, lab, workshop or examination.
9. Learning modules and lessons attach to the course offering, while attendance attaches to class sessions.

## Proposed entities

### campuses
College-owned site records: code, name, timezone, address, status. A campus may be physical or virtual if the institution needs a virtual campus designation.

### academic_terms
College-owned academic period: name, start/end dates, type, status and optional registration dates. A college may use semesters, trimesters, quarters or custom terms.

### course_offerings
A concrete delivery instance of an existing courses row. Includes offering code, academic term, optional campus, delivery mode (campus, online, distance, correspondence, hybrid), start/end dates, capacity and status. A course may have multiple offerings across campuses, terms and modes.

### course_enrolments
Student's formal registration in an offering. Includes college, offering, student auth user, student number/enrolment number, status, effective dates and source application reference where appropriate. Enrolment statuses: pending, active, suspended, completed, withdrawn. Enforce one active enrolment per student/offering through a unique key or partial unique index after lifecycle rules are finalised.

### class_groups
A cohort, class, tutorial or lab group within an offering. Has name/code and status.

### class_group_staff
Assignment of a college membership to a group with a scoped teaching role (lecturer, teaching_assistant, class_coordinator). Include start/end dates and assignment status. Membership role must be eligible for the assignment.

### class_group_enrolments (optional design choice)
Only add this if students can be assigned to multiple subgroups within one course offering. Otherwise derive group membership from course_enrolments plus a single group_id on the enrolment. Avoid maintaining two competing sources of group membership.

### class_sessions
Scheduled lesson/meeting with group, title, type, delivery mode, start/end timestamps, room/meeting reference and attendance window. Cancelled sessions must not generate absences.

## Application-to-enrolment workflow
- Application is submitted and processed by admissions.
- College decides acceptance according to its own admissions policy.
- Registrar verifies registration requirements and confirms the student's actual registration.
- A server-side, idempotent registration action creates course_enrolments from the accepted application and records the source application ID.
- Do not let a student set their own enrolment status to active.
- Reversal/cancellation must preserve the audit trail and update the enrolment status rather than deleting historical registration.

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
- college_admin: manages college configuration and staff membership.
- admissions_staff: course catalogue, applications and admissions pipeline; no unrestricted academic grade editing.
- registrar: confirms enrolment, academic term and official registration records.
- lecturer: assigned offerings/groups, learning materials, sessions, marks and class registers.
- teaching_assistant: limited assigned-group access; marking or attendance capabilities only where delegated.
- attendance_officer: scoped attendance device and register operations, no broad academic record access.
- student_support: limited support access under explicit policy, no default access to all student records.

Students remain authenticated users with own profile and enrolment policies; do not create a college_membership row for each student just to represent enrolment.

## RLS model to design and test
- All college-owned tables: RLS enabled.
- Staff access requires an active membership for the same college and appropriate role/capability.
- Lecturer access requires a current class_group_staff assignment.
- Student access is limited to rows linked to their own auth.uid() through course_enrolments.
- College A must never access College B rows, even if the same user has membership in both.
- Use trusted database membership/assignment rows, not user-editable auth metadata, for authorisation.
- UPDATE policies need matching SELECT visibility and both USING and WITH CHECK predicates.
- Avoid public/anon write access to academic structures.
- Consider private schema helper functions only when necessary; SECURITY DEFINER functions require careful review, explicit auth.uid checks and restricted execution grants.

## Important integrity constraints
- Composite tenant foreign keys should prevent a row with college_id A from referencing a parent row owned by college B.
- Existing courses currently has primary key id and college_id but no reported UNIQUE(college_id,id). Add/verify this before composite references from course_offerings.
- Use unique (college_id, campus_code), unique (college_id, offering_code), unique (college_id, group_code).
- Validate term dates and offering dates.
- Use explicit statuses and transitions, not free-form strings.
- Index college_id plus common joins (offering_id, student_user_id, term_id, group_id, starts_at).
- Add indexes only after query patterns and constraints are agreed.

## Decisions to settle before SQL migration
1. Can a student be in multiple class groups within the same offering? If yes, use class_group_enrolments; if no, one group_id on course_enrolments is simpler.
2. Can a course offering span more than one campus? If yes, model offering_campuses as a join table rather than one campus_id.
3. Can lecturers be assigned to the whole offering as well as individual groups? Support offering-level assignments if required.
4. Define official student number uniqueness: per college or globally. Recommendation: per college.
5. Define term models and enrolment status transitions per college configuration.
6. Confirm who may create and approve staff memberships. No public self-assignment.

## Implementation order
1. Reconcile existing schema and migration baseline.
2. Approve academic model decisions above.
3. Finalise staff role/capability matrix and RLS test matrix.
4. Prepare a migration plan with explicit composite keys, constraints, indexes, policies and audit hooks.
5. Test with at least two colleges, two students, a lecturer assigned to only one group, a registrar and an attendance officer.
6. Only after review, deploy a small migration and verify cross-tenant isolation before building UI.
