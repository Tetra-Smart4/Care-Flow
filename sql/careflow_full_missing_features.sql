-- CareFlow Full Missing Features / V2 database layer
-- Run this in Supabase SQL Editor before using the new screens.
-- It is additive and uses careflow_* table names to avoid damaging existing tables.

create extension if not exists pgcrypto;

create table if not exists public.careflow_appointments (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  doctor_id uuid not null references public.profiles(id) on delete cascade,
  clinic_id uuid not null references public.profiles(id) on delete cascade,
  appointment_date date not null,
  appointment_time time not null,
  reason text not null default 'General consultation',
  status text not null default 'pending' check (status in ('pending','confirmed','checked_in','in_queue','consulting','completed','cancelled')),
  qr_token uuid not null default gen_random_uuid() unique,
  token_no integer,
  checked_in_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_careflow_appt_patient on public.careflow_appointments(patient_id, appointment_date desc);
create index if not exists idx_careflow_appt_doctor on public.careflow_appointments(doctor_id, appointment_date desc);
create index if not exists idx_careflow_appt_clinic on public.careflow_appointments(clinic_id, appointment_date desc);
create index if not exists idx_careflow_appt_qr on public.careflow_appointments(qr_token);

create table if not exists public.careflow_queue_counters (
  clinic_id uuid not null references public.profiles(id) on delete cascade,
  queue_date date not null,
  next_token integer not null default 1,
  current_token integer not null default 0,
  primary key (clinic_id, queue_date)
);

create table if not exists public.careflow_consultations (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null unique references public.careflow_appointments(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  doctor_id uuid not null references public.profiles(id) on delete cascade,
  symptoms text not null default '',
  diagnosis text not null default '',
  notes text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.careflow_prescriptions (
  id uuid primary key default gen_random_uuid(),
  consultation_id uuid not null references public.careflow_consultations(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  doctor_id uuid not null references public.profiles(id) on delete cascade,
  medicine_name text not null,
  dosage text not null default '',
  frequency text not null default '',
  duration_days integer not null default 1,
  instructions text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.careflow_medicines (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  common_uses text not null default '',
  precautions text not null default '',
  side_effects text not null default '',
  general_info text,
  created_at timestamptz not null default now()
);

create table if not exists public.careflow_lab_reports (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  appointment_id uuid references public.careflow_appointments(id) on delete set null,
  title text not null,
  report_type text not null default 'General',
  result_summary text not null default '',
  reported_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.careflow_bills (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null unique references public.careflow_appointments(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  clinic_id uuid not null references public.profiles(id) on delete cascade,
  consultation_fee numeric(12,2) not null default 0,
  medicine_total numeric(12,2) not null default 0,
  test_total numeric(12,2) not null default 0,
  other_charges numeric(12,2) not null default 0,
  total numeric(12,2) generated always as (consultation_fee + medicine_total + test_total + other_charges) stored,
  paid boolean not null default false,
  receipt_no text not null unique default ('CF-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,10))),
  created_at timestamptz not null default now()
);

create table if not exists public.careflow_followups (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null references public.careflow_appointments(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  doctor_id uuid not null references public.profiles(id) on delete cascade,
  followup_date date not null,
  notes text not null default '',
  status text not null default 'scheduled' check (status in ('scheduled','completed','cancelled')),
  created_at timestamptz not null default now()
);

create table if not exists public.careflow_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null default '',
  type text not null default 'general',
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists idx_careflow_notifications_user on public.careflow_notifications(user_id, created_at desc);

alter table public.careflow_appointments enable row level security;
alter table public.careflow_queue_counters enable row level security;
alter table public.careflow_consultations enable row level security;
alter table public.careflow_prescriptions enable row level security;
alter table public.careflow_medicines enable row level security;
alter table public.careflow_lab_reports enable row level security;
alter table public.careflow_bills enable row level security;
alter table public.careflow_followups enable row level security;
alter table public.careflow_notifications enable row level security;

drop policy if exists cf_appt_select on public.careflow_appointments;
create policy cf_appt_select on public.careflow_appointments for select to authenticated using (auth.uid() = patient_id or auth.uid() = doctor_id or auth.uid() = clinic_id);
drop policy if exists cf_appt_insert on public.careflow_appointments;
create policy cf_appt_insert on public.careflow_appointments for insert to authenticated with check (auth.uid() = patient_id);
drop policy if exists cf_appt_update on public.careflow_appointments;
create policy cf_appt_update on public.careflow_appointments for update to authenticated using (auth.uid() = patient_id or auth.uid() = doctor_id or auth.uid() = clinic_id) with check (auth.uid() = patient_id or auth.uid() = doctor_id or auth.uid() = clinic_id);

drop policy if exists cf_consult_select on public.careflow_consultations;
drop policy if exists cf_consult_insert on public.careflow_consultations;
drop policy if exists cf_consult_update on public.careflow_consultations;
create policy cf_consult_select on public.careflow_consultations for select to authenticated using (auth.uid() = patient_id or auth.uid() = doctor_id);
create policy cf_consult_insert on public.careflow_consultations for insert to authenticated with check (auth.uid() = doctor_id);
create policy cf_consult_update on public.careflow_consultations for update to authenticated using (auth.uid() = doctor_id) with check (auth.uid() = doctor_id);
create or replace function public.careflow_add_lab_report(p_appointment_id uuid,p_patient_id uuid,p_title text,p_report_type text,p_result_summary text)
returns uuid language plpgsql security definer set search_path=public as $$
declare a public.careflow_appointments; v_id uuid;
begin
 select * into a from public.careflow_appointments where id=p_appointment_id and patient_id=p_patient_id;
 if not found or auth.uid()<>a.doctor_id then raise exception 'Doctor is not allowed'; end if;
 insert into public.careflow_lab_reports(patient_id,appointment_id,title,report_type,result_summary,created_by)
 values(a.patient_id,a.id,coalesce(nullif(trim(p_title),''),'Lab report'),coalesce(nullif(trim(p_report_type),''),'General'),coalesce(p_result_summary,''),auth.uid()) returning id into v_id;
 insert into public.careflow_notifications(user_id,title,body,type) values(a.patient_id,'New lab report','A new lab report has been added to your CareFlow records.','lab');
 return v_id;
end;
$$;

create or replace function public.careflow_advance_queue(p_clinic_id uuid)
returns integer language plpgsql security definer set search_path=public as $$
declare v_current integer;
v_date date := current_date;
begin
 if not exists(select 1 from public.profiles where id=auth.uid() and role in ('clinic','doctor')) then raise exception 'Not allowed'; end if;
 if not exists(select 1 from public.profiles where id=p_clinic_id and role='clinic') then raise exception 'Clinic not found'; end if;
 if not exists(select 1 from public.careflow_appointments where clinic_id=p_clinic_id and doctor_id=auth.uid() and appointment_date=v_date) and not exists(select 1 from public.profiles where id=auth.uid() and role='clinic' and id=p_clinic_id) then raise exception 'You are not assigned to this clinic'; end if;
 insert into public.careflow_queue_counters(clinic_id,queue_date,next_token,current_token) values(p_clinic_id,v_date,1,0) on conflict do nothing;
 update public.careflow_queue_counters set current_token = least(next_token-1,current_token+1) where clinic_id=p_clinic_id and queue_date=v_date returning current_token into v_current;
 update public.careflow_appointments set status='consulting' where clinic_id=p_clinic_id and appointment_date=v_date and token_no=v_current and status='in_queue';
 return coalesce(v_current,0);
end;
$$;


