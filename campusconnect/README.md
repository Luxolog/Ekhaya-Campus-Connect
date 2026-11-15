# CampusConnect — Tshwane College Pilot

**Powered by Ekhaya Technologies**

CampusConnect is a student recruitment, course discovery, application tracking and admissions workflow product. The product is designed for institutions with an existing student portal and institutions that need a complete admissions portal.

## Open the prototype

Serve this folder as a static site and open `index.html`. The demo is also reachable from the repository's GitHub Pages deployment at:

`https://luxolog.github.io/tshwane-college-website/campusconnect/`

## Two institution operating modes

### 1. Existing student portal — integration mode
CampusConnect is the recruitment and admissions-conversion layer:
- Course discovery and institution comparison
- Student enquiry capture and qualification
- Consent-led application routing
- Admissions CRM and follow-up pipeline
- Status synchronisation where an approved API is available
- Secure hand-off / export for systems without APIs

The college remains system of record for its official applications, admission decisions, fees and registration. Integration options must be agreed with each institution; never scrape or automate a portal without written authorisation.

### 2. No existing student portal — full portal mode
CampusConnect can provide:
- Branded student application journey
- Institution course and intake catalogue
- Applicant records and admissions CRM
- Document checklist and protected uploads
- Appointment booking and digital queue
- Offers, registration checklist and enrolment reporting

### 3. Hybrid mode
An institution can start with recruitment and CRM, then adopt selected admissions modules over time.

## Included in this MVP demo

- Responsive student-facing course finder
- Filters for province and study mode
- Student enquiry/application form
- Explicit application-sharing consent and separate optional marketing consent controls
- Demo student application list
- College admissions dashboard
- Applicant search and status pipeline
- CSV export of demo applicants
- Campus appointment queue demonstration
- Ekhaya platform institution directory and portal-mode configuration
- Proposed Starter, Growth and Professional subscription display

## Important prototype limitations

This is a **front-end demonstration only**:
- Demo applications and settings are saved in the current browser's localStorage.
- Seed records are fictional.
- No real authentication, role isolation, central database, API integration, messaging, file uploads, payment processing or production queue service is connected.
- Do not enter real student personal information, ID numbers, academic records or upload confidential documents.
- The sample institution/course listings, prices and statuses are illustrative and are not confirmation of live availability, accreditation, fees or admission.

## Recommended production architecture

- Next.js application for student, institution and platform-admin workspaces.
- Supabase PostgreSQL, Auth, Storage and Row Level Security, or an equivalent managed backend.
- Multi-tenant data model with `institution_id` on institutional records and strict row-level access policies.
- Central student profile with explicit, purpose-specific sharing grants to selected institutions.
- Each college's own applicant workspace; no institution can browse another institution's applicant records.
- Integration adapter per institution: API/webhook first, then approved secure file exchange or staff-managed hand-off.
- Audit log for profile access, consent, exports, application routing and status changes.
- Protected document storage, retention rules, deletion/rights workflows and encrypted transport.
- Server-side notifications and queue/appointment services.
- Subscription billing and metering for college tenants.

## Suggested core entities

- `students`, `student_profiles`, `consent_grants`
- `institutions`, `institution_users`, `campuses`
- `courses`, `intakes`, `entry_requirements`
- `applications`, `application_status_events`, `assignments`
- `documents`, `document_requirements`
- `appointments`, `queue_tickets`
- `integration_connections`, `integration_events`
- `subscriptions`, `audit_events`

## POPIA and data governance

Student data is not a list that can be sold or made visible to all colleges. The production service must document the responsible party/operator roles, lawful purpose, minimum necessary data, security safeguards, retention schedule, student rights and incident response. Sharing an application with a college must be clear and purpose-specific. Marketing consent must be separate from application processing. Legal review is required before launch.

## Commercial model to validate

Indicative proposals only:
- Starter: R999/month
- Growth: R1,999/month
- Professional: R3,999/month
- Separate onboarding, white-label setup, custom integration and usage-based messaging fees where appropriate.

## Next development milestones

1. Approve product requirements and confirm Tshwane College's official course/intake data.
2. Create Supabase production project and schema, tenant policies and authentication.
3. Implement student accounts, consent grants and secure document storage.
4. Implement college users, roles, admissions CRM and workflow configuration.
5. Build institution integration adapters and test with an authorised portal/API.
6. Add WhatsApp/email/SMS provider, appointment booking and queue check-in.
7. Add subscription billing, monitoring, backups and audit exports.
8. Complete security, privacy, accessibility and user acceptance testing before real student onboarding.

## Brand

The existing Tshwane College public website remains the institutional website. CampusConnect is presented as the platform layer, powered by Ekhaya Technologies. Official college branding, programme data and admissions rules must be approved by Tshwane College before public production use.


## Phase 1 account onboarding (implementation)

- Student registration uses Supabase Auth email/password. Email confirmation is required before password sign-in (hosted Supabase default; verify in Auth settings).
- Student profile rows are created by the existing Auth signup trigger. Students can read and update only their own profile; institution access remains consent-controlled by RLS.
- Colleges submit a public onboarding request at `account.html`. The request is inserted with a server-enforced `pending` status and is not readable by public or authenticated clients.
- Ekhaya reviews requests in the Supabase dashboard. Approval and college user provisioning are intentionally manual in Phase 1; a submitted request never creates a college, membership or login automatically.
- Configure the Supabase Auth Site URL and allowed redirect URL to include the exact GitHub Pages account page URL before testing email confirmation and password reset.
- The public publishable key is used in the browser. No service-role or secret key is included in frontend files.

The original prototype dashboards still contain localStorage demo data and must not be used for real admissions operations until those workflows are migrated to authenticated, tenant-scoped database queries.
