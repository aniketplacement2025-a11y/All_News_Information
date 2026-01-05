import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';
import 'dart:convert';

class AuthService {
  final GoTrueClient _auth = Supabase.instance.client.auth;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.session != null) {
      final box = await Hive.openBox('auth_cache');
      // Storing the session details
      box.put('session', jsonEncode(response.session!.toJson()));
      if (response.user != null) {
        box.put('user', jsonEncode(response.user!.toJson()));
      }
    }
    return response;
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
