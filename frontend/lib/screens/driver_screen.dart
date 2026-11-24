import 'package:flutter/material.dart';
import 'package:ekride_frontend/core/theme.dart';

class DriverScreen extends StatelessWidget {
  const DriverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Driver & Vehicle Hub'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Registered Vehicle', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _vehicleRow(Icons.directions_car, 'Vehicle', 'Toyota Corolla Hybrid (Silver)'),
                  const SizedBox(height: 8),
                  _vehicleRow(Icons.badge, 'License Plate', 'DHAKA-METRO-GA-45-8899'),
                  const SizedBox(height: 8),
                  _vehicleRow(Icons.event_seat, 'Capacity', '4 Seats (3 Passenger capacity)'),
                  const SizedBox(height: 8),
                  _vehicleRow(Icons.verified, 'Campus Verification', 'Active DU Sticker #2024'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Active Corridor Drive Offers', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text('You are scheduled to depart along the Dhaka University -> Banani corridor at 08:30 AM.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Booked Capacity: 2 / 3 seats', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                        Text('Projected Earnings: ৳352.30', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vehicleRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.secondary, size: 18),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
