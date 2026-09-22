# CareFlow Fix Notes

## Problems addressed

- Fixed missing `/patient`, `/doctor` and `/clinic` route handling by making `lib/core/app.dart` the single app/router owner.
- Added `onGenerateRoute` and `onUnknownRoute` so a stale route cannot crash the app with "Could not find a generator for route".
- Kept `lib/app.dart` as a compatibility export of `core/app.dart`.
- Fixed the login role selector so it has local state and is actually clickable.
- Prevented duplicate dashboard navigation by separating email/password login from OAuth auth-state handling.
- Login now routes by the authenticated Supabase profile role.
- Invalid/missing profile roles produce a useful error instead of silently sending the user back to Welcome.
- Removed legacy `String.fromEnvironment`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `anonKey:` and `--dart-define` usage from the Flutter runtime source.
- Kept a single `Supabase.initialize()` in `lib/main.dart`.

## Current permanent configuration

See `lib/core/config/app_config.dart`.

## Important role behavior

The Patient/Doctor/Clinic selector is for choosing the intended account role in the authentication UI. It cannot elevate an existing Patient account into a Doctor or Clinic Manager account. The database `profiles.role` is authoritative for routing after successful authentication.

For new users, run the supplied `database/schema.sql`; it installs an `auth.users` trigger that creates the profile and role-specific record after signup.
