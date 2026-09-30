import 'package:flutter/material.dart';

import '../models/ride_booking_details.dart';
import 'booking_confirmation_screen.dart';

class VehicleSelectionScreen extends StatefulWidget {
  const VehicleSelectionScreen({super.key});

  static const routeName = '/vehicle-selection';

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  int _selectedIndex = 0;

  final _vehicles = const [
    _VehicleOption(
      icon: Icons.electric_bike_rounded,
      name: 'Xanh SM Bike',
      description: 'Nhanh gon cho mot hanh khach',
      time: '3 phut',
    ),
    _VehicleOption(
      icon: Icons.electric_car_rounded,
      name: 'Xanh SM Car',
      description: 'Thoai mai cho 1-4 khach',
      time: '5 phut',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final details =
        ModalRoute.of(context)?.settings.arguments as RideBookingDetails?;

    return Scaffold(
      appBar: AppBar(title: const Text('Chon goi dat xe')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _vehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = _vehicles[index];
                  final selected = _selectedIndex == index;
                  final vehicleDetails = details?.copyWith(
                    vehicleName: vehicle.name,
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => setState(() => _selectedIndex = index),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : const Color(0xFFEFF3F6),
                              child: Icon(
                                vehicle.icon,
                                color: selected ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vehicle.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(vehicle.description),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Den trong ${vehicle.time}',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatPrice(
                                vehicleDetails?.estimatedPriceValue ??
                                    (index == 0 ? 10000 : 20000),
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: FilledButton(
                onPressed: () {
                  final selectedVehicle = _vehicles[_selectedIndex];
                  Navigator.pushNamed(
                    context,
                    BookingConfirmationScreen.routeName,
                    arguments: details?.copyWith(
                      vehicleName: selectedVehicle.name,
                    ),
                  );
                },
                child: const Text('Dat xe'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleOption {
  const _VehicleOption({
    required this.icon,
    required this.name,
    required this.description,
    required this.time,
  });

  final IconData icon;
  final String name;
  final String description;
  final String time;
}

String _formatPrice(double value) {
  final digits = value.round().toString();
  return '${digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  )}d';
}
