import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/firestore_models.dart';
import '../../models/ride_booking_details.dart';

class DatabaseService {
  DatabaseService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get bookings =>
      _firestore.collection('bookings');

  CollectionReference<Map<String, dynamic>> get drivers =>
      _firestore.collection('drivers');

  CollectionReference<Map<String, dynamic>> get trips =>
      _firestore.collection('trips');

  CollectionReference<Map<String, dynamic>> get foodOrders =>
      _firestore.collection('food_orders');

  CollectionReference<Map<String, dynamic>> get eventLogs =>
      _firestore.collection('event_logs');

  Future<void> upsertUser({
    required String userId,
    required Map<String, dynamic> data,
  }) {
    return users.doc(userId).set({
      'createdAt': FieldValue.serverTimestamp(),
      'rating': 5,
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> createUser(AppUser user) {
    return users.doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> createDriver(DriverProfile driver) {
    return drivers.doc(driver.id).set(driver.toMap(), SetOptions(merge: true));
  }

  Future<void> createBookingRecord(BookingRecord booking) {
    return bookings
        .doc(booking.id)
        .set(booking.toMap(), SetOptions(merge: true));
  }

  Future<void> createTripRecord(TripRecord trip) {
    return trips.doc(trip.id).set(trip.toMap(), SetOptions(merge: true));
  }

  Future<void> logEvent(AppEventLog event) {
    return eventLogs.add(event.toMap());
  }

  Future<String> createBooking({
    required RideBookingDetails details,
    String? userId,
  }) async {
    final document = bookings.doc();
    await document.set({
      'bookingId': document.id,
      ...details.toBookingMap(userId: userId),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return document.id;
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
  }) {
    return bookings.doc(bookingId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchBooking(String bookingId) {
    return bookings.doc(bookingId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUserBookings(String userId) {
    return bookings
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAvailableDrivers() {
    return drivers.where('status', isEqualTo: 'available').snapshots();
  }

  Future<String> createTrip({
    required String bookingId,
    required String driverId,
    required String userId,
  }) async {
    final document = await trips.add({
      'bookingId': bookingId,
      'driverId': driverId,
      'userId': userId,
      'status': 'active',
      'startedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return document.id;
  }

  Future<void> finishTrip({
    required String tripId,
    required int rating,
    String? feedback,
  }) {
    return trips.doc(tripId).update({
      'status': 'completed',
      'rating': rating,
      'feedback': feedback,
      'finishedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> createFoodOrder({
    required Map<String, dynamic> data,
    String? userId,
  }) async {
    final document = foodOrders.doc();
    await document.set({
      'orderId': document.id,
      'userId': userId,
      ...data,
      'status': 'requested',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return document.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUserFoodOrders(
    String userId,
  ) {
    return foodOrders
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
