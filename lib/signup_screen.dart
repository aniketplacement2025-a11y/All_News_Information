import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'auth_service.dart';
import 'profile_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _customDomainController = TextEditingController();
  final _authService = AuthService();
  final _profileService = ProfileService();

  bool _isLoading = false;

  // Common domains list
  final List<String> _commonDomains = [
    'gmail.com',
    'yahoo.com',
    'hotmail.com',
    'outlook.com',
    'icloud.com',
    'protonmail.com',
    'aol.com',
    'zoho.com',
    'yandex.ru',
    'mail.ru',
    'gmx.com',
    'fastmail.com',
    'tutanota.com',
    'hushmail.com',
    'live.com',
    'msn.com',
  ];

  final List<String> _customDomains = [];

  String _selectedDomain = 'gmail.com';
  String _completePhoneNumber = '';

  void _addCustomDomain() {
    final domain = _customDomainController.text.trim().toLowerCase();
    if (domain.isEmpty) return;

    // Enhanced domain validation
    if (!RegExp(
      r'^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,}$',
    ).hasMatch(domain)) {
      _showErrorSnackbar('Please enter a valid domain name');
      return;
    }

    if (!_customDomains.contains(domain) && !_commonDomains.contains(domain)) {
      setState(() {
        _customDomains.add(domain);
        _selectedDomain = domain;
        _customDomainController.clear();
      });
      FocusScope.of(context).unfocus();
      _showSuccessSnackbar('Domain added successfully!');
    } else {
      _showErrorSnackbar('This domain is already in the list');
    }
  }

  String get _fullEmail {
    return '${_emailUsernameController.text.trim()}@$_selectedDomain';
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await _authService.signUp(
        email: _fullEmail,
        password: _passwordController.text,
        firstName: _firstNameController.text.trim().isNotEmpty
            ? _firstNameController.text.trim()
            : null,
        lastName: _lastNameController.text.trim().isNotEmpty
            ? _lastNameController.text.trim()
            : null,
        phoneNo: _completePhoneNumber.isNotEmpty ? _completePhoneNumber : null,
      );
      if (response.user != null) {
        // After successful signup, create the profile with retry logic to handle replication delay.
        bool profileCreated = false;
        for (int i = 0; i < 10; i++) {
          // Retry for up to 10 seconds
          try {
            await _profileService.createProfile(
              email: _fullEmail,
              firstName: _firstNameController.text.trim().isNotEmpty
                  ? _firstNameController.text.trim()
                  : null,
              lastName: _lastNameController.text.trim().isNotEmpty
                  ? _lastNameController.text.trim()
                  : null,
              phoneNo: _completePhoneNumber.isNotEmpty
                  ? _completePhoneNumber
                  : null,
            );
            profileCreated = true;
            break; // On success, exit the loop.
          } on PostgrestException catch (e) {
            // If it's a foreign key violation, it's likely a replication delay.
            // Wait and retry. Don't wait on the final attempt.
            if (e.code == '23503' && i < 9) {
              print(
                'Attempt ${i + 1} failed: Foreign key violation. Retrying...',
              );
              await Future.delayed(const Duration(seconds: 1));
            } else {
              // For any other error, or on the last attempt, rethrow.
              rethrow;
            }
          }
        }

        if (!profileCreated) {
          throw Exception('Profile creation failed after multiple retries.');
        }

        if (mounted) {
          _showSuccessDialog();
        }
      }
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('user already registered')) {
        _showUserExistsDialog();
      } else {
        _showErrorSnackbar(e.message);
      }
    } catch (e) {
      _showErrorSnackbar('An unexpected error occurred. Please try again.');
      print('Signup error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showUserExistsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Already Registered'),
        content: const Text(
          'An account with this email already exists. Please log in.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              Navigator.of(
                context,
              ).pop(); // Go back to the previous screen (login)
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Registration Successful'),
        content: const Text('Please check your email for verification link.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to login
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        leading: _isLoading
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Phone Number Section with intl_phone_field
                    const Text(
                      'Phone Number',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    IntlPhoneField(
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      initialCountryCode: 'IN',
                      onChanged: (phone) {
                        setState(() {
                          _completePhoneNumber = phone.completeNumber;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Email Section
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Email Username
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _emailUsernameController,
                            decoration: const InputDecoration(
                              hintText: 'username',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter email username';
                              }
                              if (value.contains('@')) {
                                return 'Do not include @ symbol';
                              }
                              if (!RegExp(
                                r'^[a-zA-Z0-9._-]+$',
                              ).hasMatch(value)) {
                                return 'Only letters, numbers, ., -, _ are allowed';
                              }
                              return null;
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '@',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Domain Dropdown
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: _selectedDomain,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 16,
                              ),
                            ),
                            isExpanded: true,
                            items:
                                [
                                      ..._commonDomains.map((domain) {
                                        return DropdownMenuItem<String>(
                                          value: domain,
                                          child: Text(
                                            domain,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        );
                                      }),
                                      if (_customDomains.isNotEmpty) ...[
                                        const DropdownMenuItem<String>(
                                          value: 'divider',
                                          enabled: false,
                                          child: Divider(),
                                        ),
                                        ..._customDomains.map((domain) {
                                          return DropdownMenuItem<String>(
                                            value: domain,
                                            child: Text(
                                              domain,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    ]
                                    .where(
                                      (item) =>
                                          item.value != 'divider' ||
                                          _customDomains.isNotEmpty,
                                    )
                                    .toList(),
                            onChanged: (value) {
                              if (value != null && value.isNotEmpty) {
                                setState(() {
                                  _selectedDomain = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    // Custom Domain Section
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _customDomainController,
                            decoration: const InputDecoration(
                              hintText:
                                  'Add custom domain (e.g., organization.com)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                            onFieldSubmitted: (_) => _addCustomDomain(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _addCustomDomain,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    if (_customDomains.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _customDomains.map((domain) {
                          return Chip(
                            label: Text(domain),
                            onDeleted: () {
                              setState(() {
                                _customDomains.remove(domain);
                                if (_selectedDomain == domain) {
                                  _selectedDomain = _commonDomains.first;
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signup,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Create Account',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Already have an account? Log in'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _emailUsernameController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _customDomainController.dispose();
    super.dispose();
  }
}
