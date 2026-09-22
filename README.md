# CareFlow Patient — Flutter + Supabase

This is the patient-side implementation matching the supplied CareFlow screenshots.

## Included
- Supabase Auth sign in / registration
- Patient Home
- Appointments + live doctor list + booking
- Medical Records
- Test Results
- My Health / vitals
- Prescriptions
- Messages
- Profile / Personal Information
- Health Preferences
- Notifications
- Privacy & Security
- Help & Support
- RLS policies so a patient only reads/writes their own patient data

## 1. Create the database
Open Supabase SQL Editor and run:

`supabase/patient_schema.sql`

Do NOT create a second set of tables if your existing CareFlow schema already has equivalent tables. In that case, map the Dart service queries to your real column names.

## 2. Run Flutter

```bash
flutter pub get

flutter run ^
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_ANON_KEY
```

PowerShell uses the same command but with backticks for line continuation, or put it on one line.

## 3. Important
The app intentionally has NO fake patient data. Empty database = empty UI.

You must create at least one active doctor in `public.doctors` before booking:

```sql
insert into public.doctors (name, specialty)
values ('Dr. Example', 'General Medicine');
```

Create patients through the app registration screen. The app creates the matching `profiles` row.

## Existing CareFlow project
If this is being merged into an existing CareFlow app, do not blindly run the schema. The screenshots show that the current project has a different schema:
- `public.medical_records` is missing
- `public.messages` is missing
- code references `profiles.name`, but your current profiles table appears not to have `name`
- code references `clinics.owner_id`, but your current clinics table does not have `owner_id`

Those are schema/code mismatches, not Flutter UI problems. This patient package uses explicit patient tables and `first_name`/`last_name` instead of `profiles.name`.
