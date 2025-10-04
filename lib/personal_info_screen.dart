import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'profile_service.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  _PersonalInfoScreenState createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();

  late Future<Map<String, dynamic>?> _profileFuture;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _authService.currentUser;
    if (_user != null) {
      _profileFuture = _profileService.getProfileByEmail(_user!.email!);
    } else {
      // Handle the case where the user is not logged in
      _profileFuture = Future.value(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Info'), centerTitle: true),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No profile data found.'));
          } else {
            final profile = snapshot.data!;
            final email = _user?.email ?? 'No email';
            final firstName = profile['first_name'] ?? 'N/A';
            final lastName = profile['last_name'] ?? 'N/A';
            final phoneNo = profile['phone_no'] ?? 'N/A';
            final imageUrl = profile['image_url'];

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: imageUrl != null
                        ? NetworkImage(imageUrl)
                        : null,
                    child: imageUrl == null
                        ? Text(
                            email.isNotEmpty ? email[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 40),
                          )
                        : null,
                  ),
                  const SizedBox(height: 20),
                  _buildInfoTile('Email', email),
                  _buildInfoTile('First Name', firstName),
                  _buildInfoTile('Last Name', lastName),
                  _buildInfoTile('Phone Number', phoneNo),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildInfoTile(String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }
}
