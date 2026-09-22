# CareFlow — Supabase + Clickable Authentication

The app now permanently uses the Supabase project configured in `lib/core/config/app_config.dart`.

## Local run

```powershell
flutter clean
flutter pub get
dart format lib
dart analyze
flutter run
```

No `--dart-define` arguments are required.

## Required Supabase Auth setup

### Email/password

Supabase Dashboard → Authentication → Providers → Email

Enable Email provider.

If email confirmation is enabled, users must verify their email before signing in.

### Google

Supabase Dashboard → Authentication → Providers → Google

Configure the Google OAuth client and enable the provider.

Add this redirect URL to the Supabase Auth redirect allow-list:

`io.supabase.careflow://login-callback/`

### Apple

Supabase Dashboard → Authentication → Providers → Apple

Configure Apple Sign In and add the same redirect URL if using the OAuth flow:

`io.supabase.careflow://login-callback/`

For Android/iOS native deep-link return, the platform project must register the `io.supabase.careflow` scheme.

The login buttons now start real Supabase OAuth instead of showing the old “Enable Google OAuth” placeholder message.

## Important

The app contains only the Supabase publishable key. Never put a Supabase `service_role` or `sb_secret_...` key in Flutter.

The `profiles` table must contain the authenticated user's profile and a valid `role` value such as:

- `patient`
- `doctor`
- `clinic`
- `admin`

RLS policies must permit each authenticated role to read the data it needs.
