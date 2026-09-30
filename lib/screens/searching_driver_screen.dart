import 'dart:async';

import 'package:flutter/material.dart';

import '../models/ride_booking_details.dart';
import '../widgets/ride_map.dart';
import 'trip_screen.dart';

class SearchingDriverScreen extends StatefulWidget {
  const SearchingDriverScreen({super.key});

  static const routeName = '/searching-driver';

  @override
  State<SearchingDriverScreen> createState() => _SearchingDriverScreenState();
}

class _SearchingDriverScreenState extends State<SearchingDriverScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        TripScreen.routeName,
        arguments: ModalRoute.of(context)?.settings.arguments,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final details =
        ModalRoute.of(context)?.settings.arguments as RideBookingDetails?;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: SizedBox(
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(22),
                  ),
                  child: RideMap(
                    pickupPosition: details?.pickupPosition,
                    destinationPosition: details?.destinationPosition,
                    trackCurrentLocation: details == null,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              SizedBox(
                                width: 92,
                                height: 92,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CircularProgressIndicator(
                                      strokeWidth: 6,
                                      color: colorScheme.primary,
                                      backgroundColor: const Color(0xFFE1E7EA),
                                    ),
                                    Center(
                                      child: CircleAvatar(
                                        radius: 30,
                                        backgroundColor: colorScheme.primary,
                                        child: const Icon(
                                          Icons.local_taxi_rounded,
                                          size: 30,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Dang tim tai xe',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Xanh SM dang ket noi ban voi tai xe gan nhat.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Huy chuyen'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
