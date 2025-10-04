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
    try {
      // Step 1: Create the user in Supabase auth
      final AuthResponse authResponse = await _auth.signUp(
        email: email,
        password: password,
      );

      final user = authResponse.user;
      if (user == null) {
        throw Exception('Sign up successful, but no user object was returned.');
      }

      // Step 2: Insert into the public.users table
      try {
        await Supabase.instance.client.from('users').insert({
          'id': user.id,
          'email': user.email!,
        });
        print('✅ User created in public.users');
      } catch (e) {
        print('⚠️ Could not insert into public.users: $e');
        // Don't throw critical error - auth user is created successfully
        // User can still login, we'll handle profile creation later
      }

      // Step 3: Insert into the public.profile table
      try {
        await Supabase.instance.client.from('profiles').insert({
          // Changed from 'profile' to 'profiles'
          'email': user.email!,
          'first_name': firstName,
          'last_name': lastName,
          'phone_no': phoneNo,
          // first_name, last_name, etc., can be added here
          // if they are collected during sign-up
        });
        print('✅ Profile created in public.profiles');
      } catch (e) {
        print('⚠️ Could not insert into public.profiles: $e');
        // Non-critical error - profile can be created later
      }

      print('✅ User created and profile initialized in public tables.');
      return authResponse;
    } on AuthException catch (e) {
      // Handle specific auth errors
      print('Auth Error during sign up: ${e.message}');

      if (e.message.contains('already registered')) {
        throw AuthException('Email already registered. Please try logging in.');
      }
      rethrow; // Re-throw other auth exceptions
    } catch (e) {
      // Catch any other unexpected errors
      print('Unexpected error during sign up: $e');
      throw Exception('An unexpected error occurred during sign up.');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Simple auth state check
  User? get currentUser => _auth.currentUser;
  // Auth state changes stream
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;
}
