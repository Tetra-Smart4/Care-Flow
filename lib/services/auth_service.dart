import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient client = Supabase.instance.client;

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> profile,
  }) async {
    final response = await client.auth.signUp(
      email: email.trim(),
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Account could not be created.');
    }

    await client.from('profiles').upsert({
      'id': user.id,
      ...profile,
    });

    return response;
  }

  static Future<String?> getCurrentRole() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final row = await client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    return row?['role'] as String?;
  }

  static Future<void> signOut() => client.auth.signOut();
}
