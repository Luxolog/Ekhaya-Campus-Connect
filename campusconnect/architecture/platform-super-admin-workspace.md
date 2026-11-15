# CampusConnect Platform Super Admin Workspace — Product and Governance Specification

**Status:** Product, governance and security architecture only. No database objects, RLS policies, migrations, UI code, platform privileges or production workflows have been created or changed by this document.

## 1. Purpose and separation of authority

The Platform Super Admin Workspace is Ekhaya Technologies' internal control plane for operating CampusConnect as a multi-tenant service. It is separate from every college's administration workspace.

- **Platform operators** manage platform availability, tenant onboarding, platform-wide configuration, subscription products, support and security operations.
- **College administrators** manage their own institution, staff, admissions and academic operations within their tenant.
- **Students** manage their own profiles, applications, consent and learning access.
- Platform authority does not mean routine unrestricted access to student records. Support access to tenant/student data must be exceptional, purpose-limited, approved, time-bound and audited.
- A college cannot grant platform roles or access another tenant.
- Platform operator accounts must be separate from ordinary college memberships; never encode platform authority in a college role or user-editable auth metadata.

The platform control plane must not be reachable by ordinary college users merely by changing a URL or frontend role flag. Every route and server operation must enforce platform authorization independently.

## 2. Platform role model

Use a small fixed set of platform roles, with explicit capabilities:

| Platform role | Responsibility | Restrictions |
|---|---|---|
| platform_owner | Strategic ownership, appoints platform administrators, emergency governance | No routine direct student-record browsing; high-risk actions audited |
| platform_admin | Tenant lifecycle, initial college admin provisioning, platform configuration | Cannot silently inspect tenant content or bypass approval/audit |
| onboarding_reviewer | Reviews college registration, verifies evidence, recommends approve/decline | Cannot provision own privileged account or approve own request |
| billing_admin | Plans, subscriptions, invoices, credits and billing disputes | No access to academic/student records |
| integration_admin | Connector approval, integration credentials and sync operations | Access limited to integration metadata/secrets; tenant content only when approved |
| support_agent | Support tickets and scoped troubleshooting | No standing tenant data access; support session approval required |
| security_auditor | Security events, access reviews, audit evidence and incident oversight | Read-only where possible; cannot alter operational data |
| platform_developer | Platform configuration and deployment diagnostics | No production student-data access by default |

Roles are not necessarily mutually exclusive, but high-risk duties must be separated. Platform owner and platform admin assignment should require a controlled process and strong authentication. Prefer a permission catalogue with least privilege over a single unrestricted super-admin flag.

## 3. Platform navigation

Primary sections:
1. Platform Overview
2. Colleges & Tenants
3. Onboarding & Verification
4. Platform Administrators
5. Plans & Billing
6. Usage & Entitlements
7. Integrations
8. Support & Access Requests
9. Security & Audit
10. Platform Configuration
11. Service Health

Navigation is capability-filtered. Hiding a menu is not a security control; each API and database operation must verify the platform role and required capability.

## 4. Platform overview dashboard

Show operational aggregates, not unnecessary student-level records:
- Total tenants by status (pending, active, suspended, closed).
- New registration requests and age of review queue.
- Active colleges by operating mode (existing, full, hybrid).
- Subscription distribution, renewals, arrears and grace-period tenants.
- Platform usage: active staff/student accounts, applications, storage and messaging consumption, subject to defined metrics.
- Integration health: connected tenants, last successful sync, queued events and failures.
- Support ticket volumes, severity and response targets.
- Security alerts, privileged access sessions and unresolved incidents.
- Service status and scheduled maintenance.

Every metric must define its source, time window and tenant scope. Avoid exposing student names, ID numbers or application details on platform-wide dashboards. Drill-down requires a specific capability and, for personal data, a documented purpose.

## 5. College onboarding and tenant lifecycle

### 5.1 Registration request review
- Receive a college registration request with organisation details, contact person, requested operating mode and service requirements.
- Validate completeness and duplicate/impersonation indicators.
- Verify the organisation and authority of its representative using an approved process and evidence checklist.
- Record reviewer, decision, reason, evidence references and timestamps.
- Support states: submitted, under_review, more_information_required, approved, declined, withdrawn.
- The applicant can see only their own request status and required follow-up, not internal reviewer notes.

### 5.2 Tenant creation and activation
- Create a tenant only after approval.
- Assign a stable internal tenant ID and unique slug.
- Configure the operating mode: existing, full or hybrid.
- Record the institution's system-of-record boundaries and approved modules.
- Provision the initial college administrator through a platform-controlled, verified invitation.
- Tenant remains setup/pending until the initial administrator accepts and required setup checks pass.
- Activate public discovery only after profile/content approval.
- Every state transition is audited and reversible through a controlled process where appropriate.

### 5.3 Suspension, closure and reinstatement
Suspension may follow verified security risk, legal request, serious contract breach or unresolved billing status under the published terms. Billing suspension must follow a defined notice/grace process and must not delete student or academic data.

Before suspension:
- Record reason, evidence, approver and effective time.
- Notify designated college contacts unless prohibited for security/legal reasons.
- Define what remains available (e.g. read-only export, support and billing).
- Preserve data and audit history under retention policy.

Closure requires an approved data export/retention/deletion plan, legal hold check, tenant contact confirmation and documented completion. Never delete tenant data automatically on a subscription lapse.

## 6. College directory and tenant detail

Directory fields:
- College name, slug, legal/verification state.
- Tenant lifecycle status and operating mode.
- Primary contacts and initial administrator status.
- Enabled modules and integration ownership boundaries.
- Plan, subscription status and usage summary.
- Created/activated/suspended dates.
- Open support/security items.

Tenant detail tabs:
- Overview and setup readiness.
- Profile and public listing.
- Operating mode and module entitlements.
- Designated contacts and admin membership status.
- Subscription and invoices.
- Integration connections and sync health.
- Usage and limits.
- Support cases and approved support sessions.
- Security events and audit references.
- Data export/retention/closure.

Default tenant list and detail pages use metadata and aggregates. Student/application content is not included unless an approved, time-limited support session grants it.

## 7. Initial college administrator provisioning

- Platform onboarding reviewer approves the college and nominates an authorised representative.
- Platform admin creates a single-use invitation for the initial college administrator.
- Invitee must verify the invited email and accept before membership activation.
- Invitation token is high entropy, hashed at rest, single-use, expires (recommended seven days) and can be cancelled/reissued.
- The platform records the verification basis, inviter, invitee, acceptance and activation event.
- The initial college admin receives only the college_admin role within that tenant, not a platform role.
- Additional college_admin grants are managed by the college's two-person approval workflow or platform recovery process.
- Platform staff must not use a shared account or impersonate the college administrator.

## 8. Platform administrator management

Controls:
- Invite platform staff by verified email.
- Assign only approved platform roles/capabilities.
- Require MFA/strong authentication for privileged platform accounts.
- Separate requester and approver for platform_owner/platform_admin and other high-risk grants.
- Review active sessions, recovery methods and last-used dates.
- Suspend/revoke accounts immediately on termination or compromise.
- Conduct periodic access reviews and remove dormant/excess permissions.
- Emergency access is time-limited, reason-coded, notified and reviewed after use.

No self-promotion, self-approval or permanent emergency bypass. A break-glass process must have a documented trigger, dual control where feasible, automatic expiry and mandatory retrospective review.

## 9. Plans, subscriptions and billing

### 9.1 Plan catalogue
Define versioned plans with:
- Plan code/name and effective dates.
- Monthly/annual price and currency.
- Included modules and usage limits.
- Support tier and onboarding entitlements.
- Overage rules and optional add-ons.
- Trial, grace, suspension and cancellation terms.

Previously discussed Starter (R999), Growth (R1,999) and Professional (R3,999) amounts are indicative proposals only, not approved prices or live billing configuration.

### 9.2 Subscription lifecycle
States may include trial, active, past_due, grace_period, suspended, cancelled and expired. State transitions must be server-controlled and tied to billing provider events or approved manual adjustments.

- Keep invoices, payments, credits and adjustments auditable.
- Reconcile webhook events idempotently.
- Do not trust client-side payment success.
- Do not expose payment credentials or provider secrets.
- Manual credits/refunds require reason and appropriate approval.
- Plan changes record effective date and proration/contract treatment.
- Billing admins cannot view student records by virtue of billing access.

### 9.3 Entitlements
Enforce module and usage entitlements server-side. Subscription status is not an authorization mechanism and never overrides tenant RLS. If a tenant reaches a limit, show clear usage and upgrade paths; avoid destructive or silent blocking of critical student data access. Define grace and read-only behaviour contractually before implementation.

## 10. Usage metering

Meter only clearly defined events and quantities:
- Active staff seats and student accounts (define whether monthly active or provisioned).
- Applications created/processed.
- Storage used, with private-document lifecycle.
- Email/SMS/WhatsApp messages sent.
- Integration events/API calls.
- Optional support or onboarding hours.

Each metric needs:
- Definition and unit.
- Source event/table and aggregation window.
- Tenant attribution.
- Deduplication/idempotency key.
- Correction/reconciliation process.
- Retention and audit.
- Whether it is informational or billable.

Do not count failed/retried events twice. Do not meter or monetise student personal data itself. Never sell student data or create a commercial student-data marketplace.

## 11. Integrations governance

- Maintain an approved connector catalogue and supported versions.
- Record tenant, external system, vendor, contract/authorisation evidence, permitted data scopes, owner and expiry/review date.
- Approve integration access only for the named college and purpose.
- Store credentials in a server-side secret manager; display only masked metadata.
- Require signed webhooks, replay protection, idempotency and tenant binding.
- Monitor last success, failures, retries and dead-letter queues.
- Support pause, rotate and revoke controls.
- Do not scrape or automate external portals without written authorisation.
- Integration admins should see connection metadata by default, not full student payloads. Payload access for debugging requires approved, time-limited support access and redaction.

## 12. Support access and tenant-data privacy

Default support is metadata-only. If a support agent needs to inspect a tenant record:
1. A college-authorised contact opens or approves a support request and identifies the issue/purpose.
2. The request specifies the minimum tenant, record category and access duration required.
3. A designated approver authorises the access; the support agent cannot approve their own request.
4. Access is time-limited, read-only by default and restricted to the approved scope.
5. The college contact is notified unless a documented security/legal exception applies.
6. All viewed/exported records and actions are audited.
7. Access expires automatically and is reviewed after completion.

Write access or impersonation is exceptional and should require separate approval, explicit reason, visible support-session banner, restricted action set and immutable audit trail. Prefer reproducible diagnostics, redacted logs and tenant-provided test accounts over live personal-data access.

## 13. Security operations and incident management

Security workspace includes:
- Authentication and privileged access alerts.
- Suspicious tenant access patterns and cross-tenant denial events.
- RLS/policy change history and privileged database operations.
- Integration credential rotations and webhook failures.
- Export/download events and unusual volume.
- Platform administrator role changes and break-glass sessions.
- Vulnerability/incident tickets, severity, owner and response timeline.

Incident workflow:
1. Detect and classify severity.
2. Assign incident commander and responders.
3. Contain access, credential or integration risk.
4. Preserve relevant evidence and audit events.
5. Assess affected tenants and data categories.
6. Notify affected parties/regulators as required by legal advice and applicable obligations.
7. Remediate, validate and restore safely.
8. Record root cause, impact, corrective actions and lessons learned.

Do not expose incident details to unrelated tenants. Security-auditor access should be read-only wherever possible.

## 14. Audit and compliance

Platform audit events should cover:
- College request review, approval, decline and tenant lifecycle changes.
- Initial college admin invitation and activation.
- Platform role grants, approvals, suspensions and revocations.
- Support access requests, approvals, session start/end and data viewed/exported.
- Plan, price, invoice, credit, refund and entitlement changes.
- Integration approval, secret rotation, pause/resume and data-scope changes.
- Data export, retention, legal hold and closure actions.
- Security incidents, break-glass access and remediation.

Audit log design:
- Append-only to application roles.
- Server-generated timestamp and actor identity.
- Tenant context where relevant.
- Action, target reference, result, reason/ticket and correlation ID.
- Redact credentials, tokens, unnecessary personal data and sensitive payloads.
- Restrict read access to designated audit/security capabilities.
- Preserve retention and tamper-evidence controls.

This specification is not a legal compliance certification. POPIA roles, operator agreements, retention, incident reporting and student rights processes require legal/privacy review.

## 15. Platform configuration

Platform-wide configuration includes:
- Public brand, support contacts and service notices.
- Approved operating modes and module catalogue.
- Plan catalogue and entitlement definitions.
- Email/SMS/WhatsApp provider configuration.
- Feature flags and controlled rollout cohorts.
- Maintenance windows and service status.
- Data retention defaults and legal hold procedures.
- Allowed integration connectors and security requirements.

Changes to auth, data retention, pricing, entitlement enforcement, platform access or security controls require change review, approval and audit. Secrets are never shown after save.

## 16. Service health and operations

Provide operational views for:
- Application/API availability and latency.
- Database health and connection saturation.
- Authentication/email delivery health.
- Storage capacity and failed uploads.
- Queue depth, retry age and dead-letter events.
- Integration connector uptime.
- Backup success and restore-test evidence.
- Error rates and deployment status.

Service-health dashboards must avoid personal data and provide correlation IDs for troubleshooting. Define alert thresholds, on-call ownership, backup/restore objectives and disaster recovery procedures before production.

## 17. Platform permissions matrix

| Action | Owner | Platform admin | Onboarding reviewer | Billing admin | Integration admin | Support agent | Security auditor |
|---|---|---|---|---|---|---|---|
| Review college request | Oversight | Approve/assign | Review/recommend | None | None | None | Read audit |
| Create/activate tenant | Approve | Manage | Recommend | None | None | None | Read audit |
| Provision initial college admin | Approve/oversight | Execute | No | None | None | None | Read audit |
| Grant platform roles | Approve | Limited with dual control | None | None | None | None | Review |
| Manage plans/price | Approve | Limited | None | Manage with approval | None | None | Review |
| Manage invoices/credits | Oversight | Limited | None | Manage with approval | None | None | Review |
| Approve integrations | Oversight | Approve | None | None | Configure approved | None | Review |
| Tenant support access | Approve exceptions | Approve | None | None | Scoped technical | Request/use approved scope | Review |
| Security incidents | Oversight | Coordinate | None | None | Technical response | Report | Review |
| Audit review | Read | Read scoped | Own actions | Billing scope | Integration scope | Own support actions | Read broad audit |
| Platform config | Approve high-risk | Manage scoped | None | Billing config only | Connector config | None | Review |

This is a target governance matrix. The final platform capability map must be approved before implementation.

## 18. Acceptance and security tests

1. College administrator cannot access platform admin routes or APIs.
2. Platform billing admin cannot read student/application records.
3. Support agent cannot access tenant content without an approved active support session.
4. Support session expires automatically and cannot be extended by the agent alone.
5. Platform operator cannot grant themselves platform_owner or approve their own role request.
6. College onboarding cannot activate a tenant or admin before required verification/approval.
7. Tenant suspension follows the defined policy and never deletes academic records.
8. Subscription webhook replay cannot duplicate invoices, payments or entitlement transitions.
9. Client-side plan/role manipulation cannot unlock modules or cross-tenant data.
10. Integration admin cannot read full student payloads by default or access another tenant's connector.
11. Secret values and invitation tokens never appear in browser responses or audit logs.
12. Cross-tenant data queries remain denied even for a valid user from another tenant.
13. Exports require capability, reason and audit record.
14. Break-glass access expires and triggers retrospective review.
15. Audit events cannot be altered by ordinary platform operators.
16. Backups can be restored and the restore test is recorded.
17. Security incident workflow records affected scope, containment, notifications and remediation.

## 19. MVP implementation sequence

### Platform control plane MVP
1. Platform identity and strong-authentication model.
2. Fixed platform role/capability catalogue.
3. College registration review queue.
4. Tenant create/activate/suspend lifecycle.
5. Initial college admin invitation/provisioning.
6. Tenant directory and metadata-only detail.
7. Platform audit events and access reviews.

### Commercial and operations modules
8. Versioned plans and subscriptions.
9. Usage metering and billing reconciliation.
10. Integration catalogue and connector health.
11. Support requests and approved time-limited access.
12. Security operations, incidents and service health.
13. Data export/retention/closure workflows.

Do not build a global student browser as part of the platform admin MVP.

## 20. Open decisions before implementation

1. Which named people, if any, will hold platform_owner and platform_admin roles? Use individual accounts, never shared credentials.
2. Which identity provider and MFA requirement will be used for platform operators?
3. Who verifies college legal identity and authorised representatives, and what evidence is retained?
4. What is the approved tenant suspension/closure and data retention policy?
5. Which plan prices, usage metrics, billing provider and grace periods will be commercially approved?
6. Which support cases justify tenant-data access, and who approves them?
7. Which service health/incident response targets can Ekhaya Technologies actually support?
8. Which integrations are approved for the initial pilot?

## 21. Implementation boundary

This document specifies a proposed platform control plane. It does not mean platform super-admin functionality currently exists. The existing prototype's platform administration is localStorage-based demonstration functionality only. No database changes, production platform roles, RLS policies, billing configuration or privileged access workflows are authorised by this document.
