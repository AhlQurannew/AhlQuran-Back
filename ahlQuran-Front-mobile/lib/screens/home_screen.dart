import 'package:flutter/material.dart';
import '../models/guardian.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  final LoginResponse loginResponse;

  const HomeScreen({super.key, required this.loginResponse});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Guardian Dashboard',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${loginResponse.user.firstname}!',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (loginResponse.guardian != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Guardian Information',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Name: ${loginResponse.guardian!.firstName} ${loginResponse.guardian!.lastName}',
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                      if (loginResponse.guardian!.relationship != null)
                        Text(
                          'Relationship: ${loginResponse.guardian!.relationship}',
                          style: const TextStyle(fontFamily: 'Poppins'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Your children\'s information will appear here.',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
