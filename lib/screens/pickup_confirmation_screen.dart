import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/ride_booking_details.dart';
import '../services/geocoding_service.dart';
import '../widgets/ride_map.dart';
import 'booking_confirmation_screen.dart';

class PickupConfirmationScreen extends StatefulWidget {
  const PickupConfirmationScreen({super.key});

  static const routeName = '/pickup-confirmation';

  @override
  State<PickupConfirmationScreen> createState() =>
      _PickupConfirmationScreenState();
}

class _PickupConfirmationScreenState extends State<PickupConfirmationScreen> {
  final _driverNoteController = TextEditingController();
  final _geocodingService = GeocodingService();
  LatLng? _pickupPosition;
  String? _pickupAddress;

  @override
  void dispose() {
    _driverNoteController.dispose();
    super.dispose();
  }

  void _confirmPickup(RideBookingDetails details) {
    Navigator.pushNamed(
      context,
      BookingConfirmationScreen.routeName,
      arguments: details.copyWith(
        pickupPosition: _pickupPosition,
        pickupAddress: _pickupAddress,
        pickupNote: _driverNoteController.text.trim(),
      ),
    );
  }

  Future<void> _handleCurrentLocationChanged(LatLng position) async {
    if (!mounted) return;
    setState(() => _pickupPosition = position);

    try {
      final result = await _geocodingService
          .reverseGeocode(position)
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _pickupPosition = result.position;
        _pickupAddress = result.address;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pickupAddress =
            '${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final details =
        ModalRoute.of(context)?.settings.arguments as RideBookingDetails?;

    if (details == null) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: Text('Khong tim thay thong tin diem don')),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: RideMap(
              pickupPosition: _pickupPosition ?? details.pickupPosition,
              showRoute: false,
              locationButtonBottom: 326,
              onCurrentLocationChanged: _handleCurrentLocationChanged,
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _MapControlButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Quay lai',
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                Material(
                  color: Colors.white,
                  elevation: 3,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_rounded),
                          SizedBox(width: 8),
                          Text(
                            'Tim kiem',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 250),
              child: _PickupPin(),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                MediaQuery.paddingOf(context).bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 24,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCE7E7),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Diem don',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _pickupAddress ?? details.pickupAddress,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _driverNoteController,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: 'Them ghi chu cho bac tai (vi du: gan cong)',
                      prefixIcon: Icon(Icons.edit_note_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => _confirmPickup(details),
                    child: const Text('Chon diem don nay'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        tooltip: tooltip,
      ),
    );
  }
}

class _PickupPin extends StatelessWidget {
  const _PickupPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Color(0x26000000), blurRadius: 12),
            ],
          ),
          child: const Text(
            'Diem don',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        const Icon(Icons.location_on_rounded, size: 48, color: Colors.black87),
      ],
    );
  }
}
