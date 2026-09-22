import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static Future<void> initialize() async {
    if (url.isEmpty) {
      throw Exception(
        'SUPABASE_URL is missing. Start CareFlow with --dart-define=SUPABASE_URL=...',
      );
    }

    if (publishableKey.isEmpty) {
      throw Exception(
        'SUPABASE_ANON_KEY is missing. Start CareFlow with --dart-define=SUPABASE_ANON_KEY=...',
      );
    }

    await Supabase.initialize(
      url: url,
      publishableKey: publishableKey,
    );
  }
}
