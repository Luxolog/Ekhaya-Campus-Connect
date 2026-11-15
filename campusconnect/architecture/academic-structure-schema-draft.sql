-- CAMPUSCONNECT ACADEMIC STRUCTURE SCHEMA DRAFT
-- DESIGN ONLY. DO NOT RUN AGAINST A LIVE DATABASE.
-- No final RLS policies or production grants are included.
-- Reconcile live schema/migration baseline and approve role model first.

-- PRE-REQUISITES:
-- 1. courses needs UNIQUE(college_id,id) before tenant-safe composite FK.
-- 2. college_memberships.role CHECK must be deliberately expanded.
-- 3. Decide whether offerings span multiple campuses.
-- 4. Confirm enrolment lifecycle and application-to-registration workflow.

CREATE TABLE public.campuses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  college_id uuid NOT NULL REFERENCES public.colleges(id),
  code text NOT NULL,
  name text NOT NULL,
  campus_type text NOT NULL DEFAULT 'physical' CHECK (campus_type IN ('physical','virtual')),
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
  term_type text NOT NULL CHECK (term_type IN ('semester','trimester','quarter','year','custom')),
  starts_on date NOT NULL,
  ends_on date NOT NULL,
  registration_opens_on date,
  registration_closes_on date,
  status text NOT NULL DEFAULT 'planned' CHECK (status IN ('planned','open','active','completed','cancelled')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (college_id, id),
  CHECK (ends_on >= starts_on),
  CHECK (registration_closes_on IS NULL OR registration_opens_on IS NULL OR registration_closes_on >= registration_opens_on)
);

CREATE TABLE public.course_offerings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  college_id uuid NOT NULL REFERENCES public.colleges(id),
  course_id uuid NOT NULL,
  academic_term_id uuid,
  campus_id uuid,
  offering_code text NOT NULL,
  delivery_mode text NOT NULL CHECK (delivery_mode IN ('campus','online','distance','correspondence','hybrid')),
  starts_on date,
  ends_on date,
  capacity integer,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','published','enrolling','in_progress','completed','cancelled')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (college_id, offering_code),
  UNIQUE (college_id, id),
  FOREIGN KEY (college_id, course_id) REFERENCES public.courses(college_id, id),
  FOREIGN KEY (college_id, academic_term_id) REFERENCES public.academic_terms(college_id, id),
  FOREIGN KEY (college_id, campus_id) REFERENCES public.campuses(college_id, id),
  CHECK (ends_on IS NULL OR starts_on IS NULL OR ends_on >= starts_on),
  CHECK (capacity IS NULL OR capacity > 0)
);

CREATE TABLE public.course_enrolments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  college_id uuid NOT NULL REFERENCES public.colleges(id),
  course_offering_id uuid NOT NULL,
  student_user_id uuid NOT NULL REFERENCES auth.users(id),
  source_application_id uuid REFERENCES public.applications(id),
  student_number text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','active','suspended','completed','withdrawn')),
  enrolled_at timestamptz,
  starts_on date,
  ends_on date,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (college_id, course_offering_id, student_user_id),
  UNIQUE (college_id, id),
  UNIQUE (college_id, id, course_offering_id),
  FOREIGN KEY (college_id, course_offering_id) REFERENCES public.course_offerings(college_id, id),
  CHECK (ends_on IS NULL OR starts_on IS NULL OR ends_on >= starts_on)
);

CREATE TABLE public.class_groups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  college_id uuid NOT NULL REFERENCES public.colleges(id),
  course_offering_id uuid NOT NULL,
  code text NOT NULL,
  name text NOT NULL,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive','archived')),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (college_id, code),
  UNIQUE (college_id, id),
  UNIQUE (college_id, id, course_offering_id),
  FOREIGN KEY (college_id, course_offering_id) REFERENCES public.course_offerings(college_id, id)
);

-- Many-to-many: one course enrolment may belong to several groups in the same
-- offering (e.g. lecture group A and tutorial group C).
CREATE TABLE public.class_group_enrolments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  college_id uuid NOT NULL REFERENCES public.colleges(id),
  course_offering_id uuid NOT NULL,
  class_group_id uuid NOT NULL,
  course_enrolment_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','ended','revoked')),
  assigned_at timestamptz NOT NULL DEFAULT now(),
  assigned_by uuid REFERENCES auth.users(id),
  starts_on date,
  ends_on date,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (college_id, id),
  UNIQUE (college_id, class_group_id, course_enrolment_id),
  FOREIGN KEY (college_id, class_group_id, course_offering_id)
    REFERENCES public.class_groups(college_id, id, course_offering_id),
  FOREIGN KEY (college_id, course_enrolment_id, course_offering_id)
    REFERENCES public.course_enrolments(college_id, id, course_offering_id),
  CHECK (ends_on IS NULL OR starts_on IS NULL OR ends_on >= starts_on)
);
-- The three-column composite foreign key ensures the enrolment and group
-- belong to the same course offering without relying on application checks.

CREATE TABLE public.class_group_staff (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  college_id uuid NOT NULL REFERENCES public.colleges(id),
  class_group_id uuid NOT NULL,
  membership_id uuid NOT NULL REFERENCES public.college_memberships(id),
  assignment_role text NOT NULL CHECK (assignment_role IN ('lecturer','teaching_assistant','class_coordinator')),
  starts_on date,
  ends_on date,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','ended','revoked')),
  assigned_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (college_id, class_group_id) REFERENCES public.class_groups(college_id, id),
  UNIQUE (college_id, class_group_id, membership_id, assignment_role),
  CHECK (ends_on IS NULL OR starts_on IS NULL OR ends_on >= starts_on)
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

-- ROLE MODEL CHANGE (NOT EXECUTED):
-- Review college_memberships.role CHECK to add lecturer, teaching_assistant,
-- attendance_officer and student_support. Never allow public self-assignment.

-- SECURITY REQUIREMENTS BEFORE DEPLOYMENT:
-- * Enable RLS on every new public table.
-- * Staff policies verify active membership for same college.
-- * Lecturer/assistant policies additionally verify current class_group_staff.
-- * Student policies resolve own access through course_enrolments and
--   class_group_enrolments (auth.uid() = student_user_id).
-- * A lecturer sees only assigned groups; a student sees only own groups.
-- * No anon writes to academic structures.
-- * UPDATE policies require SELECT visibility plus USING and WITH CHECK.
-- * Use composite tenant FKs; verify group and enrolment share same offering.
-- * Add indexes for college_id and common join/filter columns after query review.
-- * Audit enrolment transitions, group allocations, staff assignments and corrections.
