create table if not exists public.college_registration_requests (
  id uuid primary key default gen_random_uuid(),
  institution_name text not null check (char_length(trim(institution_name)) between 2 and 180),
  registration_number text,
  website text,
  contact_name text not null check (char_length(trim(contact_name)) between 2 and 120),
  contact_email text not null check (char_length(trim(contact_email)) between 5 and 254),
  phone text not null check (char_length(trim(phone)) between 7 and 30),
  province text not null check (province in ('Eastern Cape','Free State','Gauteng','KwaZulu-Natal','Limpopo','Mpumalanga','Northern Cape','North West','Western Cape')),
  portal_mode text not null check (portal_mode in ('existing','full','hybrid')),
  notes text,
  status text not null default 'pending' check (status in ('pending','under_review','approved','declined')),
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.college_registration_requests enable row level security;
revoke all on public.college_registration_requests from anon, authenticated;
grant insert on public.college_registration_requests to anon, authenticated;
create policy "Anyone can submit a college registration request"
  on public.college_registration_requests for insert to anon, authenticated
  with check (status = 'pending' and reviewed_at is null and reviewed_by is null);
create index if not exists college_registration_requests_status_created_idx
  on public.college_registration_requests(status, created_at desc);
create index if not exists college_registration_requests_email_idx
  on public.college_registration_requests(lower(contact_email));
comment on table public.college_registration_requests is
  'Public-facing college onboarding applications. Requests remain private; Ekhaya reviews and provisions college access manually.';
