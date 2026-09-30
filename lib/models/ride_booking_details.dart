import 'package:latlong2/latlong.dart';

import 'firestore_models.dart';

class RideBookingDetails {
  const RideBookingDetails({
    required this.pickupAddress,
    this.pickupPosition = const LatLng(10.7769, 106.7009),
    required this.destinationAddress,
    required this.destinationPosition,
    this.vehicleName = 'Xanh SM Car',
    this.vehiclePrice = '20.000d',
    this.voucherCode,
    this.discountAmount = 0,
    this.bookingId,
    this.distanceMeters,
    this.durationSeconds,
    this.pickupNote = '',
    this.completionInteraction,
  });

  final String pickupAddress;
  final LatLng pickupPosition;
  final String destinationAddress;
  final LatLng destinationPosition;
  final String vehicleName;
  final String vehiclePrice;
  final String? voucherCode;
  final double discountAmount;
  final String? bookingId;
  final double? distanceMeters;
  final double? durationSeconds;
  final String pickupNote;
  final Map<String, dynamic>? completionInteraction;

  RideBookingDetails copyWith({
    String? pickupAddress,
    LatLng? pickupPosition,
    String? destinationAddress,
    LatLng? destinationPosition,
    String? vehicleName,
    String? vehiclePrice,
    String? voucherCode,
    double? discountAmount,
    String? bookingId,
    double? distanceMeters,
    double? durationSeconds,
    String? pickupNote,
    Map<String, dynamic>? completionInteraction,
  }) {
    return RideBookingDetails(
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupPosition: pickupPosition ?? this.pickupPosition,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      destinationPosition: destinationPosition ?? this.destinationPosition,
      vehicleName: vehicleName ?? this.vehicleName,
      vehiclePrice: vehiclePrice ?? this.vehiclePrice,
      voucherCode: voucherCode ?? this.voucherCode,
      discountAmount: discountAmount ?? this.discountAmount,
      bookingId: bookingId ?? this.bookingId,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      pickupNote: pickupNote ?? this.pickupNote,
      completionInteraction:
          completionInteraction ?? this.completionInteraction,
    );
  }

  Map<String, dynamic> toBookingMap({String? userId}) {
    final pickup = RideLocation(
      address: pickupAddress,
      latitude: pickupPosition.latitude,
      longitude: pickupPosition.longitude,
    );
    final destination = RideLocation.fromLatLng(
      address: destinationAddress,
      position: destinationPosition,
    );

    return {
      'userId': userId,
      'driverId': null,
      'vehicleType': vehicleName,
      'pickup': pickup.toMap(),
      'destination': destination.toMap(),
      'distance': distanceMeters == null ? null : distanceMeters! / 1000,
      'estimatedDuration':
          durationSeconds == null ? null : (durationSeconds! / 60).ceil(),
      'pickupNote': pickupNote,
      'estimatedPrice': estimatedPriceValue,
      'voucherCode': voucherCode,
      'discountAmount': discountAmount,
      'finalPrice': finalPriceValue,
      'completionInteraction': completionInteraction,
      'status': 'requested',
    };
  }

  double get estimatedPriceValue {
    final normalizedVehicleName = vehicleName.toLowerCase();
    final isBike = normalizedVehicleName.contains('bike') ||
        normalizedVehicleName.contains('xe may');
    final isPremium = normalizedVehicleName.contains('premium');
    final basePrice = isBike
        ? 10000.0
        : isPremium
            ? 30000.0
            : 20000.0;
    final pricePerKm = isBike
        ? 3000.0
        : isPremium
            ? 6500.0
            : 5000.0;
    final distanceKm = (distanceMeters ?? 0) / 1000;

    return basePrice + (distanceKm * pricePerKm);
  }

  double get finalPriceValue {
    final total = estimatedPriceValue - discountAmount;
    return total < 0 ? 0 : total;
  }
}
