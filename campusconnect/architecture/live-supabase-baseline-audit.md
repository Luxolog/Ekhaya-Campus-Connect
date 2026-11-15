# Live Supabase baseline audit — CampusConnect

**Snapshot date:** 2026-11-15  
**Project:** `campusconnect-platform`  
**Project ref:** `owaiysaotqxtqfystigc`  
**Region:** `eu-west-1`  
**Database:** PostgreSQL 17.11  
**Purpose:** Read-only reconciliation record before any schema or migration-history repair.

> This is an observed live-state inventory, not a replayable migration baseline. It must not be used to provision a fresh database. The original SQL for the first two recorded migrations was not found in the repository branch inspected, and the main branch does not currently contain a complete `supabase/migrations/` directory.

## 1. Project state

- Supabase project status: `ACTIVE_HEALTHY`.
- Nine public tables were inspected; all have RLS enabled.
- All nine public tables had zero rows at inspection.
- No Auth users, Storage buckets, or Edge Functions were present at the previous project inspection.
- Security and health advisors returned no lint findings. This is not a security certification.
- No database writes were performed during this audit.

## 2. Recorded migration history

The live migration ledger reports exactly:

| Version | Name |
|---|---|
| `20261115120143` | `auth_profile_bootstrap_and_consent_controls` |
| `20261115120200` | `consolidate_consent_read_policy` |
| `20261115120448` | `college_registration_requests` |

The PR #3 branch contains:
- `20261115120448_college_registration_requests.sql`
- `20261115130000_college_registration_reviewed_by_idx.sql`

The live index `college_registration_requests_reviewed_by_idx` exists, with definition:
`CREATE INDEX college_registration_requests_reviewed_by_idx ON public.college_registration_requests USING btree (reviewed_by)`.

However, migration version `20261115130000` is not recorded in the live migration ledger. The index migration is therefore an observed schema change without a matching migration-history record. Do not rerun or manually record it until the migration ledger, deployment history and intended migration workflow have been reconciled.

## 3. Public table inventory

| Table | Primary key | RLS | Observed rows |
|---|---|---:|---:|
| `colleges` | `id` | On | 0 |
| `college_memberships` | `id` | On | 0 |
| `student_profiles` | `user_id` | On | 0 |
| `courses` | `id` | On | 0 |
| `student_consents` | `id` | On | 0 |
| `applications` | `id` | On | 0 |
| `application_documents` | `id` | On | 0 |
| `audit_events` | `id` | On | 0 |
| `college_registration_requests` | `id` | On | 0 |

### Notable relationships and constraints

- `college_memberships.college_id` references `colleges.id`; `user_id` references `auth.users.id`.
- `student_profiles.user_id` references `auth.users.id`.
- `courses.college_id` references `colleges.id`.
- `applications.college_id` references `colleges.id`; `course_id` independently references `courses.id`. There is no composite constraint proving the selected course belongs to the same college as the application.
- `application_documents.application_id` references `applications.id`; `uploaded_by` references `auth.users.id`.
- `student_consents` links a student and college, with purpose and grant/revoke timestamps.
- `college_registration_requests.reviewed_by` references `auth.users.id`.

## 4. RLS policy inventory and implications

The live database has policies for:
- Student-owned profile read/insert/update.
- Consent-based college access to student profiles.
- Student consent grant and revoke.
- Student-owned applications and college membership access to applications.
- College-member course reads and staff course writes.
- Application document reads by applicant or college member, and document inserts by the applicant.
- College-member visibility of audit events.
- Own-membership reads.
- Public/authenticated course reads subject to publication/active-college or membership conditions.
- Public/authenticated INSERT-only college registration requests, constrained to pending and unreviewed.

Important limitations observed:
- Application SELECT allows any member of the relevant college, not only a capability-specific admissions role.
- Application UPDATE permits the configured college roles but has no separate column-level or explicit state-transition guard.
- Course writes permit college admins and admissions staff.
- Consent visibility is available to college members of the relevant college, rather than a narrower consent-management capability.
- Audit events have a SELECT policy for relevant staff but no client INSERT policy; a trusted append-only writer is not yet established.
- Application document storage paths are metadata only; no Storage bucket/policies were found in the earlier inspection.

## 5. Table grants

The effective privilege check reports broad table privileges for `anon` and `authenticated` on several tables, including applications, application_documents, courses, student_consents, student_profiles and audit_events. RLS currently supplies the row-level restrictions, but table grants should be reduced to the minimum required operations as part of the security remediation.

The college registration request table is narrower: INSERT is granted to `anon` and `authenticated`, with SELECT/UPDATE/DELETE not granted. Membership and colleges tables have SELECT only for these roles.

Do not interpret an RLS policy as a substitute for least-privilege table grants.

## 6. Functions and triggers

Observed private functions:
- `private.handle_campusconnect_user_signup()`: SECURITY DEFINER, owned by postgres, empty search_path, only postgres has EXECUTE in its ACL. It creates the student's profile from signup metadata. User metadata must not be used for authorization.
- `private.touch_updated_at()`: SECURITY INVOKER, empty search_path, postgres-owned.

Observed updated-at triggers exist on `applications`, `colleges`, `courses`, and `student_profiles`.

## 7. Index inventory

The live schema contains primary-key and supporting indexes across all nine tables. The registration-request indexes include:
- `college_registration_requests_email_idx` on `lower(contact_email)`
- `college_registration_requests_reviewed_by_idx` on `reviewed_by`
- `college_registration_requests_status_created_idx` on `(status, created_at DESC)`

Do not drop indexes solely because an advisor labels them unused; validate against actual workload and query history first.

## 8. Reconciliation decision

**Do not merge PR #3 or mutate the live migration ledger yet.**

The correct next sequence is:

1. Preserve this live-state snapshot and obtain a database schema-only export from the hosted project, including schemas, tables, constraints, indexes, policies, grants, functions and triggers.
2. Obtain the exact SQL/source or deployment evidence for migration versions `20261115120143` and `20261115120200`. Their ledger names alone are insufficient to reconstruct them safely.
3. Compare the export with the repository and PR branch, then establish a canonical migration baseline for future development without pretending the snapshot is the original migration history.
4. Resolve the unrecorded index migration through an explicit, reviewed migration-history reconciliation plan. Do not blindly replay the `CREATE INDEX IF NOT EXISTS` statement or insert a ledger row without verifying provenance and the intended deployment process.
5. Rebase/rework PR #3 only after the canonical migration source and current `main` history are understood.
6. Apply changes only after backup, review, approval and a tested rollback plan.

## 9. Scope and limitations

This audit was read-only. No SQL DDL/DML, migration-ledger repair, Auth setting change, PR merge, branch rebase, or deployment was performed.

The snapshot reflects the state returned by the connected Supabase project at the inspection time. It is not a penetration test, POPIA compliance assessment, or guarantee that every possible database object or external Auth setting has been inspected.
