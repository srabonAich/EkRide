import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ekride_frontend/core/theme.dart';
import 'package:ekride_frontend/models/booking.dart';
import 'package:ekride_frontend/services/api_service.dart';
import 'package:ekride_frontend/services/ride_provider.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<Booking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final list = await api.getMyBookings();
      setState(() {
        _bookings = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Rides & Bookings'),
        actions: [
          IconButton(onPressed: _loadBookings, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _bookings.isEmpty
              ? const Center(
                  child: Text('No active or previous ride bookings found.', style: TextStyle(color: AppTheme.textSecondary)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _bookings.length,
                  itemBuilder: (ctx, idx) {
                    final b = _bookings[idx];
                    final isConfirmed = b.status == 'CONFIRMED';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isConfirmed ? AppTheme.primary.withOpacity(0.5) : AppTheme.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Booking #${b.id} (Ride #${b.rideId})',
                                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isConfirmed ? AppTheme.primary.withOpacity(0.15) : AppTheme.border,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  b.status,
                                  style: TextStyle(
                                    color: isConfirmed ? AppTheme.primary : AppTheme.textMuted,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.trip_origin, color: AppTheme.primary, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text('Pickup: ${b.pickupAddress}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: AppTheme.secondary, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text('Drop-off: ${b.dropoffAddress}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Individual Fare: ৳${b.individualFare.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                                  if (b.savings > 0)
                                    Text('Savings: ৳${b.savings.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              if (isConfirmed) ...[
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        ride.trackBookingOnMap(b);
                                        Navigator.of(context).pop();
                                      },
                                      icon: const Icon(Icons.my_location, size: 16),
                                      label: const Text('Track on Map'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        foregroundColor: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () async {
                                        await context.read<ApiService>().cancelBooking(b.id);
                                        _loadBookings();
                                      },
                                      child: const Text('Cancel', style: TextStyle(color: AppTheme.danger)),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
