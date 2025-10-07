import 'dart:async';
import 'package:flutter/material.dart';
import 'service/profile_service.dart';
import 'screen/home_screen.dart';
import 'screen/login_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String userEmail;

  const ProfileSetupScreen({super.key, required this.userEmail});

  @override
  _ProfileSetupScreenState createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final ProfileService _profileService = ProfileService();
  Timer? _pollingTimer;
  int _elapsedSeconds = 0;
  final int _timeoutSeconds = 30;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_elapsedSeconds >= _timeoutSeconds) {
        _pollingTimer?.cancel();
        _handleTimeout();
        return;
      }

      final profile = await _profileService.getProfileByEmail(widget.userEmail);
      if (profile != null) {
        _pollingTimer?.cancel();
        _navigateToHome();
      }

      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  void _handleTimeout() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not set up your profile. Please try logging in.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Setting up your profile, please wait...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
