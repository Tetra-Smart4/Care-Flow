-- CareFlow Patient schema
-- Run this in Supabase SQL Editor before launching the Flutter app.
-- Safe for a fresh CareFlow project. If you already have tables, reconcile
-- column names instead of blindly creating duplicate tables.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'patient' check (role in ('patient','doctor','staff','admin')),
  first_name text,
  last_name text,
  email text,
  phone text,
  date_of_birth date,
  gender text,
  blood_group text,
  allergies text,
  emergency_contact_name text,
  emergency_contact_phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.doctors (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  specialty text,
  clinic_id uuid,
  email text,
  phone text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  doctor_id uuid not null references public.doctors(id) on delete restrict,
  scheduled_at timestamptz not null,
  status text not null default 'pending' check (status in ('pending','confirmed','completed','cancelled')),
  reason text,
  created_at timestamptz not null default now()
);

create table if not exists public.vitals (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  type text not null,
  value text not null,
  unit text,
  recorded_at timestamptz not null default now()
);

create table if not exists public.prescriptions (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  doctor_id uuid references public.doctors(id) on delete set null,
  medicine text not null,
  dosage text,
  frequency text,
  duration text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.medical_records (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  doctor_id uuid references public.doctors(id) on delete set null,
  title text not null,
  diagnosis text,
  notes text,
  record_date timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.lab_reports (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  result text,
  file_url text,
  report_date timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  sender_id uuid references public.profiles(id) on delete set null,
  body text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.doctors enable row level security;
alter table public.appointments enable row level security;
alter table public.vitals enable row level security;
alter table public.prescriptions enable row level security;
alter table public.medical_records enable row level security;
alter table public.lab_reports enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;

drop policy if exists "patient profile select" on public.profiles;
create policy "patient profile select" on public.profiles for select using (id = auth.uid());
drop policy if exists "patient profile update" on public.profiles;
create policy "patient profile update" on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());
drop policy if exists "patient profile insert" on public.profiles;
create policy "patient profile insert" on public.profiles for insert with check (id = auth.uid());

drop policy if exists "active doctors readable" on public.doctors;
create policy "active doctors readable" on public.doctors for select using (active = true);

drop policy if exists "patient appointments read" on public.appointments;
create policy "patient appointments read" on public.appointments for select using (patient_id = auth.uid());
drop policy if exists "patient appointments insert" on public.appointments;
create policy "patient appointments insert" on public.appointments for insert with check (patient_id = auth.uid());

drop policy if exists "patient vitals read" on public.vitals;
create policy "patient vitals read" on public.vitals for select using (patient_id = auth.uid());

drop policy if exists "patient prescriptions read" on public.prescriptions;
create policy "patient prescriptions read" on public.prescriptions for select using (patient_id = auth.uid());

drop policy if exists "patient records read" on public.medical_records;
create policy "patient records read" on public.medical_records for select using (patient_id = auth.uid());

drop policy if exists "patient labs read" on public.lab_reports;
create policy "patient labs read" on public.lab_reports for select using (patient_id = auth.uid());

drop policy if exists "patient messages read" on public.messages;
create policy "patient messages read" on public.messages for select using (patient_id = auth.uid());
drop policy if exists "patient messages insert" on public.messages;
create policy "patient messages insert" on public.messages for insert with check (patient_id = auth.uid() and sender_id = auth.uid());

drop policy if exists "patient notifications read" on public.notifications;
create policy "patient notifications read" on public.notifications for select using (user_id = auth.uid());

-- Realtime for messages.
alter publication supabase_realtime add table public.messages;
