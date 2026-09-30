import 'package:firebase_analytics/firebase_analytics.dart';

import '../../models/ride_booking_details.dart';

class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logLogin(String method) {
    return _analytics.logLogin(loginMethod: method);
  }

  Future<void> logBookingStarted(RideBookingDetails details) {
    return _analytics.logEvent(
      name: 'booking_started',
      parameters: {
        'vehicle_name': details.vehicleName,
        'destination': details.destinationAddress,
      },
    );
  }

  Future<void> logTripCompleted({
    required String bookingId,
    required int rating,
  }) {
    return _analytics.logEvent(
      name: 'trip_completed',
      parameters: {
        'booking_id': bookingId,
        'rating': rating,
      },
    );
  }
}
