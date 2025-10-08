import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../service/auth_service.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import '../service/profile_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _profileService = ProfileService();
  bool _isLoading = false; // ADD LOADING STATE

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      // setState(() => _isLoading = true); // START LOADING
      // try {
      setState(() => _isLoading = true);

      final connectivityResult = await (Connectivity().checkConnectivity());

      try {
        if (connectivityResult == ConnectivityResult.none) {
          // Offline Flow
          final box = Hive.box('auth_cache');
          final sessionJson = box.get('session');

          if (sessionJson != null) {
            final sessionData = jsonDecode(sessionJson as String);
            final cachedUser = sessionData['user'] != null
                ? User.fromJson(sessionData['user'])
                : null;

            if (cachedUser != null &&
                cachedUser.email == _emailController.text) {
              // Email matches, grant access for offline mode
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Email does not match cached session or no session found.',
                  ),
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No offline session available. Please connect to the internet.',
                ),
              ),
            );
          }
        } else {
          // Online Flow
          final response = await _authService.signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
          if (response.user != null) {
            // VERIFY USER EXISTS IN PUBLIC.USERS TABLE
            await _verifyUserInPublicTables(response.user!);

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      } on AuthException catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
        //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      } catch (e) {
        // ADD GENERAL ERROR CATCH
        // ScaffoldMessenger.of(
        //   context,
        // ).showSnackBar(SnackBar(content: Text('Login error: $e')));

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      } finally {
        // STOP LOADING
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // ADD VERIFICATION METHOD
  Future<void> _verifyUserInPublicTables(User user) async {
    try {
      final profile = await _profileService.getCompleteUserProfile(user.id);
      if (profile != null) {
        print('✅ Login successful - User found in public tables: $profile');
      } else {
        print('⚠️ User not found in public tables, but auth login successful');
      }
    } catch (e) {
      print('⚠️ Error checking public tables: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SignupScreen(),
                    ),
                  );
                },
                child: const Text('Don\'t have an account? Sign up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
