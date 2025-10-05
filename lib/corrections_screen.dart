import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_service.dart';
import 'auth_service.dart';

class CorrectionsScreen extends StatefulWidget {
  const CorrectionsScreen({super.key});

  @override
  _CorrectionsScreenState createState() => _CorrectionsScreenState();
}

class _CorrectionsScreenState extends State<CorrectionsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();
  final _authService = AuthService();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  XFile? _image;
  bool _isLoading = false;
  String? _userId;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    final user = _authService.currentUser;
    if (user != null) {
      _userId = user.id;
      _userEmail = user.email;

      final profileData = await _profileService.getProfileByEmail(user.email!);
      if (profileData != null) {
        setState(() {
          _firstNameController.text = profileData['first_name'] ?? '';
          _lastNameController.text = profileData['last_name'] ?? '';
          _emailController.text = user.email!;
          _phoneController.text = profileData['phone_no'] ?? '';
        });
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // First, update the text-based profile data
        await _profileService.updateProfile(
          email: _emailController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          phoneNo: _phoneController.text,
        );

        // Then, handle the image upload and update separately
        if (_image != null) {
          final user = _authService.currentUser;
          final userId = user!.id;
          final imageBytes = await _image!.readAsBytes();
          final fileName = 'profile_$userId.${_image!.name.split('.').last}';
          final bucket = Supabase.instance.client.storage.from('avatars');

          await bucket.uploadBinary(
            fileName,
            imageBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

          final imageUrl = bucket.getPublicUrl(fileName);

          // Make a separate call to update just the image URL
          await _profileService.updateProfileImage(
            email: _emailController.text,
            imageUrl: imageUrl,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //       appBar: AppBar(title: const Text('Corrections in Personal Info')),
      // body: const Center(child: Text('This is the Corrections screen.')),
      appBar: AppBar(title: const Text('Update Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_image != null)
                      kIsWeb
                          ? CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(_image!.path),
                            )
                          : CircleAvatar(
                              radius: 50,
                              backgroundImage: FileImage(File(_image!.path)),
                            ),
                    TextButton(
                      onPressed: _pickImage,
                      child: const Text('Change Profile Picture'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _updateProfile,
                      child: const Text('Update Profile'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
