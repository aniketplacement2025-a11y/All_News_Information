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
    String? firstName,
    String? lastName,
    String? phoneNo,
  }) async {
    final authResponse = await _auth.signUp(email: email, password: password);
    final user = authResponse.user;
    if (user == null)
      throw Exception('User creation failed - no user returned');
    else {
      try {
        // 2. Wait a moment for auth to fully complete
        await Future.delayed(const Duration(seconds: 1));
        // Insert into public.users table
        await Supabase.instance.client.from('users').insert({
          'id': user.id,
          'email': user.email!,
        });

        // Insert into public.profile table
        await Supabase.instance.client.from('profile').insert({
          'email': user.email!,
          'first_name': firstName,
          'last_name': lastName,
          'phone_no': phoneNo,
          // first_name, last_name, etc., can be added here
          // if they are collected during sign-up
        });

        print('✅ User created and profile initialized in public tables.');
      } catch (e) {
        print('Error setting up user profile: $e');
        // If anything fails after auth user creation, we should clean up
        if (e is AuthException &&
            e.message.contains('User already registered')) {
          // This is fine - user exists in auth but maybe public tables failed
          rethrow;
        }
        // Rethrow a more specific exception to be handled by the UI
        throw Exception('Failed to set up user profile.');
      }
    }
    return authResponse;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
  // Simple auth state check
  User? get currentUser => _auth.currentUser;
  // Auth state changes stream
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;
}
