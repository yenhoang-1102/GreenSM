import 'package:flutter/material.dart';

import 'home_screen.dart';
import '../models/ride_booking_details.dart';
import '../services/firebase/analytics_service.dart';
import '../services/firebase/event_tracking_service.dart';
import '../services/firebase/firebase_bootstrap.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  static const routeName = '/rating';

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final _analyticsService = AnalyticsService();
  final _eventTrackingService = EventTrackingService();
  int _rating = 5;

  Future<void> _submitRating(RideBookingDetails? details) async {
    final completedDetails = details;
    if (FirebaseBootstrap.isReady && completedDetails?.bookingId != null) {
      await _analyticsService.logTripCompleted(
        bookingId: completedDetails!.bookingId!,
        rating: _rating,
      );
      await _eventTrackingService.trackTripRated(
        details: completedDetails,
        rating: _rating,
      );
    }

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      HomeScreen.routeName,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final details =
        ModalRoute.of(context)?.settings.arguments as RideBookingDetails?;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const CircleAvatar(
                radius: 44,
                child: Icon(Icons.person_rounded, size: 48),
              ),
              const SizedBox(height: 18),
              Text(
                'Chuyen di the nao?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Danh gia cua ban giup nang cao chat luong dich vu.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final value = index + 1;
                  return IconButton(
                    onPressed: () => setState(() => _rating = value),
                    iconSize: 42,
                    icon: Icon(
                      value <= _rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xFFFFB300),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),
              const TextField(
                minLines: 3,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'De lai loi nhan cho tai xe',
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => _submitRating(details),
                child: const Text('Gui danh gia'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
