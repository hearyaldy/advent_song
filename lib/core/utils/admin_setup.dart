// lib/core/utils/admin_setup.dart
// This is a utility file to help create your first admin user
// IMPORTANT: Remove this file from production builds for security

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AdminSetup {
  // Call this function once to create your first admin user
  static Future<void> createFirstAdmin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Creating admin user...'),
            ],
          ),
        ),
      );

      // Create admin user
      final success = await AuthService.createAdminUser(email, password);

      // Close loading dialog
      Navigator.of(context).pop();

      if (success) {
        _showSuccessDialog(context, email);
      } else {
        _showErrorDialog(
            context, 'Failed to create admin user. Please try again.');
      }
    } catch (e) {
      // Close loading dialog if still open
      Navigator.of(context).pop();
      _showErrorDialog(context, 'Error: $e');
    }
  }

  static void _showSuccessDialog(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin user created successfully!'),
            const SizedBox(height: 16),
            Text('Email: $email'),
            const SizedBox(height: 8),
            const Text('You can now:'),
            const Text('1. Login using the dashboard'),
            const Text('2. Access sermon management'),
            const Text('3. Add/edit/delete sermons'),
            const SizedBox(height: 16),
            const Text(
              'IMPORTANT: Please remove the AdminSetup utility from your production app for security.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Simple UI for admin setup - add this to your dashboard temporarily
  static Widget buildSetupButton(BuildContext context) {
    final emailController = TextEditingController(text: 'admin@yourchurch.com');
    final passwordController = TextEditingController(text: 'SecurePassword123');

    return Card(
      color: Colors.orange.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'First Time Setup',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Create your first admin user:'),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Admin Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Admin Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      createFirstAdmin(
                        email: emailController.text.trim(),
                        password: passwordController.text,
                        context: context,
                      );
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Create Admin User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: Remove this setup utility after creating your admin user.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// USAGE EXAMPLE:
// Add this to your dashboard temporarily (remove after setup):
/*

// In dashboard_page.dart, add this to your SliverList children:

// TEMPORARY: Admin Setup (remove after first setup)
if (!AuthService.isLoggedIn) ...[
  AdminSetup.buildSetupButton(context),
  const SizedBox(height: 24),
],

*/
