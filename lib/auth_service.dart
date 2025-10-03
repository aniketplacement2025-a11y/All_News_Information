import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final GoTrueClient _auth = Supabase.instance.client.auth;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final authResponse = await _auth.signUp(email: email, password: password);
    if (authResponse.user != null) {
      // Then automatically insert into public.users
      try {
        await Supabase.instance.client
            .from('users')
            .insert({
              'id': authResponse.user!.id,
              'email': email,
              'created_at': DateTime.now().toIso8601String(),
            });
        print('✅ User successfully added to public.users');
      } catch (e) {
        print('⚠️ Could not add to public.users: $e');
        // Continue anyway - auth user is created successfully
      }
    }
    return authResponse;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
