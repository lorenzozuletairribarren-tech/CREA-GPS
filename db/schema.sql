-- CREA Arica - Esquema inicial (PostgreSQL 15+)
-- Cobertura: operación administrativa + clínica + portal paciente/apoderado

create extension if not exists "pgcrypto";

-- =========================
-- ENUMS / CATÁLOGOS
-- =========================
create type public.app_role as enum (
  'GERENTE_ADMIN',
  'RECEPCION_ADMIN',
  'PROFESIONAL_CLINICO',
  'SUPERVISOR_CLINICO',
  'PACIENTE_APODERADO'
);

create type public.invitation_status as enum ('PENDIENTE', 'ACEPTADA', 'EXPIRADA', 'REVOCADA');
create type public.person_type as enum ('PACIENTE', 'APODERADO', 'PROFESIONAL', 'ADMINISTRATIVO', 'OTRO');

create type public.appointment_type as enum ('INDIVIDUAL', 'GRUPAL', 'EVALUACION', 'REUNION_APODERADO');
create type public.appointment_status as enum ('AGENDADA', 'CONFIRMADA', 'CANCELADA', 'REPROGRAMADA', 'FINALIZADA');
create type public.checkin_status as enum ('LLEGO', 'EN_ESPERA', 'EN_SESION', 'FINALIZO', 'AUSENTE', 'JUSTIFICADO');

create type public.payment_method as enum ('EFECTIVO', 'TRANSFERENCIA', 'TARJETA', 'BONO_FONASA', 'OTRO');
create type public.payment_status as enum ('PENDIENTE', 'PAGADO', 'ANULADO', 'REEMBOLSADO');

create type public.clinical_note_status as enum ('BORRADOR', 'FINALIZADA', 'BLOQUEADA');
create type public.document_visibility as enum ('INTERNO', 'CLINICO', 'PORTAL');

-- =========================
-- IDENTIDAD Y SEGURIDAD
-- =========================
create table public.users_profile (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique not null,
  email text not null unique,
  full_name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id) on delete cascade,
  role public.app_role not null,
  created_at timestamptz not null default now(),
  unique (user_id, role)
);

create table public.user_invitations (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  role public.app_role not null,
  invited_by uuid not null references public.users_profile(id),
  status public.invitation_status not null default 'PENDIENTE',
  token text not null unique,
  expires_at timestamptz not null,
  accepted_by uuid references public.users_profile(id),
  created_at timestamptz not null default now()
);

create table public.audit_log (
  id bigserial primary key,
  actor_user_id uuid references public.users_profile(id),
  action text not null,
  target_table text not null,
  target_id text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- =========================
-- PERSONAS, PACIENTES Y ADMISIÓN
-- =========================
create table public.people (
  id uuid primary key default gen_random_uuid(),
  person_type public.person_type not null,
  run text,
  first_name text not null,
  middle_name text,
  last_name text not null,
  second_last_name text,
  birth_date date,
  phone text,
  email text,
  address text,
  commune text,
  region text default 'Arica y Parinacota',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.patients (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null unique references public.people(id) on delete cascade,
  ficha_code text not null unique,
  preferred_name text,
  school_name text,
  health_insurance text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.patient_guardians (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id) on delete cascade,
  guardian_person_id uuid not null references public.people(id) on delete cascade,
  relationship text not null,
  is_primary boolean not null default false,
  legal_guardian boolean not null default false,
  portal_user_id uuid references public.users_profile(id),
  created_at timestamptz not null default now(),
  unique (patient_id, guardian_person_id)
);

create table public.pre_admissions (
  id uuid primary key default gen_random_uuid(),
  source text not null default 'PUBLIC_WEB',
  applicant_name text not null,
  applicant_email text,
  applicant_phone text,
  patient_name text not null,
  patient_birth_date date,
  concern_reason text,
  status text not null default 'PENDIENTE',
  reviewed_by uuid references public.users_profile(id),
  reviewed_at timestamptz,
  internal_notes text,
  created_at timestamptz not null default now()
);

-- =========================
-- RRHH
-- =========================
create table public.staff_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users_profile(id) on delete cascade,
  person_id uuid not null unique references public.people(id),
  profession text,
  speciality text,
  hire_date date,
  contract_type text,
  signature_image_url text,
  created_at timestamptz not null default now()
);

create table public.staff_documents (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid not null references public.staff_profiles(id) on delete cascade,
  doc_type text not null,
  file_url text not null,
  signed_at timestamptz,
  created_by uuid references public.users_profile(id),
  created_at timestamptz not null default now()
);

create table public.internal_requests (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid not null references public.staff_profiles(id) on delete cascade,
  request_type text not null,
  description text not null,
  status text not null default 'PENDIENTE',
  resolved_by uuid references public.users_profile(id),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

-- =========================
-- AGENDA, RECEPCIÓN Y COBROS
-- =========================
create table public.professional_availability (
  id uuid primary key default gen_random_uuid(),
  professional_user_id uuid not null references public.users_profile(id) on delete cascade,
  weekday smallint not null check (weekday between 0 and 6),
  start_time time not null,
  end_time time not null,
  slot_minutes integer not null default 45 check (slot_minutes in (30, 45, 60, 90)),
  created_at timestamptz not null default now(),
  check (start_time < end_time)
);

create table public.appointments (
  id uuid primary key default gen_random_uuid(),
  appointment_type public.appointment_type not null,
  status public.appointment_status not null default 'AGENDADA',
  patient_id uuid references public.patients(id),
  title text,
  room text,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  created_by uuid not null references public.users_profile(id),
  notes text,
  created_at timestamptz not null default now(),
  check (starts_at < ends_at),
  check (
    (appointment_type = 'GRUPAL' and patient_id is null)
    or
    (appointment_type <> 'GRUPAL' and patient_id is not null)
  )
);

create table public.appointment_professionals (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  professional_user_id uuid not null references public.users_profile(id),
  unique (appointment_id, professional_user_id)
);

create table public.group_session_participants (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  patient_id uuid not null references public.patients(id) on delete cascade,
  unique (appointment_id, patient_id)
);

create table public.checkins (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null unique references public.appointments(id) on delete cascade,
  status public.checkin_status not null default 'LLEGO',
  arrived_at timestamptz,
  updated_by uuid references public.users_profile(id),
  updated_at timestamptz not null default now()
);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id),
  appointment_id uuid references public.appointments(id),
  amount_clp integer not null check (amount_clp >= 0),
  payment_method public.payment_method not null,
  payment_status public.payment_status not null default 'PAGADO',
  reference_number text,
  metadata jsonb not null default '{}'::jsonb,
  received_by uuid references public.users_profile(id),
  paid_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table public.appointment_confirmations (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  channel text not null check (channel in ('WHATSAPP', 'EMAIL')),
  recipient text not null,
  sent_at timestamptz,
  status text not null default 'PENDIENTE',
  provider_message_id text,
  created_at timestamptz not null default now()
);

-- =========================
-- CLÍNICA, EVALUACIÓN, FICHA E INFORMES
-- =========================
create table public.patient_records (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null unique references public.patients(id) on delete cascade,
  anamnesis text,
  clinical_history text,
  current_diagnosis text,
  allergies text,
  medications text,
  alerts text,
  updated_by uuid references public.users_profile(id),
  updated_at timestamptz not null default now()
);

create table public.therapy_plans (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id),
  created_by uuid not null references public.users_profile(id),
  goals jsonb not null,
  interventions jsonb not null,
  start_date date not null,
  end_date date,
  status text not null default 'ACTIVO',
  created_at timestamptz not null default now()
);

create table public.clinical_sessions (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid unique references public.appointments(id) on delete set null,
  patient_id uuid not null references public.patients(id),
  professional_user_id uuid not null references public.users_profile(id),
  session_date date not null,
  duration_minutes integer not null check (duration_minutes between 15 and 240),
  objective text,
  summary text,
  next_steps text,
  note_status public.clinical_note_status not null default 'BORRADOR',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.home_tasks (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id),
  clinical_session_id uuid references public.clinical_sessions(id) on delete cascade,
  description text not null,
  due_date date,
  status text not null default 'PENDIENTE',
  visible_in_portal boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.assessment_instruments (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  domain text,
  description text,
  created_at timestamptz not null default now()
);

create table public.assessment_results (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id),
  instrument_id uuid not null references public.assessment_instruments(id),
  applied_by uuid not null references public.users_profile(id),
  applied_on date not null,
  raw_scores jsonb not null,
  interpreted_result text,
  recommendations text,
  created_at timestamptz not null default now()
);

create table public.document_templates (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  template_body text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.generated_documents (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id),
  template_id uuid not null references public.document_templates(id),
  generated_by uuid not null references public.users_profile(id),
  approved_by uuid references public.users_profile(id),
  title text not null,
  content text not null,
  file_url text,
  visibility public.document_visibility not null default 'CLINICO',
  signed_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.patient_documents (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id),
  uploaded_by uuid references public.users_profile(id),
  document_type text not null,
  file_url text not null,
  visibility public.document_visibility not null default 'INTERNO',
  created_at timestamptz not null default now()
);

create table public.portal_requests (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id),
  requested_by_user_id uuid not null references public.users_profile(id),
  request_type text not null,
  details text,
  status text not null default 'PENDIENTE',
  handled_by uuid references public.users_profile(id),
  handled_at timestamptz,
  created_at timestamptz not null default now()
);

-- =========================
-- FUNCIONES DE AUTORIZACIÓN (RLS helpers)
-- =========================
create or replace function public.current_user_profile_id()
returns uuid
language sql
stable
as $$
  select id from public.users_profile where auth_user_id = auth.uid();
$$;

create or replace function public.has_role(required_role public.app_role)
returns boolean
language sql
stable
as $$
  select exists (
    select 1 from public.user_roles ur
    join public.users_profile up on up.id = ur.user_id
    where up.auth_user_id = auth.uid()
      and ur.role = required_role
  );
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
as $$
  select public.has_role('GERENTE_ADMIN');
$$;

create or replace function public.is_supervisor_or_admin()
returns boolean
language sql
stable
as $$
  select public.has_role('SUPERVISOR_CLINICO') or public.has_role('GERENTE_ADMIN');
$$;

create or replace function public.can_access_patient(target_patient uuid)
returns boolean
language sql
stable
as $$
  select
    public.is_supervisor_or_admin()
    or exists (
      select 1
      from public.appointment_professionals ap
      join public.appointments a on a.id = ap.appointment_id
      join public.users_profile up on up.id = ap.professional_user_id
      where up.auth_user_id = auth.uid()
        and (
          a.patient_id = target_patient
          or exists (
            select 1 from public.group_session_participants gsp
            where gsp.appointment_id = a.id and gsp.patient_id = target_patient
          )
        )
    )
    or exists (
      select 1
      from public.patient_guardians pg
      where pg.patient_id = target_patient
        and pg.portal_user_id = public.current_user_profile_id()
    );
$$;

-- =========================
-- REGLAS DE NEGOCIO
-- =========================
create or replace function public.prevent_overlapping_appointments()
returns trigger
language plpgsql
as $$
begin
  if exists (
    select 1
    from public.appointments a
    join public.appointment_professionals ap_existing on ap_existing.appointment_id = a.id
    join public.appointment_professionals ap_new on ap_new.professional_user_id = ap_existing.professional_user_id
    where ap_new.appointment_id = new.id
      and a.id <> new.id
      and a.status in ('AGENDADA', 'CONFIRMADA')
      and tstzrange(a.starts_at, a.ends_at, '[)') && tstzrange(new.starts_at, new.ends_at, '[)')
  ) then
    raise exception 'Choque de horario detectado para uno o más profesionales asignados.';
  end if;

  return new;
end;
$$;

create trigger trg_prevent_overlapping_appointments
after insert or update on public.appointments
for each row execute function public.prevent_overlapping_appointments();

-- =========================
-- RLS (resumen operativo)
-- =========================
alter table public.users_profile enable row level security;
alter table public.user_roles enable row level security;
alter table public.user_invitations enable row level security;
alter table public.audit_log enable row level security;
alter table public.pre_admissions enable row level security;
alter table public.appointments enable row level security;
alter table public.appointment_professionals enable row level security;
alter table public.checkins enable row level security;
alter table public.payments enable row level security;
alter table public.clinical_sessions enable row level security;
alter table public.assessment_results enable row level security;
alter table public.patient_records enable row level security;
alter table public.generated_documents enable row level security;
alter table public.patient_documents enable row level security;
alter table public.portal_requests enable row level security;
alter table public.staff_profiles enable row level security;
alter table public.staff_documents enable row level security;
alter table public.internal_requests enable row level security;

-- Admin total
create policy admin_all_users_profile on public.users_profile
  for all using (public.is_admin()) with check (public.is_admin());

-- Usuario ve/edita su propio perfil
create policy user_self_profile on public.users_profile
  for select using (auth.uid() = auth_user_id);
create policy user_self_profile_update on public.users_profile
  for update using (auth.uid() = auth_user_id) with check (auth.uid() = auth_user_id);

-- Roles solo admin
create policy admin_roles_all on public.user_roles
  for all using (public.is_admin()) with check (public.is_admin());

-- Invitaciones: admin gestiona, invitado consulta por email
create policy admin_invites_all on public.user_invitations
  for all using (public.is_admin()) with check (public.is_admin());

-- Pre-admisión: inserción pública; lectura/gestión interna admin/recepción
create policy public_create_pre_admission on public.pre_admissions
  for insert with check (true);
create policy internal_read_pre_admission on public.pre_admissions
  for select using (public.is_admin() or public.has_role('RECEPCION_ADMIN'));
create policy internal_update_pre_admission on public.pre_admissions
  for update using (public.is_admin() or public.has_role('RECEPCION_ADMIN'));

-- Agenda: recepción/admin/supervisor ven todo; profesional ve lo asignado
create policy appointments_select_policy on public.appointments
  for select using (
    public.is_admin()
    or public.has_role('RECEPCION_ADMIN')
    or public.has_role('SUPERVISOR_CLINICO')
    or exists (
      select 1 from public.appointment_professionals ap
      join public.users_profile up on up.id = ap.professional_user_id
      where ap.appointment_id = appointments.id
        and up.auth_user_id = auth.uid()
    )
  );

create policy appointments_modify_policy on public.appointments
  for all using (
    public.is_admin()
    or public.has_role('RECEPCION_ADMIN')
    or public.has_role('SUPERVISOR_CLINICO')
  ) with check (
    public.is_admin()
    or public.has_role('RECEPCION_ADMIN')
    or public.has_role('SUPERVISOR_CLINICO')
  );

-- Check-in y pagos: recepción/admin editan, clínicos lectura pagos
create policy checkins_rw on public.checkins
  for all using (public.is_admin() or public.has_role('RECEPCION_ADMIN') or public.has_role('SUPERVISOR_CLINICO'))
  with check (public.is_admin() or public.has_role('RECEPCION_ADMIN') or public.has_role('SUPERVISOR_CLINICO'));

create policy payments_select_policy on public.payments
  for select using (
    public.is_admin()
    or public.has_role('RECEPCION_ADMIN')
    or public.has_role('SUPERVISOR_CLINICO')
    or public.has_role('PROFESIONAL_CLINICO')
  );

create policy payments_modify_policy on public.payments
  for all using (public.is_admin() or public.has_role('RECEPCION_ADMIN'))
  with check (public.is_admin() or public.has_role('RECEPCION_ADMIN'));

-- Clínica: profesional accede solo sus pacientes/sesiones; supervisor/admin total
create policy clinical_sessions_policy on public.clinical_sessions
  for all using (
    public.is_supervisor_or_admin()
    or (
      public.has_role('PROFESIONAL_CLINICO')
      and exists (
        select 1 from public.users_profile up
        where up.id = clinical_sessions.professional_user_id
          and up.auth_user_id = auth.uid()
      )
    )
  ) with check (
    public.is_supervisor_or_admin()
    or (
      public.has_role('PROFESIONAL_CLINICO')
      and exists (
        select 1 from public.users_profile up
        where up.id = clinical_sessions.professional_user_id
          and up.auth_user_id = auth.uid()
      )
    )
  );

create policy patient_record_policy on public.patient_records
  for select using (public.can_access_patient(patient_id));
create policy patient_record_modify_policy on public.patient_records
  for update using (public.is_supervisor_or_admin() or public.has_role('PROFESIONAL_CLINICO'));

create policy assessment_policy on public.assessment_results
  for all using (public.is_supervisor_or_admin() or public.has_role('PROFESIONAL_CLINICO'))
  with check (public.is_supervisor_or_admin() or public.has_role('PROFESIONAL_CLINICO'));

-- Documentos clínicos + portal
create policy generated_documents_select_policy on public.generated_documents
  for select using (
    public.is_supervisor_or_admin()
    or public.has_role('PROFESIONAL_CLINICO')
    or (
      visibility = 'PORTAL'
      and public.can_access_patient(patient_id)
      and public.has_role('PACIENTE_APODERADO')
    )
  );

create policy generated_documents_modify_policy on public.generated_documents
  for all using (public.is_supervisor_or_admin() or public.has_role('PROFESIONAL_CLINICO'))
  with check (public.is_supervisor_or_admin() or public.has_role('PROFESIONAL_CLINICO'));

create policy patient_documents_select_policy on public.patient_documents
  for select using (
    public.is_supervisor_or_admin()
    or public.has_role('PROFESIONAL_CLINICO')
    or (
      visibility = 'PORTAL'
      and public.can_access_patient(patient_id)
      and public.has_role('PACIENTE_APODERADO')
    )
  );

-- Solicitudes portal
create policy portal_requests_select_policy on public.portal_requests
  for select using (
    public.is_admin()
    or public.has_role('RECEPCION_ADMIN')
    or (requested_by_user_id = public.current_user_profile_id() and public.has_role('PACIENTE_APODERADO'))
  );

create policy portal_requests_insert_policy on public.portal_requests
  for insert with check (
    requested_by_user_id = public.current_user_profile_id()
    and public.has_role('PACIENTE_APODERADO')
  );

create policy portal_requests_update_policy on public.portal_requests
  for update using (public.is_admin() or public.has_role('RECEPCION_ADMIN'));

-- RRHH: solo admin y perfil propio en solicitudes
create policy staff_profiles_admin on public.staff_profiles
  for all using (public.is_admin()) with check (public.is_admin());

create policy staff_documents_admin on public.staff_documents
  for all using (public.is_admin()) with check (public.is_admin());

create policy internal_requests_policy on public.internal_requests
  for select using (
    public.is_admin()
    or exists (
      select 1
      from public.staff_profiles sp
      where sp.id = internal_requests.staff_id
        and sp.user_id = public.current_user_profile_id()
    )
  );

create policy internal_requests_insert_policy on public.internal_requests
  for insert with check (
    exists (
      select 1
      from public.staff_profiles sp
      where sp.id = internal_requests.staff_id
        and sp.user_id = public.current_user_profile_id()
    )
  );

create policy internal_requests_update_admin on public.internal_requests
  for update using (public.is_admin());

-- =========================
-- AUTOMATIZACIONES CRÍTICAS
-- =========================
create type public.reminder_type as enum ('CONFIRMACION_DIA_SIGUIENTE', 'RECORDATORIO_24H', 'RECORDATORIO_2H');
create type public.reminder_status as enum ('PENDIENTE', 'ENVIADO', 'ERROR', 'CONFIRMADO', 'NO_CONFIRMADO');

create table public.appointment_reminders (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  reminder_type public.reminder_type not null,
  channel text not null check (channel in ('WHATSAPP', 'EMAIL')),
  recipient text not null,
  scheduled_for timestamptz not null,
  status public.reminder_status not null default 'PENDIENTE',
  provider_message_id text,
  error_message text,
  sent_at timestamptz,
  created_at timestamptz not null default now(),
  unique (appointment_id, reminder_type, channel)
);

create table public.automation_job_runs (
  id uuid primary key default gen_random_uuid(),
  job_name text not null,
  scheduled_for timestamptz not null,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  status text not null default 'RUNNING' check (status in ('RUNNING', 'OK', 'ERROR')),
  rows_processed integer not null default 0,
  error_message text,
  metadata jsonb not null default '{}'::jsonb
);

create table public.portal_download_audit (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id),
  patient_id uuid not null references public.patients(id),
  generated_document_id uuid references public.generated_documents(id),
  patient_document_id uuid references public.patient_documents(id),
  downloaded_at timestamptz not null default now(),
  ip_address inet,
  user_agent text,
  metadata jsonb not null default '{}'::jsonb,
  check ((generated_document_id is not null) <> (patient_document_id is not null))
);

alter table public.generated_documents
  add column if not exists pdf_storage_path text,
  add column if not exists is_published boolean not null default false,
  add column if not exists published_at timestamptz,
  add column if not exists published_by uuid references public.users_profile(id);

alter table public.patient_documents
  add column if not exists pdf_storage_path text,
  add column if not exists is_published boolean not null default false,
  add column if not exists published_at timestamptz,
  add column if not exists published_by uuid references public.users_profile(id);

create or replace function public.queue_next_day_confirmations(job_run_id uuid default null)
returns integer
language plpgsql
as $$
declare
  v_count integer := 0;
  v_tz text := 'America/Santiago';
begin
  insert into public.appointment_confirmations (appointment_id, channel, recipient, status)
  select a.id, channel_data.channel, channel_data.recipient, 'PENDIENTE'
  from public.appointments a
  join public.patients p on p.id = a.patient_id
  join public.people pp on pp.id = p.person_id
  cross join lateral (
    values
      ('WHATSAPP'::text, coalesce(pp.phone, 'SIN_TELEFONO')),
      ('EMAIL'::text, coalesce(pp.email, 'SIN_EMAIL'))
  ) channel_data(channel, recipient)
  where a.status in ('AGENDADA', 'CONFIRMADA')
    and ((a.starts_at at time zone v_tz)::date = ((now() at time zone v_tz)::date + 1))
    and not exists (
      select 1
      from public.appointment_confirmations ac
      where ac.appointment_id = a.id
        and ac.channel = channel_data.channel
    );

  get diagnostics v_count = row_count;

  insert into public.audit_log (actor_user_id, action, target_table, target_id, payload)
  values (
    null,
    'QUEUE_NEXT_DAY_CONFIRMATIONS',
    'appointment_confirmations',
    coalesce(job_run_id::text, 'manual'),
    jsonb_build_object('created_rows', v_count)
  );

  return v_count;
end;
$$;

create or replace function public.queue_session_reminders(hours_before integer, job_run_id uuid default null)
returns integer
language plpgsql
as $$
declare
  v_count integer := 0;
begin
  insert into public.appointment_reminders (appointment_id, reminder_type, channel, recipient, scheduled_for)
  select
    a.id,
    case
      when hours_before >= 24 then 'RECORDATORIO_24H'::public.reminder_type
      else 'RECORDATORIO_2H'::public.reminder_type
    end,
    channel_data.channel,
    channel_data.recipient,
    a.starts_at - make_interval(hours => hours_before)
  from public.appointments a
  join public.patients p on p.id = a.patient_id
  join public.people pp on pp.id = p.person_id
  cross join lateral (
    values
      ('WHATSAPP'::text, coalesce(pp.phone, 'SIN_TELEFONO')),
      ('EMAIL'::text, coalesce(pp.email, 'SIN_EMAIL'))
  ) channel_data(channel, recipient)
  where a.status in ('AGENDADA', 'CONFIRMADA')
    and a.starts_at >= now()
    and not exists (
      select 1
      from public.appointment_reminders ar
      where ar.appointment_id = a.id
        and ar.reminder_type = (
          case when hours_before >= 24 then 'RECORDATORIO_24H'::public.reminder_type else 'RECORDATORIO_2H'::public.reminder_type end
        )
        and ar.channel = channel_data.channel
    );

  get diagnostics v_count = row_count;

  insert into public.audit_log (actor_user_id, action, target_table, target_id, payload)
  values (
    null,
    'QUEUE_SESSION_REMINDERS',
    'appointment_reminders',
    coalesce(job_run_id::text, 'manual'),
    jsonb_build_object('hours_before', hours_before, 'created_rows', v_count)
  );

  return v_count;
end;
$$;

create or replace function public.run_daily_automation_confirmations()
returns uuid
language plpgsql
as $$
declare
  v_job_id uuid;
  v_rows integer := 0;
begin
  insert into public.automation_job_runs (job_name, scheduled_for)
  values ('daily_confirmations_cl_18h', now())
  returning id into v_job_id;

  begin
    v_rows := public.queue_next_day_confirmations(v_job_id);
    update public.automation_job_runs
    set status = 'OK', rows_processed = v_rows, finished_at = now()
    where id = v_job_id;
  exception when others then
    update public.automation_job_runs
    set status = 'ERROR', error_message = sqlerrm, finished_at = now()
    where id = v_job_id;
    raise;
  end;

  return v_job_id;
end;
$$;

create or replace function public.publish_generated_document(target_document uuid, publisher uuid)
returns public.generated_documents
language plpgsql
security definer
as $$
declare
  v_doc public.generated_documents;
begin
  if not (public.is_supervisor_or_admin() or public.has_role('PROFESIONAL_CLINICO')) then
    raise exception 'No autorizado para publicar documentos.';
  end if;

  update public.generated_documents
  set
    is_published = true,
    published_at = now(),
    published_by = publisher,
    pdf_storage_path = coalesce(pdf_storage_path, format('storage://informes/%s.pdf', id::text))
  where id = target_document
  returning * into v_doc;

  if v_doc.id is null then
    raise exception 'Documento no encontrado.';
  end if;

  insert into public.audit_log (actor_user_id, action, target_table, target_id, payload)
  values (publisher, 'PUBLISH_GENERATED_DOCUMENT', 'generated_documents', target_document::text, jsonb_build_object('pdf_storage_path', v_doc.pdf_storage_path));

  return v_doc;
end;
$$;

create or replace function public.portal_download_generated_document(target_document uuid, ip inet default null, ua text default null)
returns text
language plpgsql
security definer
as $$
declare
  v_doc public.generated_documents;
  v_user uuid;
begin
  v_user := public.current_user_profile_id();

  select *
  into v_doc
  from public.generated_documents gd
  where gd.id = target_document
    and gd.is_published = true
    and gd.visibility = 'PORTAL'
    and public.can_access_patient(gd.patient_id);

  if v_doc.id is null then
    raise exception 'Documento no disponible para portal.';
  end if;

  insert into public.portal_download_audit (user_id, patient_id, generated_document_id, ip_address, user_agent)
  values (v_user, v_doc.patient_id, v_doc.id, ip, ua);

  insert into public.audit_log (actor_user_id, action, target_table, target_id, payload)
  values (v_user, 'PORTAL_DOWNLOAD_DOCUMENT', 'generated_documents', target_document::text, jsonb_build_object('ip_address', ip, 'user_agent', ua));

  return v_doc.pdf_storage_path;
end;
$$;

-- Ejemplo de programación con pg_cron (activar extensión según entorno):
-- select cron.schedule('crea_confirmaciones_18h_cl', '0 18 * * *', $$select public.run_daily_automation_confirmations();$$);

alter table public.appointment_reminders enable row level security;
alter table public.automation_job_runs enable row level security;
alter table public.portal_download_audit enable row level security;

create policy appointment_reminders_select_policy on public.appointment_reminders
  for select using (
    public.is_admin() or public.has_role('RECEPCION_ADMIN') or public.has_role('SUPERVISOR_CLINICO') or public.has_role('PROFESIONAL_CLINICO')
  );

create policy appointment_reminders_modify_policy on public.appointment_reminders
  for all using (public.is_admin() or public.has_role('RECEPCION_ADMIN'))
  with check (public.is_admin() or public.has_role('RECEPCION_ADMIN'));

create policy automation_job_runs_admin on public.automation_job_runs
  for all using (public.is_admin()) with check (public.is_admin());

create policy portal_download_audit_select_internal on public.portal_download_audit
  for select using (public.is_admin() or public.has_role('RECEPCION_ADMIN') or public.has_role('SUPERVISOR_CLINICO'));

create policy portal_download_audit_insert_portal on public.portal_download_audit
  for insert with check (
    public.has_role('PACIENTE_APODERADO')
    and user_id = public.current_user_profile_id()
    and public.can_access_patient(patient_id)
  );

drop policy if exists generated_documents_select_policy on public.generated_documents;
create policy generated_documents_select_policy on public.generated_documents
  for select using (
    public.is_supervisor_or_admin()
    or public.has_role('PROFESIONAL_CLINICO')
    or (
      visibility = 'PORTAL'
      and is_published = true
      and public.can_access_patient(patient_id)
      and public.has_role('PACIENTE_APODERADO')
    )
  );
