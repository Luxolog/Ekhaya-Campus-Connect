# CampusConnect College Staff Governance and Permission Model

**Status:** Architecture proposal only. No database schema, RLS policy, migration or production data has been changed.

## 1. Existing implementation facts
The live `college_memberships` table currently contains `id`, `college_id`, `user_id`, `role`, and `created_at`. It has a unique constraint on (college_id, user_id), a role CHECK limited to `college_admin`, `admissions_staff`, and `registrar`, and a SELECT policy that lets authenticated users read only their own membership rows. This is not yet a staff invitation or role administration workflow.

The migration history currently lists three entries: `auth_profile_bootstrap_and_consent_controls`, `consolidate_consent_read_policy`, and `college_registration_requests`. The broader original schema still needs a reproducible baseline before any production migration is prepared.

## 2. Governance principles
- A college controls its own staff roster, but cannot grant access to another college.
- Staff access is invitation-based and requires a verified authenticated account.
- No public self-registration into a college staff role.
- A user cannot grant, approve or expand their own privileges.
- Role grants are explicit, auditable, time-bound where appropriate, and revocable.
- College administrators may manage ordinary staff roles within their college, but high-privilege administrator grants and recovery must use a separately controlled approval route.
- The platform operator provisions the initial college administrator only after verifying the college's authority and designated representative outside the public signup flow.
- Staff access is denied by default until invitation acceptance and activation are complete.
- A suspended college blocks staff access even if individual memberships remain active.
- A person can hold multiple roles at one college; role grants are additive only within the intersection of tenant membership, assigned scope and permitted action.

## 3. Recommended data model

### Existing `college_memberships`
Keep one identity membership per (college_id, user_id), but introduce a membership lifecycle in a reviewed migration:
- `status`: invited, active, suspended, revoked.
- `created_at`, `activated_at`, `suspended_at`, `revoked_at` or equivalent event history.
- Preserve the existing `role` field temporarily for compatibility during migration; do not treat it as the long-term source of multiple role grants.

### `college_staff_invitations`
Private invitation workflow:
- college_id, normalized invited_email, invited_by membership, requested role set, status, token_hash, expires_at, accepted_by user, accepted_at, created_at.
- Store only a cryptographic hash of a high-entropy, single-use invitation token. Never store the raw token.
- Invitation acceptance requires a valid authenticated session and verified email matching the invitation.
- Token is single-use, expires, is invalidated on cancellation/reissue, and cannot be used to change the invited email or college.
- Invitations are created and cancelled only by an authorised college administrator; initial college admin invitations are platform-provisioned.
- Do not expose invitation token hashes or private invitation rows to ordinary browser clients.

### `college_membership_roles`
Normalised role grants to support multiple roles per person:
- id, college_id, membership_id, role, status, granted_by, approved_by, starts_at, ends_at, created_at, revoked_at.
- Unique active grant for a given membership and role; retain revoked history.
- A user may be lecturer and attendance_officer simultaneously, without duplicating the college membership.
- Role grants are college-wide only for administrative roles. Teaching access still requires explicit offering/group assignments; attendance access additionally requires assigned operational scope.
- Role grant changes are privileged server-side actions and append audit events.

### Permission catalogue
Use a fixed, version-controlled permission catalogue rather than allowing each college to invent arbitrary permissions. Example capabilities:
- college.settings.manage
- college.staff.invite
- college.staff.role.grant
- college.staff.role.revoke
- courses.manage
- applications.review
- enrolments.manage
- academic_terms.manage
- offerings.manage
- class_groups.manage
- class_groups.assign_students
- class_groups.assign_staff
- learning_materials.manage
- sessions.manage
- attendance.register.read
- attendance.register.record
- attendance.adjust
- grades.read
- grades.record
- grades.approve
- student_support.read_limited

The role-to-capability mapping is platform-defined and version controlled. Colleges assign roles, not arbitrary capabilities. High-impact capabilities (role administration, grade approval, attendance correction) must be separated from ordinary operational permissions.

## 4. Role and capability boundaries

| Role | College-wide capabilities | Required scope |
|---|---|---|
| college_admin | College configuration, ordinary staff invitations and role administration | Same college; elevated admin grants use separate approval |
| admissions_staff | Course catalogue, application review and admissions communications | Same college; only minimum student fields needed |
| registrar | Academic terms, offerings, official enrolment and student/group registration | Same college |
| lecturer | Learning material, sessions, assigned class registers, delegated marks | Assigned offering/group only |
| teaching_assistant | Delegated class operations and limited roster/attendance tasks | Explicit assigned group |
| attendance_officer | Device operations and attendance recording/correction workflow | Assigned campus/device/session |
| student_support | Limited student support and case context | Explicit support assignment or case; no bulk student browsing |

Students are not staff memberships. Student access is based on their own profile, applications, enrolments and class-group enrolments.

## 5. Staff lifecycle

1. College administrator selects an existing role from the approved role catalogue and enters the staff member's email.
2. Server validates that the administrator has permission to invite that role and cannot invite a role above their own grant authority.
3. Server creates a pending invitation with a single-use token hash and expiry; it sends the invitation through a trusted email service.
4. Invitee signs in or creates an account, verifies the same email, and accepts the invitation.
5. A trusted server-side operation consumes the token atomically, creates/activates the membership and role grants, and records the audit event.
6. Where required, a second authorised approver approves high-risk role grants. The inviter cannot approve their own request.
7. College admin may suspend/revoke staff membership. Revocation also deactivates role grants and group assignments, or causes them to become ineffective immediately through the membership status check.
8. Reinstatement requires an explicit new approval and audit event; do not silently reactivate expired or revoked invitations.

## 6. Approval and anti-escalation rules
- Initial `college_admin`: platform-verified onboarding, not public signup.
- Additional `college_admin`: existing admin requests plus second-admin approval, or platform support recovery. The requester cannot approve their own request.
- `registrar`: granted by college_admin; optional second approval if the college requires separation of duties.
- `admissions_staff`: granted by college_admin.
- `lecturer`, `teaching_assistant`, `attendance_officer`, `student_support`: granted by college_admin; their operational scope is assigned separately.
- No staff member may grant themselves a role, change their own membership status, assign themselves to a group, or modify their own grant authority.
- A college administrator cannot assign a platform-level role or access another tenant.
- Platform support should use a controlled, audited support workflow; no permanent shared superuser account.

## 7. RLS and server-side security plan
- Keep invitation tables in a non-exposed schema where practical. Do not grant anon or ordinary authenticated users direct access to invitation token material.
- `college_memberships`: staff may read their own membership; college admins may read their own college roster through a tenant-scoped policy or a narrowly scoped server-side endpoint. No client-side membership INSERT/role UPDATE.
- `college_membership_roles`: members may read their own grants; authorised college admins may read the college's role roster. No direct client INSERT/UPDATE/DELETE.
- `college_staff_invitations`: no public SELECT of raw invitation records or token hashes. Creation, acceptance, cancellation and expiry occur through narrowly scoped server-side operations.
- RLS helper predicates must use trusted database membership and role-grant rows, not user-editable auth user_metadata.
- Avoid circular RLS policies. If a private helper is needed to check membership, make it minimal, stable, schema-qualified and review its execution privileges. Prefer SECURITY INVOKER; if SECURITY DEFINER is unavoidable, place it in a non-exposed schema, check auth.uid() inside the function, set a safe search_path and revoke default PUBLIC EXECUTE.
- Never expose service-role or secret keys in the browser.
- Use `TO authenticated` plus explicit tenant, ownership, role and assignment predicates; authentication alone is not authorisation.
- For UPDATE, ensure SELECT visibility plus both USING and WITH CHECK. Prevent changes to college_id, membership user_id, role authority and invitation recipient through ordinary client updates.
- Use server-side atomic transactions for invitation consumption and role grant changes; make acceptance idempotent and protect against replay/races.
- Log who invited, accepted, approved, granted, suspended, revoked and reinstated access, including timestamps and relevant request context. Do not log raw invitation tokens.

## 8. Required audit events
At minimum:
- staff_invitation_created, staff_invitation_cancelled, staff_invitation_expired, staff_invitation_accepted
- membership_activated, membership_suspended, membership_revoked, membership_reinstated
- role_grant_requested, role_grant_approved, role_grant_created, role_grant_revoked
- class_group_staff_assigned, class_group_staff_revoked
Audit records should be append-only to application roles. Corrections should be additional events, not edits that erase history.

## 9. Test plan
Use two colleges and users with overlapping memberships:
1. College A administrator cannot read or manage College B's staff roster or invitations.
2. Ordinary staff cannot create invitations or alter their role grants.
3. Staff cannot grant themselves a role or approve their own elevated role request.
4. A verified invitee can accept only an unexpired invitation addressed to their verified email.
5. Replaying or concurrently accepting the same token creates at most one membership/role grant.
6. Expired, cancelled and consumed tokens fail.
7. Revoked/suspended membership immediately denies access to all college resources, including previously assigned groups.
8. Lecturer with two group assignments sees only those groups; no college-wide roster.
9. Attendance officer cannot read grades or change enrolments.
10. Student support cannot export/browse all students.
11. College suspension blocks all staff access.
12. Audit events are written for every privileged lifecycle transition and cannot be edited by ordinary staff.

## 10. Decisions before migration
1. Should additional college_admin grants always require two-person approval? Recommendation: yes.
2. Should staff invitation expiry default to 7 days, with one reissue? Recommendation: 7 days and single-use token.
3. Which staff roles need a second approval beyond college_admin? Recommendation: registrar and grade-approver capability if the college chooses separation of duties.
4. Confirm whether existing role column is retained as a compatibility field for one release before moving all authorisation to role grants.
5. Decide whether college admins may invite student_support and attendance_officer directly or whether those roles require a designated approver.

## 11. Implementation sequence
1. Reconcile the original schema migration baseline.
2. Approve this role catalogue and staff lifecycle.
3. Design the role-grant and invitation SQL with constraints and RLS in a private schema where appropriate.
4. Implement server-side invitation/approval workflows with audit events.
5. Test anti-escalation and tenant isolation with two colleges.
6. Only after explicit approval, prepare and review migrations. No deployment is authorised by this design document.
