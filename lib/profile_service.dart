// lib/services/profile_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get complete user profile with error handling
  Future<Map<String, dynamic>?> getCompleteUserProfile(String userId) async {
    try {
      // Get user email first from public.users
      final userData = await _supabase
          .from('users')
          .select('email, created_at, updated_at')
          .eq('id', userId)
          .single()
          .timeout(const Duration(seconds: 10));

      if (userData == null) return null;

      // Then get profile details using email
      final profileData = await _supabase
          .from('profiles')
          .select('first_name, last_name, phone_no, image_url')
          .eq('email', userData['email'])
          .single()
          .timeout(const Duration(seconds: 10));

      return {'user': userData, 'profile': profileData};
    } catch (e) {
      print('⚠️ Profile fetch error: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateProfile({
    required String email,
    String? firstName,
    String? lastName,
    String? phoneNo,
    String? imageUrl,
  }) async {
    try {
      final updates = {
        'first_name': firstName,
        'last_name': lastName,
        'phone_no': phoneNo,
      };

      if (imageUrl != null) {
        updates['image_url'] = imageUrl;
      }

      await _supabase
          .from('profiles')
          .update(updates)
          .eq('email', email)
          .timeout(const Duration(seconds: 10));

      print('✅ Profile updated successfully for: $email');
    } catch (e) {
      print('❌ Profile update error: $e');
      rethrow;
    }
  }

  // Check if user exists in public tables
  Future<bool> userExistsInPublicTables(String userId) async {
    try {
      await _supabase
          .from('users')
          .select('id')
          .eq('id', userId)
          .single()
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get user profile by email
  Future<Map<String, dynamic>?> getProfileByEmail(String email) async {
    try {
      final profileData = await _supabase
          .from('profiles')
          .select('*')
          .eq('email', email)
          .single()
          .timeout(const Duration(seconds: 10));
      return profileData;
    } catch (e) {
      print('⚠️ Get profile by email error: $e');
      return null;
    }
  }

  // Update profile image URL
  Future<void> updateProfileImage({
    required String email,
    required String imageUrl,
  }) async {
    try {
      await _supabase
          .from('profiles')
          .update({'image_url': imageUrl})
          .eq('email', email);

      print('✅ Profile image updated for: $email');
    } catch (e) {
      print('❌ Profile image update error: $e');
      rethrow;
    }
  }

  // Create a new user profile
  Future<void> createProfile({
    required String email,
    String? firstName,
    String? lastName,
    String? phoneNo,
  }) async {
    try {
      await _supabase.from('profiles').insert({
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'phone_no': phoneNo,
      });
      //.timeout(const Duration(seconds: 10));

      print('✅ Profile created successfully for: $email');
    } catch (e) {
      print('❌ Profile creation error: $e');
      rethrow;
    }
  }
}
