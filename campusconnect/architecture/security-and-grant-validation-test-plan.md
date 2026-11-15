# CampusConnect security and grant validation test plan

**Status:** Draft for non-production validation  
**Prepared:** 15 November 2026  
**Target project:** campusconnect-platform (reference only; do not execute this plan against production)  
**Purpose:** Validate least-privilege table grants, RLS isolation, tenant boundaries and trusted audit behaviour before any production ACL or policy change.

## 1. Safety boundary

This document is a test plan, not a migration. It contains no production-ready GRANT/REVOKE statements. Run tests only against a disposable Supabase development branch or a separate non-production project with synthetic identities and records.

Do not create test users, rows, buckets, functions or policies in the production project. Do not use service-role credentials in browser/client tests. Record the exact branch/project ref and migration head for every test run.

## 2. Verified baseline facts

The live project inspection on 15 November 2026 reported:
- Nine public application tables, all with RLS enabled and zero rows at inspection time.
- No Storage buckets and no Edge Functions at inspection time.
- Three migration ledger entries: 20261115120143, 20261115120200 and 20261115120448.
- All nine tables have FORCE ROW LEVEL SECURITY disabled.
- The PR #3 branch remains open and unmerged; its latest inspected head is 38b6552f1100e82fad00a9ab0765d4aded0416b7.
- Direct ACLs on several application tables and public-schema default privileges are broader than the current policy operations suggest.

These facts are a point-in-time baseline, not a certification or a guarantee that no external Auth configuration exists.

## 3. Synthetic test fixture

Create all fixtures only in non-production:
- College A and College B, both active.
- Student A and Student B, each with a distinct Auth identity and own profile.
- Staff A assigned to College A and Staff B assigned to College B.
- At least one staff identity per supported role: college_admin, admissions_staff and registrar.
- One published and one unpublished course per college.
- One consent per student/college pair as required by each test.
- One application and one document metadata record per student/college.
- Audit events for both colleges.

Never reuse real student or staff personal information.

## 4. Role and operation matrix to validate

This matrix is a proposed minimum based on the current policy definitions. Confirm frontend calls and server workflows before treating it as final.

| Table | anon | authenticated | Test focus |
|---|---|---|---|
| colleges | none | SELECT | Membership-scoped college visibility |
| college_memberships | none | SELECT | Own memberships only |
| student_profiles | none | SELECT, INSERT*, UPDATE | Own profile and consented college read; *review whether direct INSERT is still needed with signup trigger |
| courses | SELECT | SELECT, INSERT, UPDATE, DELETE | Published active-college reads; role-limited writes |
| student_consents | none | SELECT, INSERT, UPDATE | Student-owned consent and revocation; college visibility scope |
| applications | none | SELECT, INSERT, UPDATE** | Student submissions and scoped college access; **review direct UPDATE vs trusted workflow |
| application_documents | none | SELECT, INSERT | Applicant/college-party access and upload ownership |
| audit_events | none | SELECT | Scoped reads; no client mutation; trusted append path required |
| college_registration_requests | INSERT | INSERT | Pending/unreviewed-only submissions; no client read or mutation |

Do not grant TRUNCATE, REFERENCES or TRIGGER to anon/authenticated. Do not grant broad DELETE on tables that have no DELETE policy. Service-role access is server-side only and must never be exposed to browsers.

## 5. Test cases

### 5.1 Anonymous access
1. Read a published course belonging to an active college — expected allow.
2. Read an unpublished course — expected deny/no row.
3. Read a course belonging to a suspended/inactive college — expected deny/no row.
4. Read colleges, memberships, profiles, consents, applications, documents or audit events — expected deny.
5. Insert a well-formed college registration request with pending/unreviewed fields — expected allow.
6. Attempt a request with approved status, reviewed_at or reviewed_by populated — expected deny.
7. Attempt to read, update or delete a registration request — expected deny.

### 5.2 Student isolation
1. Student A reads and updates Student A profile — expected allow.
2. Student A reads or updates Student B profile — expected deny.
3. Student A grants consent to an active college with a valid purpose — expected allow.
4. Student A attempts consent for an inactive college or with invalid purpose — expected deny.
5. Student A revokes own active consent — expected allow.
6. Student A attempts to change another student's consent — expected deny.
7. Student A submits an application for self to a college with active consent — expected allow.
8. Student A submits for Student B or without active consent — expected deny.
9. Student A reads own application and document metadata — expected allow.
10. Student A reads Student B application/document metadata — expected deny.
11. Student A inserts document metadata with another user's uploaded_by or application_id — expected deny.

### 5.3 College tenant isolation
1. Staff A reads College A and its permitted records — expected allow.
2. Staff A reads College B applications, courses, consents or audit events — expected deny.
3. Staff A attempts to change an application college_id to College B — expected deny.
4. Staff A attempts to access an inactive/revoked membership — expected deny.
5. Staff A inserts or updates College A courses under an allowed role — expected allow.
6. Staff A inserts, updates or deletes College B courses — expected deny.
7. Validate each role separately; do not assume college_admin, admissions_staff and registrar have identical capabilities.
8. Attempt self-assignment or membership role escalation — expected deny; no client membership write policy should exist.

### 5.4 Application and audit integrity
1. Verify application state transitions are valid and attributable to an authorised staff capability.
2. Attempt to update status, student_id, college_id, course_id and submitted_at independently.
3. Verify course_id cannot reference a course belonging to a different college. The current FK references courses(id) alone; a tenant-safe composite relationship or trusted validation is still a design requirement.
4. Client INSERT/UPDATE/DELETE/TRUNCATE against audit_events — expected deny.
5. Trusted audit append records actor, college, event type, entity and timestamp; reject spoofed actor/tenant values.
6. Relevant staff can read only the audit events scoped to their college.

### 5.5 Default privileges and object creation
For every role that can create application objects (at minimum verify postgres and supabase_admin ownership contexts):
1. Create a disposable table in the test schema/public equivalent.
2. Inspect direct and effective privileges for anon, authenticated and service_role.
3. Create a disposable function and sequence; inspect EXECUTE and sequence privileges.
4. Verify new objects do not inherit unnecessary client privileges.
5. Confirm default ACL corrections do not remove required service-role access or break migration execution.
6. Drop only the disposable test objects after evidence capture.

### 5.6 Signup and trusted functions
1. Test signup-trigger profile bootstrap using synthetic Auth users.
2. Verify metadata only populates display fields and cannot assign roles or memberships.
3. Verify the SECURITY DEFINER function's owner, empty search_path and execute surface remain as designed.
4. Test profile update and recovery flows with the intended Auth redirect configuration in a controlled environment.
5. Confirm no service-role secret is present in client bundles, source maps, logs or browser requests.

## 6. Acceptance criteria

A test run passes only when:
- Every expected allow case succeeds and every expected deny case is blocked.
- Cross-college and cross-student reads/writes are denied.
- RLS remains enabled on every application table.
- Direct grants match the approved operation matrix; no unnecessary TRUNCATE, REFERENCES or TRIGGER grants remain for client roles.
- Default privileges for future objects are least-privilege for all relevant owners.
- Signup/profile bootstrap, published course discovery, consent, application, document and college-request flows still work.
- Audit records cannot be forged or modified by clients.
- The tenant-safe course/application relationship is enforced.
- Security advisor findings are reviewed, and automated tests are retained with the release evidence.
- The complete test evidence, project ref, migration head and reviewer sign-off are recorded.

A security advisor with no lint findings is not sufficient evidence of passing these tests.

## 7. Known unresolved design questions

1. Should student profile bootstrap be the only profile INSERT path?
2. Should application status transitions be moved to a trusted server-side function?
3. Which role may read consent records, and should that be narrower than general college membership?
4. What is the approved audit append mechanism and event schema?
5. Should course ownership be enforced by a composite foreign key involving college_id?
6. Which fields may students/staff update directly, and which require column-level grants or trusted server operations?
7. Which object owner(s) execute future migrations and therefore require default-privilege remediation?

## 8. Execution order

1. Recover missing migration sources and establish a canonical baseline strategy.
2. Create a non-production environment from the approved baseline.
3. Build synthetic fixtures and capture current behaviour before ACL changes.
4. Implement the proposed grant/default-privilege changes only in non-production.
5. Run the full test matrix and application smoke tests.
6. Review advisor output, logs and regression evidence.
7. Obtain explicit approval before preparing or applying any production migration.

## 9. Sign-off

| Role | Name | Decision | Date |
|---|---|---|---|
| Product owner | Pending | Pending | Pending |
| Database/security reviewer | Pending | Pending | Pending |
| Application reviewer | Pending | Pending | Pending |

**Current status:** Draft only. No production changes performed.
