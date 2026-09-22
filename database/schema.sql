-- CareFlow Supabase/PostgreSQL setup
-- Run in Supabase SQL Editor on a fresh project.

create extension if not exists pgcrypto;

do $$ begin
  create type public.user_role as enum ('patient','doctor','clinic','admin');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.appointment_status as enum ('Requested','Confirmed','Checked In','Consultation','Completed','Cancelled','No-show');
exception when duplicate_object then null; end $$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text,
  role public.user_role not null default 'patient',
  phone text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.clinics (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references public.profiles(id) on delete set null,
  name text not null,
  email text,
  phone text,
  address text,
  registration_number text,
  working_hours jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.doctors (
  id uuid primary key references public.profiles(id) on delete cascade,
  clinic_id uuid references public.clinics(id) on delete set null,
  specialization text,
  qualification text,
  experience_years int not null default 0,
  license_number text,
  consultation_fee numeric(12,2) not null default 0,
  status text not null default 'Active',
  created_at timestamptz not null default now()
);

create table if not exists public.patients (
  id uuid primary key references public.profiles(id) on delete cascade,
  clinic_id uuid references public.clinics(id) on delete set null,
  patient_code text unique,
  date_of_birth date,
  gender text,
  blood_group text,
  allergies text,
  chronic_conditions text,
  emergency_contact jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.clinic_staff (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  role text not null,
  department text,
  status text not null default 'Active',
  created_at timestamptz not null default now(),
  unique(clinic_id, profile_id)
);

create table if not exists public.doctor_availability (
  id uuid primary key default gen_random_uuid(),
  doctor_id uuid not null references public.doctors(id) on delete cascade,
  weekday int not null check (weekday between 1 and 7),
  start_time time not null,
  end_time time not null,
  slot_minutes int not null default 30
);

create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid references public.clinics(id) on delete cascade,
  patient_id uuid not null references public.patients(id) on delete cascade,
  doctor_id uuid not null references public.doctors(id) on delete cascade,
  appointment_date date not null,
  appointment_time time not null,
  status public.appointment_status not null default 'Requested',
  appointment_type text default 'Consultation',
  notes text,
  walk_in boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.appointment_status_history (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  old_status text,
  new_status text not null,
  changed_by uuid references public.profiles(id) on delete set null,
  changed_at timestamptz not null default now()
);

create table if not exists public.medical_records (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id) on delete cascade,
  doctor_id uuid references public.doctors(id) on delete set null,
  clinic_id uuid references public.clinics(id) on delete set null,
  appointment_id uuid references public.appointments(id) on delete set null,
  title text not null,
  diagnosis text,
  symptoms text,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.medical_documents (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id) on delete cascade,
  clinic_id uuid references public.clinics(id) on delete set null,
  title text not null,
  storage_path text not null,
  mime_type text,
  created_at timestamptz not null default now()
);

create table if not exists public.vitals (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id) on delete cascade,
  appointment_id uuid references public.appointments(id) on delete set null,
  blood_pressure text,
  heart_rate numeric,
  weight_kg numeric,
  blood_sugar numeric,
  recorded_at timestamptz not null default now()
);

create table if not exists public.prescriptions (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id) on delete cascade,
  doctor_id uuid references public.doctors(id) on delete set null,
  clinic_id uuid references public.clinics(id) on delete set null,
  appointment_id uuid references public.appointments(id) on delete set null,
  status text not null default 'Active',
  instructions text,
  created_at timestamptz not null default now()
);

create table if not exists public.prescription_items (
  id uuid primary key default gen_random_uuid(),
  prescription_id uuid not null references public.prescriptions(id) on delete cascade,
  medicine_name text not null,
  dose text,
  frequency text,
  duration_days int
);

create table if not exists public.lab_tests (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  price numeric(12,2) default 0,
  active boolean not null default true
);

create table if not exists public.lab_orders (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid references public.clinics(id) on delete cascade,
  patient_id uuid not null references public.patients(id) on delete cascade,
  doctor_id uuid references public.doctors(id) on delete set null,
  test_id uuid references public.lab_tests(id) on delete set null,
  status text not null default 'Pending',
  ordered_at timestamptz not null default now(),
  completed_at timestamptz
);

create table if not exists public.lab_results (
  id uuid primary key default gen_random_uuid(),
  lab_order_id uuid not null references public.lab_orders(id) on delete cascade,
  result_json jsonb not null default '{}'::jsonb,
  report_storage_path text,
  reviewed_by uuid references public.doctors(id) on delete set null,
  reviewed_at timestamptz
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  body text,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create table if not exists public.message_attachments (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  storage_path text not null,
  mime_type text,
  created_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  name text not null,
  description text,
  price numeric(12,2) not null default 0,
  active boolean not null default true
);

create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid references public.clinics(id) on delete cascade,
  patient_id uuid references public.patients(id) on delete set null,
  invoice_number text unique not null,
  subtotal numeric(12,2) not null default 0,
  tax numeric(12,2) not null default 0,
  discount numeric(12,2) not null default 0,
  total numeric(12,2) not null default 0,
  status text not null default 'Pending',
  created_at timestamptz not null default now()
);

create table if not exists public.invoice_items (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  description text not null,
  quantity numeric(10,2) not null default 1,
  unit_price numeric(12,2) not null default 0,
  total numeric(12,2) not null default 0
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  amount numeric(12,2) not null,
  method text not null,
  reference text,
  status text not null default 'Paid',
  paid_at timestamptz not null default now()
);

create table if not exists public.suppliers (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  name text not null,
  phone text,
  email text
);

create table if not exists public.medicines (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  name text not null,
  category text,
  stock int not null default 0,
  reorder_level int not null default 10,
  expiry_date date,
  supplier_id uuid references public.suppliers(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.inventory_transactions (
  id uuid primary key default gen_random_uuid(),
  medicine_id uuid not null references public.medicines(id) on delete cascade,
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  quantity int not null,
  transaction_type text not null check (transaction_type in ('IN','OUT','ADJUSTMENT')),
  reason text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid references public.clinics(id) on delete cascade,
  doctor_id uuid references public.doctors(id) on delete cascade,
  patient_id uuid references public.patients(id) on delete cascade,
  rating int not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id) on delete set null,
  clinic_id uuid references public.clinics(id) on delete set null,
  action text not null,
  entity_type text,
  entity_id uuid,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Helpers used by RLS. SECURITY DEFINER avoids recursive policy checks.
create or replace function public.current_role()
returns text
language sql
stable
security definer
set search_path = public
as $$ select role::text from public.profiles where id = auth.uid() $$;

create or replace function public.has_clinic_access(target_clinic uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'
  )
  or exists (
    select 1 from public.clinics c where c.id = target_clinic and c.owner_id = auth.uid()
  )
  or exists (
    select 1 from public.clinic_staff cs where cs.clinic_id = target_clinic and cs.profile_id = auth.uid() and cs.status = 'Active'
  )
  or exists (
    select 1 from public.doctors d where d.clinic_id = target_clinic and d.id = auth.uid()
  )
  or exists (
    select 1 from public.patients p where p.clinic_id = target_clinic and p.id = auth.uid()
  );
$$;

create or replace function public.can_view_profile(target_user uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select target_user = auth.uid()
  or exists (select 1 from public.doctors d where d.id = target_user and public.has_clinic_access(d.clinic_id))
  or exists (select 1 from public.patients p where p.id = target_user and public.has_clinic_access(p.clinic_id))
  or exists (select 1 from public.clinic_staff s where s.profile_id = target_user and public.has_clinic_access(s.clinic_id));
$$;

-- Automatic profile/role records after Supabase Auth signup.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role text := coalesce(new.raw_user_meta_data->>'role','patient');
  v_name text := coalesce(new.raw_user_meta_data->>'name', split_part(new.email,'@',1));
  v_clinic_id uuid;
begin
  if v_role not in ('patient','doctor','clinic','admin') then v_role := 'patient'; end if;

  insert into public.profiles(id,name,email,role)
  values(new.id,v_name,new.email,v_role::public.user_role)
  on conflict (id) do update set name=excluded.name,email=excluded.email,role=excluded.role,updated_at=now();

  if v_role = 'patient' then
    insert into public.patients(id, patient_code) values(new.id, 'CF-' || upper(substr(replace(new.id::text,'-',''),1,8))) on conflict (id) do nothing;
  elsif v_role = 'doctor' then
    insert into public.doctors(id) values(new.id) on conflict (id) do nothing;
  elsif v_role = 'clinic' then
    insert into public.clinics(owner_id,name,email) values(new.id, coalesce(v_name,'CareFlow Clinic'), new.email) returning id into v_clinic_id;
    insert into public.clinic_staff(clinic_id,profile_id,role) values(v_clinic_id,new.id,'Manager') on conflict (clinic_id,profile_id) do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- updated_at trigger
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$ begin new.updated_at = now(); return new; end $$;
drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at before update on public.profiles for each row execute procedure public.touch_updated_at();

-- Enable RLS everywhere.
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['profiles','clinics','doctors','patients','clinic_staff','doctor_availability','appointments','appointment_status_history','medical_records','medical_documents','vitals','prescriptions','prescription_items','lab_tests','lab_orders','lab_results','messages','message_attachments','notifications','services','invoices','invoice_items','payments','suppliers','medicines','inventory_transactions','reviews','audit_logs']
  LOOP execute format('alter table public.%I enable row level security',t); END LOOP;
END $$;

-- Profiles
DROP POLICY IF EXISTS profiles_select ON public.profiles;
CREATE POLICY profiles_select ON public.profiles FOR SELECT USING (public.can_view_profile(id));
DROP POLICY IF EXISTS profiles_update ON public.profiles;
CREATE POLICY profiles_update ON public.profiles FOR UPDATE USING (id=auth.uid()) WITH CHECK (id=auth.uid());

-- Clinics
DROP POLICY IF EXISTS clinics_select ON public.clinics;
CREATE POLICY clinics_select ON public.clinics FOR SELECT USING (public.has_clinic_access(id));
DROP POLICY IF EXISTS clinics_insert ON public.clinics;
CREATE POLICY clinics_insert ON public.clinics FOR INSERT WITH CHECK (owner_id=auth.uid() OR public.current_role() in ('admin'));
DROP POLICY IF EXISTS clinics_update ON public.clinics;
CREATE POLICY clinics_update ON public.clinics FOR UPDATE USING (owner_id=auth.uid() OR public.current_role()='admin') WITH CHECK (owner_id=auth.uid() OR public.current_role()='admin');

-- Doctors / patients / staff
DROP POLICY IF EXISTS doctors_select ON public.doctors;
CREATE POLICY doctors_select ON public.doctors FOR SELECT USING (id=auth.uid() OR public.has_clinic_access(clinic_id));
DROP POLICY IF EXISTS doctors_update ON public.doctors;
CREATE POLICY doctors_update ON public.doctors FOR UPDATE USING (id=auth.uid() OR public.current_role() in ('clinic','admin')) WITH CHECK (id=auth.uid() OR public.current_role() in ('clinic','admin'));

DROP POLICY IF EXISTS patients_select ON public.patients;
CREATE POLICY patients_select ON public.patients FOR SELECT USING (id=auth.uid() OR public.has_clinic_access(clinic_id));
DROP POLICY IF EXISTS patients_update ON public.patients;
CREATE POLICY patients_update ON public.patients FOR UPDATE USING (id=auth.uid() OR public.current_role() in ('clinic','admin')) WITH CHECK (id=auth.uid() OR public.current_role() in ('clinic','admin'));

DROP POLICY IF EXISTS staff_select ON public.clinic_staff;
CREATE POLICY staff_select ON public.clinic_staff FOR SELECT USING (public.has_clinic_access(clinic_id));
DROP POLICY IF EXISTS staff_write ON public.clinic_staff;
CREATE POLICY staff_write ON public.clinic_staff FOR ALL USING (public.current_role() in ('clinic','admin') AND public.has_clinic_access(clinic_id)) WITH CHECK (public.current_role() in ('clinic','admin') AND public.has_clinic_access(clinic_id));

-- Clinic-scoped operational tables
DROP POLICY IF EXISTS availability_all ON public.doctor_availability;
CREATE POLICY availability_all ON public.doctor_availability FOR ALL USING (exists(select 1 from doctors d where d.id=doctor_id and public.has_clinic_access(d.clinic_id))) WITH CHECK (exists(select 1 from doctors d where d.id=doctor_id and public.has_clinic_access(d.clinic_id)));

DROP POLICY IF EXISTS appointments_all ON public.appointments;
CREATE POLICY appointments_all ON public.appointments FOR ALL USING (patient_id=auth.uid() OR doctor_id=auth.uid() OR public.has_clinic_access(clinic_id)) WITH CHECK (patient_id=auth.uid() OR doctor_id=auth.uid() OR public.has_clinic_access(clinic_id));

DROP POLICY IF EXISTS status_history_all ON public.appointment_status_history;
CREATE POLICY status_history_all ON public.appointment_status_history FOR ALL USING (exists(select 1 from appointments a where a.id=appointment_id and (a.patient_id=auth.uid() or a.doctor_id=auth.uid() or public.has_clinic_access(a.clinic_id)))) WITH CHECK (exists(select 1 from appointments a where a.id=appointment_id and (a.patient_id=auth.uid() or a.doctor_id=auth.uid() or public.has_clinic_access(a.clinic_id))));

DROP POLICY IF EXISTS medical_records_all ON public.medical_records;
CREATE POLICY medical_records_all ON public.medical_records FOR ALL USING (patient_id=auth.uid() OR doctor_id=auth.uid() OR public.has_clinic_access(clinic_id)) WITH CHECK (patient_id=auth.uid() OR doctor_id=auth.uid() OR public.has_clinic_access(clinic_id));

DROP POLICY IF EXISTS medical_documents_all ON public.medical_documents;
CREATE POLICY medical_documents_all ON public.medical_documents FOR ALL USING (patient_id=auth.uid() OR public.has_clinic_access(clinic_id)) WITH CHECK (patient_id=auth.uid() OR public.has_clinic_access(clinic_id));

DROP POLICY IF EXISTS vitals_all ON public.vitals;
CREATE POLICY vitals_all ON public.vitals FOR ALL USING (patient_id=auth.uid() OR exists(select 1 from appointments a where a.id=appointment_id and (a.doctor_id=auth.uid() or public.has_clinic_access(a.clinic_id)))) WITH CHECK (patient_id=auth.uid() OR exists(select 1 from appointments a where a.id=appointment_id and (a.doctor_id=auth.uid() or public.has_clinic_access(a.clinic_id))));

DROP POLICY IF EXISTS prescriptions_all ON public.prescriptions;
CREATE POLICY prescriptions_all ON public.prescriptions FOR ALL USING (patient_id=auth.uid() OR doctor_id=auth.uid() OR public.has_clinic_access(clinic_id)) WITH CHECK (patient_id=auth.uid() OR doctor_id=auth.uid() OR public.has_clinic_access(clinic_id));

DROP POLICY IF EXISTS prescription_items_all ON public.prescription_items;
CREATE POLICY prescription_items_all ON public.prescription_items FOR ALL USING (exists(select 1 from prescriptions p where p.id=prescription_id and (p.patient_id=auth.uid() or p.doctor_id=auth.uid() or public.has_clinic_access(p.clinic_id)))) WITH CHECK (exists(select 1 from prescriptions p where p.id=prescription_id and (p.patient_id=auth.uid() or p.doctor_id=auth.uid() or public.has_clinic_access(p.clinic_id))));

DROP POLICY IF EXISTS lab_tests_select ON public.lab_tests;
CREATE POLICY lab_tests_select ON public.lab_tests FOR SELECT USING (auth.uid() is not null);
DROP POLICY IF EXISTS lab_tests_write ON public.lab_tests;
CREATE POLICY lab_tests_write ON public.lab_tests FOR ALL USING (public.current_role() in ('clinic','admin')) WITH CHECK (public.current_role() in ('clinic','admin'));

DROP POLICY IF EXISTS lab_orders_all ON public.lab_orders;
CREATE POLICY lab_orders_all ON public.lab_orders FOR ALL USING (patient_id=auth.uid() OR doctor_id=auth.uid() OR public.has_clinic_access(clinic_id)) WITH CHECK (patient_id=auth.uid() OR doctor_id=auth.uid() OR public.has_clinic_access(clinic_id));

DROP POLICY IF EXISTS lab_results_all ON public.lab_results;
CREATE POLICY lab_results_all ON public.lab_results FOR ALL USING (exists(select 1 from lab_orders o where o.id=lab_order_id and (o.patient_id=auth.uid() or o.doctor_id=auth.uid() or public.has_clinic_access(o.clinic_id)))) WITH CHECK (exists(select 1 from lab_orders o where o.id=lab_order_id and (o.patient_id=auth.uid() or o.doctor_id=auth.uid() or public.has_clinic_access(o.clinic_id))));

-- Messaging / notifications
DROP POLICY IF EXISTS messages_all ON public.messages;
CREATE POLICY messages_all ON public.messages FOR ALL USING (sender_id=auth.uid() OR receiver_id=auth.uid()) WITH CHECK (sender_id=auth.uid());
DROP POLICY IF EXISTS message_attachments_all ON public.message_attachments;
CREATE POLICY message_attachments_all ON public.message_attachments FOR ALL USING (exists(select 1 from messages m where m.id=message_id and (m.sender_id=auth.uid() or m.receiver_id=auth.uid()))) WITH CHECK (exists(select 1 from messages m where m.id=message_id and m.sender_id=auth.uid()));
DROP POLICY IF EXISTS notifications_all ON public.notifications;
CREATE POLICY notifications_all ON public.notifications FOR ALL USING (user_id=auth.uid()) WITH CHECK (user_id=auth.uid());

-- Billing / inventory / services
DROP POLICY IF EXISTS services_all ON public.services;
CREATE POLICY services_all ON public.services FOR ALL USING (public.has_clinic_access(clinic_id)) WITH CHECK (public.has_clinic_access(clinic_id));
DROP POLICY IF EXISTS invoices_all ON public.invoices;
CREATE POLICY invoices_all ON public.invoices FOR ALL USING (patient_id=auth.uid() OR public.has_clinic_access(clinic_id)) WITH CHECK (patient_id=auth.uid() OR public.has_clinic_access(clinic_id));
DROP POLICY IF EXISTS invoice_items_all ON public.invoice_items;
CREATE POLICY invoice_items_all ON public.invoice_items FOR ALL USING (exists(select 1 from invoices i where i.id=invoice_id and (i.patient_id=auth.uid() or public.has_clinic_access(i.clinic_id)))) WITH CHECK (exists(select 1 from invoices i where i.id=invoice_id and (i.patient_id=auth.uid() or public.has_clinic_access(i.clinic_id))));
DROP POLICY IF EXISTS payments_all ON public.payments;
CREATE POLICY payments_all ON public.payments FOR ALL USING (exists(select 1 from invoices i where i.id=invoice_id and (i.patient_id=auth.uid() or public.has_clinic_access(i.clinic_id)))) WITH CHECK (exists(select 1 from invoices i where i.id=invoice_id and public.has_clinic_access(i.clinic_id)));
DROP POLICY IF EXISTS suppliers_all ON public.suppliers;
CREATE POLICY suppliers_all ON public.suppliers FOR ALL USING (public.has_clinic_access(clinic_id)) WITH CHECK (public.has_clinic_access(clinic_id));
DROP POLICY IF EXISTS medicines_all ON public.medicines;
CREATE POLICY medicines_all ON public.medicines FOR ALL USING (public.has_clinic_access(clinic_id)) WITH CHECK (public.has_clinic_access(clinic_id));
DROP POLICY IF EXISTS inventory_all ON public.inventory_transactions;
CREATE POLICY inventory_all ON public.inventory_transactions FOR ALL USING (public.has_clinic_access(clinic_id)) WITH CHECK (public.has_clinic_access(clinic_id));

DROP POLICY IF EXISTS reviews_all ON public.reviews;
CREATE POLICY reviews_all ON public.reviews FOR ALL USING (patient_id=auth.uid() OR public.has_clinic_access(clinic_id)) WITH CHECK (patient_id=auth.uid() OR public.has_clinic_access(clinic_id));

DROP POLICY IF EXISTS audit_select ON public.audit_logs;
CREATE POLICY audit_select ON public.audit_logs FOR SELECT USING (public.has_clinic_access(clinic_id));
DROP POLICY IF EXISTS audit_insert ON public.audit_logs;
CREATE POLICY audit_insert ON public.audit_logs FOR INSERT WITH CHECK (actor_id=auth.uid());

-- Realtime
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['appointments','messages','notifications','lab_orders','lab_results','prescriptions','payments','inventory_transactions']
  LOOP
    BEGIN execute format('alter publication supabase_realtime add table public.%I',t);
    EXCEPTION WHEN duplicate_object THEN NULL; END;
  END LOOP;
END $$;

-- Private storage bucket for medical documents.
insert into storage.buckets(id,name,public)
values('careflow-documents','careflow-documents',false)
on conflict (id) do nothing;

DROP POLICY IF EXISTS careflow_docs_select ON storage.objects;
CREATE POLICY careflow_docs_select ON storage.objects FOR SELECT TO authenticated USING (bucket_id='careflow-documents');
DROP POLICY IF EXISTS careflow_docs_insert ON storage.objects;
CREATE POLICY careflow_docs_insert ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id='careflow-documents' AND owner_id::uuid = auth.uid());
DROP POLICY IF EXISTS careflow_docs_update ON storage.objects;
CREATE POLICY careflow_docs_update ON storage.objects FOR UPDATE TO authenticated USING (bucket_id='careflow-documents' AND owner_id::uuid = auth.uid());
DROP POLICY IF EXISTS careflow_docs_delete ON storage.objects;
CREATE POLICY careflow_docs_delete ON storage.objects FOR DELETE TO authenticated USING (bucket_id='careflow-documents' AND owner_id::uuid = auth.uid());
