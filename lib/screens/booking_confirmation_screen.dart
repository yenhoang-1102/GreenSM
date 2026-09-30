import 'package:flutter/material.dart';

import '../models/ride_booking_details.dart';
import '../services/firebase/analytics_service.dart';
import '../services/firebase/auth_service.dart';
import '../services/firebase/database_service.dart';
import '../services/firebase/event_tracking_service.dart';
import '../services/firebase/firebase_bootstrap.dart';
import '../widgets/ride_map.dart';
import 'searching_driver_screen.dart';

class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({super.key});

  static const routeName = '/booking-confirmation';

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  final _analyticsService = AnalyticsService();
  final _eventTrackingService = EventTrackingService();
  final _screenStopwatch = Stopwatch();
  final _vouchers = const [
    _RideVoucherOption(code: 'Khong dung voucher', discountAmount: 0),
    _RideVoucherOption(code: 'RIDE20', discountAmount: 20000),
    _RideVoucherOption(code: 'NEWUSER30', discountAmount: 30000),
    _RideVoucherOption(code: 'WEEKEND15', discountAmount: 15000),
  ];
  final _vehicles = const [
    _RideVehicleOption(
      icon: Icons.electric_bike_rounded,
      name: 'Green Bike',
      description: '1 khach',
      arrivalMinutes: 2,
    ),
    _RideVehicleOption(
      icon: Icons.electric_car_rounded,
      name: 'Green Car',
      description: '4 khach',
      arrivalMinutes: 3,
      recommended: true,
    ),
    _RideVehicleOption(
      icon: Icons.airport_shuttle_rounded,
      name: 'Green Premium',
      description: '4 khach',
      arrivalMinutes: 4,
    ),
  ];
  int _selectedVehicleIndex = 1;
  int _selectedVoucherIndex = 0;
  bool _isBooking = false;
  String? _lastButtonBeforeCompletion;

  @override
  void initState() {
    super.initState();
    _screenStopwatch.start();
  }

  Map<String, dynamic> _buildCompletionInteraction({
    required String buttonLabel,
  }) {
    final duration = _screenStopwatch.elapsed;
    return {
      'screen': 'booking_confirmation_screen',
      'completionButton': buttonLabel,
      'lastButtonBeforeCompletion': _lastButtonBeforeCompletion,
      'screenDurationMs': duration.inMilliseconds,
      'screenDurationSeconds': duration.inSeconds,
      'buttonClickedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _showVoucherPicker() async {
    _lastButtonBeforeCompletion = 'Mo chon voucher';
    final selectedIndex = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            const Text(
              'Chon voucher',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            for (var index = 0; index < _vouchers.length; index++)
              _RideVoucherTile(
                voucher: _vouchers[index],
                selected: _selectedVoucherIndex == index,
                onTap: () => Navigator.pop(sheetContext, index),
              ),
          ],
        ),
      ),
    );

    if (selectedIndex != null && mounted) {
      _lastButtonBeforeCompletion = 'Chon voucher: '
          '${_vouchers[selectedIndex].code}';
      setState(() => _selectedVoucherIndex = selectedIndex);
    }
  }

  Future<void> _confirmBooking(
    RideBookingDetails? details, {
    required Map<String, dynamic> completionInteraction,
  }) async {
    setState(() => _isBooking = true);
    final voucher = _vouchers[_selectedVoucherIndex];
    final vehicle = _vehicles[_selectedVehicleIndex];
    var nextDetails = details?.copyWith(
      vehicleName: vehicle.name,
      voucherCode: voucher.discountAmount == 0 ? null : voucher.code,
      discountAmount: voucher.discountAmount.toDouble(),
      completionInteraction: completionInteraction,
    );

    try {
      if (FirebaseBootstrap.isReady && nextDetails != null) {
        final bookingId = await _databaseService.createBooking(
          details: nextDetails,
          userId: _authService.currentUser?.uid,
        );
        nextDetails = nextDetails.copyWith(bookingId: bookingId);
        await _analyticsService.logBookingStarted(nextDetails);
        await _eventTrackingService.trackBookingCreated(
          details: nextDetails,
          bookingId: bookingId,
          completionInteraction: completionInteraction,
        );
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        SearchingDriverScreen.routeName,
        arguments: nextDetails,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final details =
        ModalRoute.of(context)?.settings.arguments as RideBookingDetails?;
    final voucher = _vouchers[_selectedVoucherIndex];
    final vehicle = _vehicles[_selectedVehicleIndex];
    final selectedDetails = details?.copyWith(vehicleName: vehicle.name);
    final subtotal = selectedDetails?.estimatedPriceValue ?? 20000;
    final discount = voucher.discountAmount.toDouble();
    final discountedTotal = subtotal - discount;
    final total = discountedTotal < 0 ? 0.0 : discountedTotal;
    final routeSummary = details?.distanceMeters == null ||
            details?.durationSeconds == null
        ? 'Dang tinh lo trinh'
        : '${(details!.durationSeconds! / 60).ceil()} phut  •  '
            '${(details.distanceMeters! / 1000).toStringAsFixed(1)} km';

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            bottom: MediaQuery.sizeOf(context).height * 0.52,
            child: RideMap(
              pickupPosition: details?.pickupPosition,
              destinationPosition: details?.destinationPosition,
              trackCurrentLocation: details == null,
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 16,
            child: Material(
              color: Colors.white,
              elevation: 3,
              borderRadius: BorderRadius.circular(12),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Quay lai',
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 82,
            left: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFE1FAFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  routeSummary,
                  style: const TextStyle(
                    color: Color(0xFF007D86),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.66,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 24,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    MediaQuery.paddingOf(context).bottom + 20,
                  ),
                  children: [
                    Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCE7E7),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Chon dich vu',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    for (var index = 0; index < _vehicles.length; index++)
                      _RideVehicleTile(
                        vehicle: _vehicles[index],
                        price: (details?.copyWith(
                                  vehicleName: _vehicles[index].name,
                                ).estimatedPriceValue ??
                            20000),
                        selected: _selectedVehicleIndex == index,
                        onTap: () {
                          _lastButtonBeforeCompletion =
                              'Chon xe: ${_vehicles[index].name}';
                          setState(() => _selectedVehicleIndex = index);
                        },
                      ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: Icon(
                        Icons.local_offer_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        voucher.code,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        voucher.discountAmount == 0
                            ? 'Chon ma giam gia'
                            : 'Giam ${_formatRidePrice(discount)}',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _showVoucherPicker,
                    ),
                    const Divider(height: 1),
                    const ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 4),
                      leading: Icon(Icons.payments_outlined),
                      title: Text(
                        'Tien mat',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text('Phuong thuc thanh toan'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tong tien',
                                style: TextStyle(color: Colors.black54),
                              ),
                              Text(
                                _formatRidePrice(total),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: _isBooking
                                ? null
                                : () => _confirmBooking(
                                      details,
                                      completionInteraction:
                                          _buildCompletionInteraction(
                                        buttonLabel: 'Dat xe',
                                      ),
                                    ),
                            child: _isBooking
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text('Dat xe'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RideVehicleTile extends StatelessWidget {
  const _RideVehicleTile({
    required this.vehicle,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final _RideVehicleOption vehicle;
  final double price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? const Color(0xFFF0FCFC) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? primary : const Color(0xFFE5ECEC),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFF7F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(vehicle.icon, color: primary, size: 34),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicle.name} - ${vehicle.description}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Don trong ${vehicle.arrivalMinutes} phut',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      if (vehicle.recommended) ...[
                        const SizedBox(height: 5),
                        Text(
                          'Du kien den noi som hon',
                          style: TextStyle(
                            color: primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatRidePrice(price),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RideVoucherTile extends StatelessWidget {
  const _RideVoucherTile({
    required this.voucher,
    required this.selected,
    required this.onTap,
  });

  final _RideVoucherOption voucher;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_offer_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    voucher.code,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  voucher.discountAmount == 0
                      ? '0d'
                      : '-${_formatRidePrice(voucher.discountAmount.toDouble())}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
      fontSize: strong ? 18 : 14,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}

class _RideVoucherOption {
  const _RideVoucherOption({
    required this.code,
    required this.discountAmount,
  });

  final String code;
  final int discountAmount;
}

class _RideVehicleOption {
  const _RideVehicleOption({
    required this.icon,
    required this.name,
    required this.description,
    required this.arrivalMinutes,
    this.recommended = false,
  });

  final IconData icon;
  final String name;
  final String description;
  final int arrivalMinutes;
  final bool recommended;
}

String _formatRidePrice(double value) {
  final text = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final reverseIndex = text.length - i;
    buffer.write(text[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }
  return '${buffer}d';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.white,
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title),
      subtitle: Text(
        value,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
