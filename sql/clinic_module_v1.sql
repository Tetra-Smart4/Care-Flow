-- CAREFLOW CLINIC V1
-- Run after confirming your existing table names/columns.
-- This migration is intentionally additive: it adds clinic relationships without
-- deleting existing data.

-- 1. One clinic account maps to one clinic row.
--    Expected: clinics.id is UUID and references profiles.id / auth.users.id.

alter table if exists public.clinics
  add column if not exists clinic_id text;

alter table if exists public.clinics
  add column if not exists clinic_name text;

alter table if exists public.clinics
  add column if not exists phone text;

alter table if exists public.clinics
  add column if not exists address text;

-- 2. Link doctors and patients to their clinic.

alter table if exists public.doctors
  add column if not exists clinic_id uuid;

alter table if exists public.patients
  add column if not exists clinic_id uuid;

alter table if exists public.appointments
  add column if not exists clinic_id uuid;

-- 3. Add foreign keys only when they are not already present.

do $$
begin
  if to_regclass('public.clinics') is not null
     and not exists (
       select 1 from pg_constraint
       where conname = 'doctors_clinic_id_fkey'
     ) then
    alter table public.doctors
      add constraint doctors_clinic_id_fkey
      foreign key (clinic_id) references public.clinics(id) on delete set null;
  end if;

  if to_regclass('public.clinics') is not null
     and not exists (
       select 1 from pg_constraint
       where conname = 'patients_clinic_id_fkey'
     ) then
    alter table public.patients
      add constraint patients_clinic_id_fkey
      foreign key (clinic_id) references public.clinics(id) on delete set null;
  end if;

  if to_regclass('public.clinics') is not null
     and not exists (
       select 1 from pg_constraint
       where conname = 'appointments_clinic_id_fkey'
     ) then
    alter table public.appointments
      add constraint appointments_clinic_id_fkey
      foreign key (clinic_id) references public.clinics(id) on delete set null;
  end if;
end;
$$;

-- 4. Keep a patient's clinic association synchronized when an appointment is created.
--    This is a simple V1 model: one patient is associated with the clinic that
--    handles the latest appointment. For multi-clinic patients later, replace this
--    with a clinic_patients junction table.

create or replace function public.careflow_set_appointment_clinic_patient()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.clinic_id is not null then
    update public.patients
       set clinic_id = new.clinic_id
     where id = new.patient_id
       and (clinic_id is null or clinic_id <> new.clinic_id);
  end if;
  return new;
end;
$$;

drop trigger if exists careflow_appointment_clinic_patient on public.appointments;
create trigger careflow_appointment_clinic_patient
after insert or update of clinic_id, patient_id on public.appointments
for each row
execute function public.careflow_set_appointment_clinic_patient();

-- 5. Backfill clinic_id from appointments for existing patient records.

update public.patients p
   set clinic_id = x.clinic_id
  from (
    select distinct on (patient_id)
           patient_id,
           clinic_id
      from public.appointments
     where clinic_id is not null
     order by patient_id, created_at desc
  ) x
 where p.id = x.patient_id
   and p.clinic_id is null;

-- 6. Backfill appointment clinic from the doctor's clinic where possible.

update public.appointments a
   set clinic_id = d.clinic_id
  from public.doctors d
 where a.doctor_id = d.id
   and a.clinic_id is null
   and d.clinic_id is not null;

-- 7. Create/update the clinic row for the currently logged-in clinic manually when needed.
-- Replace the UUID below with the clinic user's auth.users.id.
--
-- insert into public.clinics (id, clinic_id, clinic_name, phone, address)
-- select p.id, 'CLINIC-' || upper(substr(replace(p.id::text, '-', ''), 1, 8)),
--        p.full_name, p.phone, p.address
-- from public.profiles p
-- where p.id = '<CLINIC_AUTH_USER_UUID>'
-- on conflict (id) do update set
--   clinic_name = excluded.clinic_name,
--   phone = excluded.phone,
--   address = excluded.address;


-- Profiles: the clinic needs to see only the doctor/patient profiles linked to its clinic.
alter table if exists public.profiles enable row level security;

drop policy if exists "Clinic can read linked profiles" on public.profiles;
create policy "Clinic can read linked profiles"
on public.profiles for select to authenticated
using (
  id = auth.uid()
  or exists (
    select 1 from public.doctors d
    where d.id = profiles.id
      and d.clinic_id = auth.uid()
  )
  or exists (
    select 1 from public.patients p
    where p.id = profiles.id
      and p.clinic_id = auth.uid()
  )
);

-- Automatically create the clinic row when a clinic account is registered.
create or replace function public.careflow_create_clinic_row()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(new.raw_user_meta_data->>'role', '') = 'clinic' then
    insert into public.clinics (id, clinic_id, clinic_name, phone, address)
    values (
      new.id,
      'CLN-' || upper(substr(replace(new.id::text, '-', ''), 1, 8)),
      coalesce(new.raw_user_meta_data->>'full_name', 'Clinic'),
      new.raw_user_meta_data->>'phone',
      new.raw_user_meta_data->>'address'
    )
    on conflict (id) do update set
      clinic_name = excluded.clinic_name,
      phone = excluded.phone,
      address = excluded.address;
  end if;
  return new;
end;
$$;

drop trigger if exists careflow_create_clinic_row_after_auth on auth.users;
create trigger careflow_create_clinic_row_after_auth
after insert on auth.users
for each row
execute function public.careflow_create_clinic_row();

-- 8. RLS helper: clinic owner is auth.uid() = clinics.id.

alter table if exists public.clinics enable row level security;
alter table if exists public.doctors enable row level security;
alter table if exists public.patients enable row level security;
alter table if exists public.appointments enable row level security;

-- Clinics
 drop policy if exists "Clinic can read own clinic" on public.clinics;
create policy "Clinic can read own clinic"
on public.clinics for select to authenticated
using (id = auth.uid());

 drop policy if exists "Clinic can update own clinic" on public.clinics;
create policy "Clinic can update own clinic"
on public.clinics for update to authenticated
using (id = auth.uid())
with check (id = auth.uid());

-- Doctors
 drop policy if exists "Clinic can read own doctors" on public.doctors;
create policy "Clinic can read own doctors"
on public.doctors for select to authenticated
using (clinic_id = auth.uid());

 drop policy if exists "Clinic can update own doctors" on public.doctors;
create policy "Clinic can update own doctors"
on public.doctors for update to authenticated
using (clinic_id = auth.uid())
with check (clinic_id = auth.uid());

-- Patients
 drop policy if exists "Clinic can read own patients" on public.patients;
create policy "Clinic can read own patients"
on public.patients for select to authenticated
using (clinic_id = auth.uid());

-- Appointments
 drop policy if exists "Clinic can read own appointments" on public.appointments;
create policy "Clinic can read own appointments"
on public.appointments for select to authenticated
using (clinic_id = auth.uid());

 drop policy if exists "Clinic can update own appointments" on public.appointments;
create policy "Clinic can update own appointments"
on public.appointments for update to authenticated
using (clinic_id = auth.uid())
with check (clinic_id = auth.uid());

-- Enable Realtime for the clinic-management tables.
-- Run the ALTER TABLE commands that apply to your project only once.

-- alter publication supabase_realtime add table public.doctors;
-- alter publication supabase_realtime add table public.patients;
-- alter publication supabase_realtime add table public.appointments;
