import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ekride_frontend/core/theme.dart';
import 'package:ekride_frontend/services/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final isDriver = user.role == 'DRIVER';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Student Profile & Settings')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.primary.withOpacity(0.2),
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0] : 'S',
                    style: const TextStyle(color: AppTheme.primary, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 14),
                Text(user.fullName, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(user.university ?? 'University of Dhaka', style: const TextStyle(color: AppTheme.secondary, fontSize: 13)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                      const SizedBox(width: 6),
                      Text('${user.rating.toStringAsFixed(2)} Peer Rating', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: AppTheme.border),
                const SizedBox(height: 16),
                _infoTile('Student ID', user.studentId ?? 'N/A', Icons.badge_outlined),
                _infoTile('Email Address', user.email, Icons.email_outlined),
                _infoTile('Phone', user.phone ?? 'N/A', Icons.phone_outlined),
                _infoTile('Current Role', user.role, Icons.security),
                const SizedBox(height: 24),
                // Switch Role Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      auth.switchRole(isDriver ? 'PASSENGER' : 'DRIVER');
                    },
                    icon: Icon(isDriver ? Icons.person : Icons.directions_car, color: AppTheme.primary),
                    label: Text(
                      isDriver ? 'Switch to Passenger Mode' : 'Switch to Driver Mode',
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
