import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
       setState(() => _isLoading = true);
      try {
        final response = await _authService.signUp(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (response.user != null) {
          //await _verifyUserInPublicTable(response.user!.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful! Please check your email for verification.')),
          );
          Navigator.of(context).pop();
        }
      } on AuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }catch (e) { // ADD THIS CATCH BLOCK
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally { // ADD THIS FINALLY BLOCK
        setState(() => _isLoading = false);
      }
    }
  }
  
  // ADD THIS ENTIRE METHOD
  // Future<void> _verifyUserInPublicTable(String userId) async {
  //   try {
  //     // Wait a moment for the trigger to execute
  //     await Future.delayed(Duration(seconds: 2));
      
  //     final data = await Supabase.instance.client
  //         .from('users')
  //         .select()
  //         .eq('id', userId)
  //         .single();
          
  //     print('✅ User successfully created in public.users: $data');
  //   } catch (e) {
  //     print('⚠️ User not found in public.users yet: $e');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
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
                    return 'Please enter a password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signup,
                child: const Text('Sign Up'),
              ),
              TextButton(
                onPressed: _isLoading ? null : () { 
                  Navigator.of(context).pop();
                },
                child: const Text('Already have an account? Log in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}