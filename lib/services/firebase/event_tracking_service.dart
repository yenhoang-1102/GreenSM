import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/firestore_models.dart';
import '../../models/ride_booking_details.dart';
import 'database_service.dart';
import 'firebase_bootstrap.dart';

class EventTrackingService {
  EventTrackingService({
    FirebaseAuth? auth,
    DatabaseService? databaseService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _databaseService = databaseService ?? DatabaseService();

  final FirebaseAuth _auth;
  final DatabaseService _databaseService;

  Future<void> trackLogin({required String method}) {
    return _track(
      eventName: 'login_success',
      screen: 'login_screen',
      metadata: {'method': method},
    );
  }

  Future<void> trackBookingCreated({
    required RideBookingDetails details,
    required String bookingId,
    Map<String, dynamic>? completionInteraction,
  }) {
    return _track(
      eventName: 'booking_created',
      screen: 'booking_confirmation_screen',
      bookingId: bookingId,
      location: RideLocation(
        address: details.pickupAddress,
        latitude: details.pickupPosition.latitude,
        longitude: details.pickupPosition.longitude,
      ),
      metadata: {
        'service': 'ride',
        'vehicleName': details.vehicleName,
        'vehiclePrice': details.estimatedPriceValue,
        'voucherCode': details.voucherCode,
        'discountAmount': details.discountAmount,
        'finalPrice': details.finalPriceValue,
        'pickupAddress': details.pickupAddress,
        'destinationAddress': details.destinationAddress,
        'destinationLatitude': details.destinationPosition.latitude,
        'destinationLongitude': details.destinationPosition.longitude,
        if (completionInteraction != null)
          'completionInteraction': completionInteraction,
      },
    );
  }

  Future<void> trackFoodOrderCreated({
    required String orderId,
    required String restaurant,
    required String itemName,
    required String category,
    required int quantity,
    required int totalPrice,
    Map<String, dynamic>? completionInteraction,
  }) {
    return _track(
      eventName: 'food_order_created',
      screen: 'food_order_screen',
      bookingId: orderId,
      metadata: {
        'service': 'food',
        'orderId': orderId,
        'restaurant': restaurant,
        'itemName': itemName,
        'category': category,
        'quantity': quantity,
        'totalPrice': totalPrice,
        if (completionInteraction != null)
          'completionInteraction': completionInteraction,
      },
    );
  }

  Future<void> trackTripRated({
    required RideBookingDetails details,
    required int rating,
  }) {
    return _track(
      eventName: 'trip_rated',
      screen: 'rating_screen',
      bookingId: details.bookingId,
      metadata: {
        'service': 'ride',
        'rating': rating,
        'vehicleName': details.vehicleName,
        'destinationAddress': details.destinationAddress,
      },
    );
  }

  Future<void> _track({
    required String eventName,
    required String screen,
    String? bookingId,
    RideLocation? location,
    Map<String, dynamic> metadata = const {},
  }) async {
    if (!FirebaseBootstrap.isReady) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _databaseService
          .logEvent(
            AppEventLog(
              eventName: eventName,
              screen: screen,
              device: _deviceLabel,
              timeStep: DateTime.now().millisecondsSinceEpoch,
              userId: user.uid,
              bookingId: bookingId,
              location: location,
              metadata: metadata,
            ),
          )
          .timeout(const Duration(seconds: 8));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Khong ghi duoc event $eventName vao Firestore: $error');
      }
    }
  }

  String get _deviceLabel {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }
}
