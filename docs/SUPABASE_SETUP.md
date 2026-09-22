# CareFlow Supabase Setup

## Step 1 — Create a Supabase project

Create a new Supabase project and keep the project URL and publishable/anon key ready.

## Step 2 — Create the database

Open **Supabase Dashboard → SQL Editor**, paste the complete contents of:

`database/schema.sql`

Run it once.

The SQL creates:

- profiles / role system
- clinic, doctor and patient records
- appointments and status history
- medical records and documents
- vitals and prescriptions
- lab orders and results
- messages and notifications
- invoices, payments and billing
- medicines, suppliers and inventory
- reviews and audit logs
- RLS helper functions and policies
- signup trigger
- Realtime publication entries
- private document storage bucket

## Step 3 — Authentication settings

In **Authentication → Providers**, enable Email.

During development you may disable email confirmation to make local testing easier. In production, use verified email/phone flows.

Google and Apple buttons in the UI require their providers to be configured in Supabase Auth before use.

## Step 4 — Run the app

PowerShell:

```powershell
flutter pub get

dart format lib

flutter analyze

flutter run
```

Chrome:

```powershell
flutter run -d chrome
```

Or use the included helper:

```powershell
.\run_supabase.ps1
```

## Step 5 — Create accounts

Register a Patient, Doctor and Clinic account from the app.

The Auth trigger in `schema.sql` automatically creates:

- `profiles` row
- `patients` row for patient users
- `doctors` row for doctor users
- `clinics` + manager staff row for clinic users

The login route uses the saved `profiles.role`, not the selected UI tab. This prevents a user from choosing a different role in the UI to gain another dashboard.

## Step 6 — Assign doctors and patients to a clinic

The clinic manager can create staff records and assign doctors/patients. For early development, this can also be done from SQL Editor.

Example:

```sql
update public.doctors
set clinic_id = 'YOUR_CLINIC_UUID'
where id = 'DOCTOR_PROFILE_UUID';

update public.patients
set clinic_id = 'YOUR_CLINIC_UUID'
where id = 'PATIENT_PROFILE_UUID';
```

## Step 7 — Realtime

The schema adds these tables to `supabase_realtime`:

- appointments
- messages
- notifications
- lab_orders
- lab_results
- prescriptions
- payments
- inventory_transactions

`lib/services/realtime_service.dart` provides the reusable Flutter subscription layer.

## Step 8 — What is live

The Supabase-ready services query PostgreSQL for:

- appointments
- doctors
- patients
- clinic statistics
- medical records
- prescriptions + prescription items
- lab orders
- invoices
- medicines
- notifications
- messages
- analytics summaries
- report summaries

The previous generated demo fallback values were removed from the service layer. Empty database tables now produce empty states rather than fake clinical data.

## Production note

This is an engineering starter, not a certified clinical system. Before real patient use, add legal/compliance review, formal audit requirements, stronger storage authorization, backups, monitoring, payment provider integration, push notification credentials, data retention rules and full automated tests.
