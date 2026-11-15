-- CAMPUSCONNECT ATTENDANCE + LEARNING SCHEMA DRAFT
-- DESIGN ONLY. DO NOT RUN AGAINST A LIVE DATABASE.
-- Logical DDL sketch for review, not a migration.
-- Prerequisites: reconcile the live baseline, role model, RLS helpers,
-- storage policies, device gateway and exact reader integration contract.

CREATE TABLE public.campuses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  college_id uuid NOT NULL REFERENCES public.colleges(id),
  code text NOT NULL,
  name text NOT NULL,
  timezone text NOT NULL DEFAULT 'Africa/Johannesburg',
  address jsonb NOT NULL DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (college_id, code),
  UNIQUE (college_id, id)
);

CREATE TABLE public.academic_terms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  college_id uuid NOT NULL REFERENCES public.colleges(id),
  name text NOT NULL,
  starts_on date NOT NULL,
  ends_on date NOT NULL,
  status text NOT NULL DEFAULT 'planned' CHECK (status IN ('planned','active','completed','cancelled')),
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (ends_on >= starts_on),
  UNIQUE (college_id, id)
);

CREATE TABLE public.course_offerings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  college_id uuid NOT NULL REFERENCES public.colleges(id),
  course_id uuid NOT NULL REFERENCES public.courses(id),
  campus_id uuid,
  academic_term_id uuid,
  offering_code text NOT NULL,
  delivery_mode text NOT NULL CHECK (delivery_mode IN ('campus','online','distance','correspondence','hybrid')),
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','published','in_progress','completed','cancelled')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (college_id, offering_code),
  UNIQUE (college_id, id),
  FOREIGN KEY (college_id, campus_id) REFERENCES public.campuses(college_id, id),
  FOREIGN KEY (college_id, academic_term_id) REFERENCES public.academic_terms(college_id, id)
);
-- Add a composite FK from (college_id, course_id) to courses only after
-- confirming/adding a matching unique constraint to the existing courses table.

CREATE TABLE public.course_enrolments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  college_id uuid NOT NULL REFERENCES public.colleges(id),
  course_offering_id uuid NOT NULL,
  student_user_id uuid NOT NULL REFERENCES auth.users(id),
  enrolment_number text,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('pending','active','suspended','completed','withdrawn')),
  starts_on date,
  ends_on date,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (college_id, course_offering_id, student_user_id),
  UNIQUE (college_id, id),
  FOREIGN KEY (college_id, course_offering_id) REFERENCES public.course_offerings(college_id, id),
  CHECK (ends_on IS NULL OR starts_on IS NULL OR ends_on >= starts_on)
);

CREATE TABLE public.class_groups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  college_id uuid NOT NULL REFERENCES public.colleges(id),
  course_offering_id uuid NOT NULL,
  name text NOT NULL,
  code text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (college_id, code),
  UNIQUE (college_id, id),
  FOREIGN KEY (college_id, course_offering_id) REFERENCES public.course_offerings(college_id, id)
);

CREATE TABLE public.class_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  college_id uuid NOT NULL REFERENCES public.colleges(id),
  class_group_id uuid NOT NULL,
  title text NOT NULL,
  session_type text NOT NULL CHECK (session_type IN ('lecture','tutorial','laboratory','exam','workshop','other')),
  delivery_mode text NOT NULL CHECK (delivery_mode IN ('campus','online','hybrid')),
  starts_at timestamptz NOT NULL,
  ends_at timestamptz NOT NULL,
  attendance_opens_at timestamptz,
  attendance_closes_at timestamptz,
  room_label text,
  status text NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled','in_progress','completed','cancelled')),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (college_id, id),
  FOREIGN KEY (college_id, class_group_id) REFERENCES public.class_groups(college_id, id),
  CHECK (ends_at > starts_at),
  CHECK (attendance_closes_at IS NULL OR attendance_opens_at IS NULL OR attendance_closes_at >= attendance_opens_at)
);

CREATE TABLE public.course_modules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  college_id uuid NOT NULL REFERENCES public.colleges(id),
  course_offering_id uuid NOT NULL,
  title text NOT NULL,
  description text,
  sort_order integer NOT NULL DEFAULT 0,
  published boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (college_id, id),
  FOREIGN KEY (college_id, course_offering_id) REFERENCES public.course_offerings(college_id, id)
);

CREATE TABLE public.lessons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  college_id uuid NOT NULL REFERENCES public.colleges(id),
  module_id uuid NOT NULL,
  title text NOT NULL,
  lesson_type text NOT NULL CHECK (lesson_type IN ('live','recorded','reading','activity')),
  content jsonb NOT NULL DEFAULT '{}'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  published_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (college_id, id),
  FOREIGN KEY (college_id, module_id) REFERENCES public.course_modules(college_id, id)
);

CREATE TABLE public.lesson_resources (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  college_id uuid NOT NULL REFERENCES public.colleges(id),
  lesson_id uuid NOT NULL,
  storage_bucket text NOT NULL,
  storage_object_path text NOT NULL,
  resource_type text NOT NULL CHECK (resource_type IN ('document','video','audio','image','link','other')),
  title text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (college_id, id),
  FOREIGN KEY (college_id, lesson_id) REFERENCES public.lessons(college_id, id),
  UNIQUE (storage_bucket, storage_object_path)
);

CREATE TABLE public.online_classroom_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  college_id uuid NOT NULL REFERENCES public.colleges(id),
  class_session_id uuid NOT NULL,
  provider text NOT NULL,
  provider_meeting_ref text NOT NULL,
  status text NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled','started','ended','cancelled')),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (college_id, id),
  FOREIGN KEY (college_id, class_session_id) REFERENCES public.class_sessions(college_id, id)
);
-- Provider credentials, meeting passwords and signed join tokens belong in a
-- server-side secret store / short-lived server response, never in this table.

CREATE TABLE public.student_cards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  college_id uuid NOT NULL REFERENCES public.colleges(id),
  student_user_id uuid NOT NULL REFERENCES auth.users(id),
  technology text NOT NULL CHECK (technology IN ('nfc','rfid')),
  credential_fingerprint bytea NOT NULL,
  card_label text,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','lost','revoked','expired')),
  issued_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (college_id, credential_fingerprint),
  UNIQUE (college_id, id),
  CHECK ((status <> 'revoked') OR revoked_at IS NOT NULL)
);
-- Fingerprint must be keyed (HMAC) by a server-held secret. Never store raw
-- card UIDs if avoidable. Credential resolution is server-side only.

CREATE TABLE public.attendance_devices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  college_id uuid NOT NULL REFERENCES public.colleges(id),
  campus_id uuid,
  vendor text NOT NULL,
  model text,
  connector_type text NOT NULL CHECK (connector_type IN ('vendor_api','webhook','local_gateway','standard_protocol','manual_import')),
  external_device_id text NOT NULL,
  capabilities jsonb NOT NULL DEFAULT '{}'::jsonb,
  secret_reference text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','active','offline','disabled','quarantined')),
  last_seen_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (college_id, external_device_id),
  UNIQUE (college_id, id),
  FOREIGN KEY (college_id, campus_id) REFERENCES public.campuses(college_id, id)
);
-- secret_reference points to a server-side vault entry; no device secret in DB.

CREATE TABLE public.attendance_device_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  college_id uuid NOT NULL REFERENCES public.colleges(id),
  device_id uuid,
  source_event_id text NOT NULL,
  idempotency_key text NOT NULL,
  student_user_id uuid REFERENCES auth.users(id),
  class_session_id uuid,
  card_id uuid,
  event_kind text NOT NULL CHECK (event_kind IN ('tap_in','tap_out','qr_checkin','manual_checkin','online_join','online_leave','unknown')),
  occurred_at timestamptz NOT NULL,
  received_at timestamptz NOT NULL DEFAULT now(),
  verification_status text NOT NULL CHECK (verification_status IN ('verified','rejected','needs_review')),
  rejection_reason text,
  sanitised_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  UNIQUE (college_id, idempotency_key),
  UNIQUE (college_id, source_event_id),
  FOREIGN KEY (college_id, device_id) REFERENCES public.attendance_devices(college_id, id),
  FOREIGN KEY (college_id, class_session_id) REFERENCES public.class_sessions(college_id, id),
  FOREIGN KEY (college_id, card_id) REFERENCES public.student_cards(college_id, id)
);
-- Append-only. Device gateway/service writes; end-user clients do not.

CREATE TABLE public.attendance_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  college_id uuid NOT NULL REFERENCES public.colleges(id),
  class_session_id uuid NOT NULL,
  student_user_id uuid NOT NULL REFERENCES auth.users(id),
  status text NOT NULL DEFAULT 'pending_review' CHECK (status IN ('present','late','absent','excused','pending_review')),
  first_check_in_at timestamptz,
  last_event_at timestamptz,
  attendance_minutes integer,
  calculation_version integer NOT NULL DEFAULT 1,
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (college_id, class_session_id, student_user_id),
  FOREIGN KEY (college_id, class_session_id) REFERENCES public.class_sessions(college_id, id),
  CHECK (attendance_minutes IS NULL OR attendance_minutes >= 0)
);

CREATE TABLE public.attendance_adjustments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  college_id uuid NOT NULL REFERENCES public.colleges(id),
  attendance_record_id uuid NOT NULL,
  previous_status text,
  new_status text NOT NULL CHECK (new_status IN ('present','late','absent','excused','pending_review')),
  reason text NOT NULL,
  requested_by uuid NOT NULL REFERENCES auth.users(id),
  reviewed_by uuid REFERENCES auth.users(id),
  reviewed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (college_id, attendance_record_id) REFERENCES public.attendance_records(college_id, id)
);
-- Append-only; approval and permission checks enforced server-side/RLS.

CREATE TABLE public.qr_attendance_challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  college_id uuid NOT NULL REFERENCES public.colleges(id),
  class_session_id uuid NOT NULL,
  token_hash bytea NOT NULL UNIQUE,
  created_by uuid NOT NULL REFERENCES auth.users(id),
  expires_at timestamptz NOT NULL,
  revoked_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (college_id, class_session_id) REFERENCES public.class_sessions(college_id, id)
);
-- Only token hash is persisted. Token is random, short-lived, session-bound,
-- rate-limited, and redeemed through a server-side endpoint.

CREATE TABLE public.online_presence_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  college_id uuid NOT NULL REFERENCES public.colleges(id),
  class_session_id uuid NOT NULL,
  student_user_id uuid NOT NULL REFERENCES auth.users(id),
  provider text NOT NULL,
  provider_event_id text NOT NULL,
  event_kind text NOT NULL CHECK (event_kind IN ('joined','left')),
  occurred_at timestamptz NOT NULL,
  received_at timestamptz NOT NULL DEFAULT now(),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  UNIQUE (college_id, provider, provider_event_id),
  FOREIGN KEY (college_id, class_session_id) REFERENCES public.class_sessions(college_id, id)
);

-- REQUIRED BEFORE PRODUCTION (intentionally not included as copy/paste policies):
-- 1. RLS enabled on every table above.
-- 2. College membership/capability policies for each operation.
-- 3. Student SELECT policies scoped to own active enrolment/records.
-- 4. Lecturer access scoped to assigned class groups and offerings.
-- 5. Registrar/attendance officer access separately scoped.
-- 6. No anon/authenticated INSERT/UPDATE on device events or card fingerprints.
-- 7. Server gateway validates device signatures, replay, timestamps,
--    college/device binding, card status, enrolment and session eligibility.
-- 8. Private Storage bucket policies for lesson_resources.
-- 9. Composite foreign keys/checks for college ownership where parent tables
--    have matching unique constraints.
-- 10. Indexes on college_id, student_user_id, session dates, device_id,
--     event timestamps and active card lookups; validate with query plans.
-- 11. Explicit grants and Data API exposure review in addition to RLS.
