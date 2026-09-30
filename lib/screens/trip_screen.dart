import 'package:flutter/material.dart';

import '../models/ride_booking_details.dart';
import '../services/firebase/database_service.dart';
import '../services/firebase/firebase_bootstrap.dart';
import '../widgets/ride_map.dart';
import 'rating_screen.dart';

class TripScreen extends StatelessWidget {
  const TripScreen({super.key});

  static const routeName = '/trip';

  @override
  Widget build(BuildContext context) {
    final details =
        ModalRoute.of(context)?.settings.arguments as RideBookingDetails?;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  RideMap(
                    showRoute: true,
                    pickupPosition: details?.pickupPosition,
                    destinationPosition: details?.destinationPosition,
                    trackCurrentLocation: details == null,
                  ),
                  Positioned(
                    top: 18,
                    left: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Quay lai',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tai xe dang den',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text('Du kien don ban sau 3 phut'),
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        child: Icon(Icons.person_rounded),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nguyen Minh Khoa',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            Text('Toyota Vios - 51G 123.45'),
                          ],
                        ),
                      ),
                      Icon(Icons.star_rounded, color: Color(0xFFFFB300)),
                      Text('4.9'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.call_rounded),
                          label: const Text('Goi'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            if (FirebaseBootstrap.isReady &&
                                details?.bookingId != null) {
                              await DatabaseService().updateBookingStatus(
                                bookingId: details!.bookingId!,
                                status: 'completed',
                              );
                            }
                            if (!context.mounted) return;
                            Navigator.pushReplacementNamed(
                              context,
                              RatingScreen.routeName,
                              arguments: details,
                            );
                          },
                          icon: const Icon(Icons.flag_rounded),
                          label: const Text('Ket thuc'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
