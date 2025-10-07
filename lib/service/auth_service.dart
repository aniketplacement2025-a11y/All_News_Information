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
      final AuthResponse authResponse = await _auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'phone_no': phoneNo,
        },
      );
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
