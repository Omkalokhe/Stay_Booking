import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/auth_controller.dart';

class AdminProfileTab extends StatelessWidget {
  const AdminProfileTab({required this.user, super.key});

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final email = (user['email'] as String?)?.trim() ?? 'admin@gmail.com';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3E1E86),
        foregroundColor: Colors.white,
        title: const Text('Profile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
              ),
              onPressed: () => authController.logout(
                redirectToLogin: true,
                showMessage: false,
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
            ),
          ),
        ],
      ),
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text(
              'Email: $email',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }
}
