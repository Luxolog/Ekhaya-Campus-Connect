# CampusConnect — Expanded Platform Architecture and Foundation Gap Assessment

**Document status:** Architecture consolidation and inspection report.  
**Inspection date:** 15 November 2026.  
**Scope:** Existing GitHub repository and live Supabase project, plus the expanded seven-area product direction.  
**Change boundary:** Documentation only. No application source code, Supabase schema, policies, migrations, student accounts, production configuration, integrations or deployments were changed.

## 1. Executive summary

CampusConnect is expanding from its current student recruitment/admissions prototype and early account foundation into a multi-college platform with seven distinct service areas:

1. College Management.
2. Learning Management.
3. Jobs, including a dedicated Holiday Jobs section.
4. Work Experience.
5. Student Funding.
6. Student Wellness.
7. Partner Network and Integrations.

Jobs and Work Experience are separate modules with separate opportunity records, applications, approvals, placement lifecycle and outcome reporting. Holiday Jobs is a dedicated section within Jobs, not a shopping or product marketplace. CampusConnect will not include gadgets, consumer shopping or a retail marketplace.

The existing project remains the foundation. Preserve the current Supabase project `campusconnect-platform`, the GitHub repository `Luxolog/Ekhaya-Campus-Connect`, existing account onboarding work and the established academic/attendance architecture. Do not create a replacement project or rewrite the current prototype as a prerequisite.

The live database is healthy and small, but it is still an admissions/account foundation. The repository contains static HTML/CSS/JavaScript prototypes and architecture documents; it does not yet contain a complete production application stack, migration baseline or production tenant workflows. Several foundational security and migration issues must be resolved before feature tables are introduced.

**Recommended approach:** keep the seven modules as distinct bounded domains over shared identity, tenant, consent, permissions, audit, storage, notification and partner foundations. Build free/low-cost referrals and standards-based integrations first; only add paid providers where an approved use case requires them.

## 2. Inspection scope and evidence

### 2.1 GitHub repository inspected

Repository: [Luxolog/Ekhaya-Campus-Connect](https://github.com/Luxolog/Ekhaya-Campus-Connect)  
Default branch: `main`  
Visibility: public  
Latest inspected main tree commit: `129164364a714f8ab3ae7c53845e1186ded3d754`

The complete main tree was inspected. It contains:
- Root Tshwane College public website prototype (HTML/CSS/JavaScript).
- `campusconnect/index.html`: CampusConnect recruitment/admissions demonstration.
- `campusconnect/account.html`: Supabase Auth/profile account page.
- `student-portal/`: separate static student/lecturer LMS-style demonstration using browser localStorage.
- `career-finder.html`, programme pages and contact page.
- Existing CampusConnect architecture, academic structure, attendance/learning, college workspace, staff governance, platform admin and implementation blueprint documents.

The main branch does not currently contain `supabase/config.toml`, a `supabase/migrations/` directory, package manifest/build configuration, automated test suite or GitHub Actions workflow. The complete tree has no production Jobs, Holiday Jobs, Work Experience, Funding, Wellness or Partner Network application modules.

### 2.2 Existing pull requests and branches

The inspected repository has existing work that must be preserved:
- PR #2, “Build CampusConnect student recruitment and admissions pilot”: closed; its MVP work is part of the established project history.
- PR #3, “CampusConnect Phase 1 account onboarding”: still open on `campusconnect-phase1-auth`. Its branch contains the account onboarding changes and two college-registration-request migration files. Do not close, merge, rebase or overwrite it without explicit direction.
- PR #1, “Add internal operations dashboard and secure platform scaffold”: still open on `internal-operations-prototype`. It is a separate Tshwane College internal operations prototype, not a CampusConnect product module and not part of the CampusConnect Supabase schema. Keep it separate; do not merge its internal operations schema into `campusconnect-platform`.

The current main branch already contains the CampusConnect account page and prototype link, but its tree does not contain the PR #3 `supabase/migrations/` directory. This must be reconciled rather than assuming that an open PR's files are present on main.

### 2.3 Live Supabase project inspected

Existing project preserved:
- Name: `campusconnect-platform`
- Project ref: `owaiysaotqxtqfystigc`
- Region: `eu-west-1` (EU West 1)
- Status at inspection: `ACTIVE_HEALTHY`
- Database: PostgreSQL 17.11
- Public application tables: 9
- Rows reported by table inspection: 0 in each of the nine public tables
- Auth user count: 0
- Recorded Supabase migrations: 3
- Storage buckets: 0
- Supabase Edge Functions: 0

No student accounts were created. No data was inserted or modified.

### 2.4 Supabase health/advisors

- Security advisor returned no lint findings at inspection. This is not a security certification and does not replace policy testing.
- Health advisor returned no lint findings at inspection.
- Performance advisor reported 14 unused-index informational findings. Given the currently empty/low-traffic database, do not drop these indexes without workload evidence and a reviewed query plan.

## 3. Product architecture and module boundaries

### 3.1 Shared platform foundation

All modules use shared services, but module data and workflows remain bounded:
- Global student identity and profile.
- College tenant identity, membership and operating mode.
- Role/capability authorisation and assignment scopes.
- Purpose-specific consent and privacy preferences.
- Private document/resource storage.
- Audit and event history.
- Notifications and communications preferences.
- Partner/provider registry.
- Integration connection catalogue and event gateway.
- Search/discovery indexing with publication and privacy rules.
- Usage metering and subscription entitlements, where commercially enabled.

The shared foundation must not become a global unrestricted student-data pool. A module's need to display an opportunity does not grant the opportunity owner access to a student's full profile.

### 3.2 College Management

**Purpose:** Manage the institution's own operational and academic administration.

Scope:
- College profile, campuses and academic terms.
- Course catalogue and course offerings.
- Admissions CRM and application workflow.
- Student registration and enrolments.
- Multiple class groups per course offering.
- Staff invitations, role grants and teaching assignments.
- Timetable and class sessions.
- Attendance and academic administration.
- College reports, approved exports and integration health.
- College billing/plan view for authorised users.

Operating modes remain:
- Existing portal: CampusConnect provides recruitment, consent-led lead/application routing and approved synchronisation/hand-off; the college's existing system remains authoritative for the workflows assigned to it.
- Full portal: CampusConnect provides the agreed admissions/registration modules.
- Hybrid: the college adopts selected modules, with explicit system-of-record ownership per domain.

An accepted application is not automatically a registered student. A registrar-controlled, idempotent registration workflow creates the course enrolment. One enrolment may be assigned to several groups within the same offering through the existing planned many-to-many `class_group_enrolments` relationship.

### 3.3 Learning Management

**Purpose:** Deliver college-controlled learning through a shared LMS and classroom technology.

Scope:
- Course offerings, modules, lessons and learning resources.
- Live, recorded, reading and activity lesson types.
- Timetable and online classroom sessions.
- Student access and learning progress.
- Assignments, assessments and submissions after academic rules are approved.
- Lecturer/teaching assistant tools and scoped marking.
- Results and academic progress views.
- Attendance and class register integration.

Academic governance:
- College-managed teaching is the default.
- The college supplies/approves lecturers, content, assessments, marking and academic outcomes.
- CampusConnect supplies the LMS and classroom technology.
- Optional Ekhaya delivery support requires a separate service agreement and remains under the agreed academic governance.
- Ekhaya-managed courses require separate provider ownership and regulatory/accreditation review.

The existing `student-portal/` directory is a demonstration only. Its sample student/lecturer login uses localStorage and its test timer/scoring are browser-side demonstrations. It is not a production LMS and is not currently connected to the CampusConnect Supabase project.

### 3.4 Jobs, including dedicated Holiday Jobs

**Purpose:** Connect students and graduates with verified employment opportunities.

Jobs scope:
- Employer and recruiter verification.
- Employer accounts and scoped employer staff memberships.
- Job listings, categories, work location, work arrangement and closing dates.
- Entry requirements, eligibility, remuneration disclosure where supplied and application instructions.
- Student job profile and CV/document access with permission.
- Job applications, application events and employer communication.
- Saved jobs and alerts, subject to student preferences.
- Moderation, reporting, expiry and fraud/scam handling.
- Employer reporting limited to that employer's listings and applicants.

**Dedicated Holiday Jobs section:**
- A distinct student-facing section and route, with its own discovery filters and seasonal presentation.
- Holiday/seasonal job classification, availability window and application deadlines.
- Clear eligibility, age, location, schedule and remuneration information where verified.
- Separate reporting and campaign controls for holiday hiring periods.
- Can share the underlying job-posting and employer identity foundation, but must not be buried as an incidental filter in the general jobs interface.

Holiday Jobs remain employment opportunities. They are not internships, WIL placements or work-experience records.

### 3.5 Work Experience

**Purpose:** Coordinate structured workplace exposure and learning placements, not ordinary employment vacancies.

Supported types:
- Internships.
- Apprenticeships.
- Learnerships.
- Work-integrated learning (WIL).
- Job shadowing.

Scope:
- Verified placement hosts/employers.
- Placement opportunities and programme type.
- College course/qualification and WIL requirements where applicable.
- Student applications and selection.
- Placement approval and matching.
- Placement agreements and required approvals.
- Host supervisors and college coordinators.
- Start/end dates, schedules and expected hours.
- Logbooks, evidence and attendance/progress.
- Mentor feedback, evaluations and completion outcomes.
- Dispute, incident and early termination workflows.

**Boundary from Jobs:** a job application is not a placement application. A job offer does not create a work-experience placement. Placement records need structured host/college/student supervision, learning outcomes, agreements and completion evidence. A student may use the same verified employer identity in both modules, but the opportunities, applications and lifecycle records remain separate.

### 3.6 Student Funding

**Purpose:** Help students discover and apply for funding opportunities.

Funding types must be explicit and distinct:
- Bursaries.
- Sponsorships.
- Loans.

Scope:
- Verified funders and funding providers.
- Funding opportunities, award periods and application deadlines.
- Eligibility criteria and required documents.
- College/course/qualification eligibility.
- Student discovery and matching.
- Funding applications, status and missing-information requests.
- Award/decline outcome records where the provider confirms them.
- Renewal and progress requirements where applicable.
- Referral and application hand-off to provider systems.

**Loan boundary:** CampusConnect should initially provide verified information, eligibility discovery and a secure referral/application hand-off. It should not perform credit scoring, underwriting, loan origination, debt collection or promise loan approval. Loan products must be labelled as loans, with provider identity, repayment/interest/fee disclosures and appropriate legal/compliance review before publication.

Funding awards and disbursement must remain the responsibility of the funder/college unless a separately approved and legally reviewed payment arrangement is introduced. Do not treat a funding listing as a guaranteed award.

### 3.7 Student Wellness

**Purpose:** Connect students to appropriate wellness support while minimising sensitive data.

Two service pathways:
1. **Free referrals:** a student can discover or request a referral to a verified support provider/service without a counselling charge to the student, subject to the partner's actual terms.
2. **Sponsored counselling:** an approved sponsor funds a defined number or type of counselling sessions, vouchers or referrals. Availability and eligibility must be clear.

Scope:
- Verified wellness providers and service types.
- Referral directory and service availability.
- Student-initiated referral request and consent.
- Warm hand-off or secure provider referral.
- Sponsored-session eligibility, allocation and redemption.
- Appointment/referral status limited to operational metadata.
- Aggregated sponsor reporting and programme utilisation.
- Student feedback/complaint route and provider quality review.

**Sensitive-data boundary:**
- Treat wellness and counselling information as highly sensitive.
- Collect the minimum necessary referral metadata.
- Do not store diagnoses, therapy notes, clinical records, detailed symptoms or session transcripts in CampusConnect.
- Do not expose student identity or counselling details to sponsors. Sponsors receive aggregate utilisation and financial reconciliation data by default.
- Provider access is restricted to the specific referral and information the student has authorised or that is otherwise lawfully required.
- Consent, lawful basis, retention, emergency escalation and POPIA review must be completed before launch.
- CampusConnect is not an emergency service and must not imply continuous clinical availability. Provide clear local emergency/support escalation information approved by qualified partners.

### 3.8 Partner Network and Integrations

**Purpose:** Manage verified organisations and the partnerships that make CampusConnect useful.

Partner categories may include:
- Employers and recruiters.
- Work-experience hosts.
- Bursary, sponsorship and loan providers.
- Wellness and counselling providers.
- Colleges and education providers.
- Technology and integration partners.
- Student-support/referral organisations.

Scope:
- Partner onboarding, verification and approval.
- Partner organisation profile and contacts.
- Partnership type, agreement, owner, term and review date.
- Services/offers provided to students or colleges.
- Referral rules, eligibility and permitted data scope.
- Integration catalogue and connector ownership.
- API/webhook/file exchange configuration metadata.
- Connector health, sync events, retry and reconciliation.
- Partner performance and aggregate reporting.
- Partner suspension, renewal and offboarding.

The Partner Network is a relationship and service directory, not a consumer product-shopping marketplace. It must not introduce gadgets, retail catalogues or general product listings.


### 3.9 Education bookshops and study-material partners

CampusConnect should connect colleges and students with verified bookshops, campus bookstores, textbook suppliers, publishers and other approved education-material providers. This includes required college textbooks and prescribed reading lists, as well as study guides, past-paper resources and textbooks for learners preparing for matric rewrite / Amended Senior Certificate examinations.

The experience should support:
- College- and course-linked booklists, prescribed titles, editions, ISBNs and recommended reading.
- Discovery of nearby or online bookshops and suppliers that can fulfil a booklist.
- Availability, price indications, delivery/collection options and student discounts where providers supply current information.
- Direct links, contact/referral or approved affiliate hand-off to the bookshop's own checkout or ordering channel.
- Dedicated matric rewrite study-material discovery, clearly separated from college-specific prescribed textbooks.
- Provider verification, listing ownership, update dates, referral attribution and complaint handling.

**Commercial and product boundary:** this is an education-support partnership and referral capability within the Partner Network, not a CampusConnect retail marketplace. CampusConnect should not hold general retail stock, process bookshop orders or payments, or add unrelated consumer products. Start with free provider listings, bookshop-submitted information and direct links; consider affiliate arrangements only where agreed and transparent. Do not imply stock or pricing is live unless the provider supplies a verified update.

## 4. Shared architecture and data boundaries

### 4.1 Identity and tenant context

- One global authenticated student identity.
- College memberships and academic relationships are separate from the global student profile.
- Employer, funder, wellness provider and other partner accounts have scoped organisation memberships.
- Platform operator roles are distinct from college, employer and partner roles.
- A student chooses the college or service recipient for each application/referral.
- Tenant context is resolved server-side; never trust a client-supplied tenant ID as authority.
- Cross-tenant relationships use composite tenant-aware keys/foreign keys where relevant.

Some opportunities may be platform-wide or partner-wide rather than college-owned. Every record therefore needs an explicit ownership and visibility model, for example platform-published, college-published, employer-owned or partner-owned. Public visibility does not grant access to private applicant data.

### 4.2 Consent and data-sharing model

Use separate, purpose-specific grants for:
- College applications and admissions.
- Job applications to a named employer.
- Work-experience applications to a named host and college.
- Funding applications to a named funder.
- Wellness referrals to a named provider.
- Partner referral/communication where required.
- Optional marketing communications.

Record the notice/consent version, purpose, recipient, capture time, source, status and revocation history. Consent must not be bundled into a single blanket platform permission. Where another lawful basis is relied on, record and document it with legal/privacy review.

### 4.3 Role and capability model

Keep the existing proposed college roles and platform roles, and extend through a controlled capability catalogue rather than a single global role string.

Proposed additional organisation roles (final names and capabilities to be approved):
- Employer owner/admin, recruiter and hiring reviewer.
- Placement host coordinator and workplace supervisor.
- Funder administrator and funding reviewer.
- Wellness provider coordinator and counsellor/clinician access role (only to the provider-side referral information required).
- Partner administrator and integration operator.

A user may hold multiple scoped roles across organisations. No role in one organisation grants access to another organisation's records. Students do not become staff memberships merely because they apply for a job, placement, funding or wellness referral.

### 4.4 Storage and audit

- Private buckets/objects for CVs, application documents, placement evidence, agreements and learning resources.
- Separate storage scopes and retention rules by data class.
- Short-lived signed access only after server-side permission checks.
- No public storage URLs for private student records.
- Immutable event evidence for important state changes.
- Audit application decisions, placement approvals, funding decisions, wellness referral access, consent changes, document downloads, exports, role changes and partner integration operations.
- Do not put sensitive wellness details or raw credentials into audit payloads.

### 4.5 Notifications and messaging

Use a shared notification service with module-specific templates and preferences:
- Email first where it is free/low-cost and reliable.
- Optional SMS/WhatsApp after provider, consent, cost and opt-out review.
- Queue-based delivery, retry and idempotency.
- Avoid sensitive details in notification subject lines or lock-screen previews.
- Keep transactional service notifications separate from marketing.

## 5. Proposed domain model inventory (design only)

This is a logical inventory, not approved DDL. Reuse existing core tables and avoid duplicating the global student profile.

### Existing foundation
- `colleges`
- `college_memberships`
- `student_profiles`
- `courses`
- `student_consents`
- `applications`
- `application_documents`
- `audit_events`
- `college_registration_requests`

### College and learning
- `campuses`, `academic_terms`, `course_offerings`
- `course_enrolments`, `class_groups`, `class_group_enrolments`
- `class_group_staff`, `class_sessions`
- `course_modules`, `lessons`, `lesson_resources`
- `lesson_enrolments`, `online_classroom_sessions`
- Assessment, submission, marking and results entities only after academic governance is approved.

### Jobs
- `employers`, `employer_memberships`
- `job_posts`, `job_categories`, `job_applications`
- `job_application_events`, `saved_jobs`, `job_reports`

Holiday Jobs should use a dedicated route/section and explicit job classification/seasonality fields, with a distinct application and reporting experience where needed. It can reuse the verified employer and core job-posting foundation.

### Work Experience
- `placement_hosts`
- `placement_opportunities`
- `placement_applications`
- `placements`
- `placement_agreements`
- `placement_supervisors`
- `placement_logs`
- `placement_reviews`
- `placement_evidence`

Do not reuse `job_applications` as placement applications.

### Student Funding
- `funding_providers`
- `funding_opportunities`
- `funding_eligibility_rules`
- `funding_applications`
- `funding_application_events`
- `funding_awards` (provider-confirmed outcome metadata only)

### Student Wellness
- `wellness_providers`
- `wellness_services`
- `wellness_referrals`
- `counselling_sponsorships`
- `sponsored_session_allocations`
- `sponsored_session_redemptions`

Keep sensitive referral detail in a restricted data boundary. Do not create a clinical-record or therapy-notes module.

### Partner Network and integrations
- `partners`
- `partner_memberships`
- `partner_agreements`
- `partner_services`
- `partner_referrals`
- `integration_connectors`
- `integration_connections`
- `integration_events`
- `integration_sync_runs`

### Shared operational foundations still to design
- Role catalogue, capability grants and membership lifecycle.
- Invitations and approval workflow.
- Consent notices/versions and consent event history.
- Notifications, preferences and delivery events.
- Private file metadata and retention policy.
- Moderation/review queues and report handling.
- Audit event taxonomy and append-only write path.
- Feature/module entitlements and usage metering.
- Support cases and approved time-limited support sessions.
- Search index/projection with explicit public/private field allowlists.

## 6. Free integrations and partnership-first strategy

Use a low-cost decision hierarchy:

1. **Native/simple workflows:** public listings, provider links, secure email notifications, CSV import/export under permission controls.
2. **Open standards:** OAuth 2.0/OIDC, signed webhooks, standard REST APIs, calendar links, CSV/JSON exchange and documented file formats.
3. **Partner-provided/free tiers:** use only after checking usage limits, data processing terms, privacy, reliability, support and commercial sustainability.
4. **Open-source/self-hosted components:** consider where operational ownership, patching, backup, security and maintenance can be supported.
5. **Paid integration:** only where the use case is material, free alternatives are inadequate, the provider is approved and the ongoing cost is understood.

Do not assume that an integration is free simply because an API exists. Record provider pricing, free-tier limits, rate limits, data location, subprocessors, support obligations and exit/export options.

Partnership-first does not mean unrestricted data sharing. Each partner receives only the minimum information needed for the agreed referral or service.

## 7. Live foundation gap assessment

Priority:
- **P0 — blocker:** must be resolved before production student data or new production modules.
- **P1 — foundational:** required before the relevant module pilot.
- **P2 — module-specific:** required before that module goes live.
- **P3 — optimisation:** can follow initial controlled pilot.

### 7.1 Repository and delivery gaps

| Priority | Gap observed | Why it matters | Required foundation |
|---|---|---|---|
| P0 | Main branch has no `supabase/config.toml` or tracked `supabase/migrations/` baseline | Database changes cannot be reproduced safely from main | Reconcile and version a complete baseline without overwriting open PR work |
| P0 | Two open PRs remain unmerged; PR #3 contains migration files absent from main | Current main, PR branch and live DB history are not aligned | Review branch diffs and migration history; decide merge/reconciliation separately |
| P0 | No package/build manifest or automated test suite in the inspected main tree | No reproducible application build or automated regression/security gate | Choose application framework/toolchain and add pinned dependencies, lockfile, build and tests |
| P0 | Core application views remain static/localStorage demonstrations | No secure shared tenant workflow exists | Replace module-by-module with authenticated server/data operations only after security foundation |
| P1 | `student-portal/` is a separate localStorage LMS demonstration | It is not a production CampusConnect LMS | Decide whether to evolve its UX into the new LMS or use it as a reference; do not assume its data/auth is live |
| P1 | No documented CI, deployment, environment separation or rollback pipeline in main | Releases/configuration cannot yet be controlled reliably | Add development/test/production workflow, secret management and deployment gates |
| P1 | No module navigation, route map or feature entitlement catalogue for seven domains | Expanded product scope can become a monolith with unclear boundaries | Approve navigation, bounded contexts and role-specific entry points |
| P2 | Public GitHub repository contains prototypes | Public demo code is not suitable for confidential data or secrets | Keep secrets/data out of Git; decide whether production/private application code requires private repository/hosting |

### 7.2 Supabase schema and migration gaps

| Priority | Gap observed | Why it matters | Required foundation |
|---|---|---|---|
| P0 | Live migration history has 3 entries, but main has no migration directory and PR #3 contains only two later migration files | The original baseline and live changes are not reproducibly represented | Inventory exact live objects and reconstruct a reviewed baseline/migration history |
| P0 | Live `college_registration_requests_reviewed_by_idx` index was observed, but migration history list does not include a corresponding migration | Schema drift exists between live state and recorded migration history | Identify source of index and reconcile without dropping or recreating it blindly |
| P0 | Current schema has only 9 admissions/account tables | Seven-module platform has no domain data foundations | Design bounded module schemas after baseline and access model are approved |
| P0 | `college_memberships.role` permits only college_admin, admissions_staff and registrar | Cannot safely support lecturer, TA, attendance officer, student support or platform roles | Controlled role catalogue, membership lifecycle, multi-role grants and capability model |
| P0 | No tenant-aware composite FK from application to course | An application may reference a course belonging to a different college unless prevented elsewhere | Add/validate composite unique keys and composite foreign keys in a reviewed migration |
| P0 | Proposed academic draft needs `UNIQUE(college_id,id)` on courses and memberships before composite references | Draft SQL cannot be safely applied as-is | Resolve prerequisites and use tenant-aware composite foreign keys |
| P1 | No campuses, terms, offerings, enrolments, group allocation or staff assignment tables live | No formal academic lifecycle or class-group assignment exists | Approve and implement academic structure after RLS design |
| P1 | No dedicated class-group many-to-many bridge live | Multiple groups per course offering cannot be represented authoritatively | Implement `class_group_enrolments`; keep group assignment separate from enrolment |
| P1 | Attendance/learning SQL draft contains no actual RLS policies/grants and lacks the class-group enrolment/staff bridge found in the academic draft | Drafts are not a single coherent, deployable schema | Consolidate drafts, remove duplicate definitions and complete table-level security design |
| P1 | No Storage buckets exist and no storage policies were found | Document and learning-resource metadata cannot yet be backed by protected uploads | Design private buckets, object naming, RLS policies, retention and signed access |
| P1 | No Edge Functions exist | No deployed trusted API operations or connector gateway are present | Decide server-side runtime and implement authenticated/idempotent operations later |
| P1 | Audit table has a SELECT policy but no application INSERT policy was observed | A durable append-only audit write path is not established for normal application workflows | Design server-controlled audit writes and restrict update/delete paths |
| P1 | Current `applications` UPDATE policy permits the existing staff roles to update rows but has no explicit column-level/state-machine restrictions | Sensitive fields and status transitions need tighter workflow control | Move privileged transitions to trusted operations; add column/capability checks and transition audit |
| P1 | Current staff SELECT policies for applications/documents/consents rely on membership, not a lifecycle state or fine-grained capability | Current membership model has no active/suspended lifecycle | Add lifecycle and role/capability scope before broader data access |
| P1 | Current consent record stores free-text purpose and grant/revoke timestamps only | No consent notice version, recipient-purpose taxonomy or immutable consent event history | Design versioned purpose-specific consent grants and history |
| P1 | No platform operator role model or support-session data boundary live | Platform administration could otherwise be confused with tenant access | Implement separate platform identity, capabilities and audited time-limited support access |
| P1 | `audit_events` is not yet demonstrated as immutable against privileged application paths | Audit evidence may be incomplete | Append-only write service, restricted grants, event taxonomy and tamper review |
| P2 | Existing table grants to anon/authenticated include broad DML privileges on several tables, while RLS currently denies operations without policies | Grants are broader than the desired least-privilege design even though RLS is a row gate | Review explicit table/column grants separately from RLS; grant only required operations |
| P2 | Existing tables have RLS enabled but `FORCE ROW LEVEL SECURITY` is false | Owner/bypass roles may bypass policies; this is not automatically a defect but requires an explicit owner/service-role model | Document trusted database owners, service role usage and test execution contexts |

### 7.3 Current policy observations requiring remediation design

The following are observations of current live policies, not claims that data has been exposed:

- `applications` SELECT permits the student or any user with a membership in the application's college. The current policy does not check membership lifecycle or a finer capability.
- `application_documents` SELECT permits the applicant or any member of the related college. The current design does not distinguish admissions, registrar and other document-reading needs.
- `student_consents` SELECT permits the student or any member of the related college; a more granular purpose/capability model is needed.
- `student_profiles` SELECT uses the student's own row or an active consent joined to a college membership. This is a useful existing consent gate, but must be reconciled with versioned purposes and the new module-specific recipients.
- `applications` UPDATE has USING and WITH CHECK membership predicates for current staff roles, but no explicit allowed-column/state-transition workflow was observed.
- `courses` INSERT/UPDATE/DELETE policies allow college_admin and admissions_staff. Course catalogue governance should be reviewed before academic offerings are introduced.
- `college_registration_requests` is intentionally public INSERT-only with pending status checks; keep internal review private.
- `audit_events` has a staff SELECT policy; no client INSERT policy was observed.
- All nine public application tables have RLS enabled. This is a good starting point, not proof of complete tenant isolation.

The broad table grants and RLS predicates must be assessed together. RLS is not a substitute for least-privilege SQL grants, and a GRANT is not a substitute for row-level authorisation.

### 7.4 Existing functions and triggers

Two private functions were observed:
- `private.handle_campusconnect_user_signup()`: SECURITY DEFINER trigger function with an empty search_path; creates a student's own profile row from auth signup metadata.
- `private.touch_updated_at()`: SECURITY INVOKER timestamp trigger helper with an empty search_path.

Four public-table update triggers call `touch_updated_at()` on applications, colleges, courses and student_profiles. No public Edge Functions were listed. The signup trigger's SECURITY DEFINER use should remain narrowly scoped and be reviewed for ownership, execute grants, trigger binding and safe search_path; user-editable metadata must never be used as an authorisation claim.

### 7.5 Module-specific missing foundations

| Module | Missing foundations before pilot |
|---|---|
| College Management | Membership lifecycle, multi-role capabilities, tenant-safe academic keys, staff invitations, secure admissions state machine, official system-of-record mapping |
| Learning Management | Course offering/group foundations, lecturer assignment, private resource storage, progress model, assessment governance, online-class provider adapter |
| Jobs | Verified employer model, job posting moderation, private CV/document access, job application workflow, employer-scoped RLS, expiry/scam reporting |
| Holiday Jobs | Dedicated route and section, seasonal fields and filters, age/eligibility/legal review, clear temporary work terms, dedicated reporting |
| Work Experience | Separate host/opportunity/application/placement entities, college approval, agreements, supervisor assignments, hours/logbook/evidence and evaluation |
| Student Funding | Verified provider model, funding type distinction, eligibility rules, application lifecycle, provider hand-off, loan disclosure and legal review |
| Student Wellness | Restricted referral data boundary, provider verification, consent, minimum-data referral, sponsored allocation/redemption, sponsor aggregate-only reporting, privacy/clinical governance |
| Partner Network | Partner registry, verified organisation membership, agreements, service catalogue, referral scopes, connector inventory, partner lifecycle and performance governance |

## 8. Supabase Data API change relevant to future modules

Supabase's 2026 breaking-change notice states that new public-schema tables are no longer automatically exposed to the Data and GraphQL APIs by default, with enforcement across projects from 30 October 2026. CampusConnect's inspection date is after that enforcement date.

Therefore, future schema design must explicitly decide:
- Which tables are exposed through the Data API.
- Which roles receive table/column grants.
- Which tables remain private and are accessible only through trusted server-side operations.
- Which public views, if any, use `security_invoker` on PostgreSQL 15+.
- Which tables require RLS and which exact policy predicates apply.

Do not assume creating a table makes it reachable through the API. Do not expose sensitive wellness, internal partner, moderation, support or credential metadata tables merely for convenience.

Supabase CLI v3 also changed hosted-project command behavior: database commands default to local and hosted changes require explicit remote targeting/confirmation. Do not run CLI deployment commands as part of this inspection; future CLI work must follow the installed version's help and current docs.

## 9. Recommended foundation architecture before module development

Build the foundations in this order:

### Foundation A — repository and environment control
- Preserve current repo and open PR branches.
- Decide production application framework and runtime.
- Add package manifest/lockfile, environment separation and CI tests.
- Keep public prototype deployment separate from authenticated production services.
- Reconcile all migrations into version control.

### Foundation B — tenant, identity and access
- Global student identity.
- College, employer, funder, wellness provider and partner organisation identities.
- Membership lifecycle and invitation process.
- Multiple role grants and explicit capability catalogue.
- Platform roles separate from organisation roles.
- Tenant context and cross-tenant tests.

### Foundation C — privacy, consent and secure records
- Purpose-specific, versioned consent and revocation history.
- Lawful-basis register and privacy notice versions.
- Private storage and document metadata.
- Audit event catalogue and append-only trusted write path.
- Data retention, export, correction and deletion workflows.
- Wellness restricted data boundary.

### Foundation D — shared workflows
- Workflow/state-machine framework with actor/capability checks.
- Notifications and delivery queue.
- Moderation and reporting queues.
- Search and public publication projections.
- Partner referral tracking and integration event handling.
- Idempotency, retries and reconciliation.

### Foundation E — first modules
- College Management and admissions.
- Academic structure and LMS.
- Jobs and dedicated Holiday Jobs.
- Work Experience as a distinct placement lifecycle.
- Student Funding.
- Student Wellness.
- Partner Network and integrations.

## 10. Suggested delivery sequence

1. Reconcile live schema, migration history and main/PR branch state.
2. Approve tenant/organisation model, role/capability catalogue and consent model.
3. Implement and test identity, membership lifecycle, invitations and tenant isolation.
4. Implement College Management admissions and academic foundation.
5. Implement student LMS foundation and attendance gateway after academic groups/sessions.
6. Implement Jobs and dedicated Holiday Jobs.
7. Implement Work Experience with separate placements and supervision.
8. Implement Student Funding with verified providers and safe loan boundaries.
9. Implement Student Wellness referrals and sponsored counselling under strict data minimisation.
10. Implement Partner Network, partner agreements and integrations across all modules.
11. Add billing/entitlements only after the module and tenant boundaries are stable.
12. Complete security, privacy, operational and user acceptance testing before production onboarding.

The first end-to-end pilot should use synthetic accounts and test data. It should prove college onboarding, student account, application, registrar enrolment, multiple group allocation, LMS access, a job application, a work-experience placement workflow, a funding referral and a wellness referral without cross-tenant leakage. These should be staged rather than all launched at once.

## 11. Decisions to confirm before detailed module schemas

1. Which college is the first operational pilot, and is it existing-portal, full-portal or hybrid?
2. Should employer, funder and wellness-provider organisations be first-class tenants with their own admin portals, or partner workspaces within the platform initially?
3. Should Jobs be open to all verified employers, or only partner-approved employers at launch?
4. What is the minimum Holiday Jobs eligibility/age policy and who approves it?
5. Which Work Experience types are in the first pilot (WIL, internships, apprenticeships, learnerships, job shadowing)?
6. Will funding providers receive applications in CampusConnect or via provider hand-off initially?
7. For wellness, which verified provider(s) can offer free referrals and sponsored counselling, and who is the clinical/privacy governance contact?
8. Which student data may each partner receive, and who approves the data-sharing purpose?
9. Which existing college reader hardware models and protocols are available for a pilot?
10. Which free email, video classroom, calendar and integration providers are acceptable after privacy and terms review?

## 12. Explicit non-goals

- No gadgets or consumer shopping catalogue.
- No retail/product marketplace.
- No combining Jobs and Work Experience into one opportunity/application model.
- No automatic conversion of job applications into placements.
- No credit scoring, loan underwriting or debt collection in the initial Student Funding module.
- No storage of counselling notes, diagnoses or clinical records in CampusConnect.
- No unrestricted platform-wide student browser.
- No direct reader/device writes to Supabase.
- No scraping or unauthorised automation of college portals.
- No new Supabase project, student accounts, production configuration changes or database deployment as part of this work.

## 13. Implementation boundary and next gate

This document consolidates the expanded product architecture and records the current foundation gaps from the repository and live project inspection. It does not authorise implementation or deployment.

The next safe gate is a reviewed **Foundation Remediation Plan** with:
- a reconciled schema/migration baseline;
- an approved organisation/tenant and role model;
- a table-by-table RLS and grants matrix;
- consent, storage and audit design;
- a module dependency map;
- explicit test cases and rollback/restore plan.

Only after the user approves a specific implementation change should source code, database schema or production configuration be modified.
