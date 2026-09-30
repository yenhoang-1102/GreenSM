import '../../models/firestore_models.dart';
import 'database_service.dart';

class FirestoreSeedService {
  FirestoreSeedService({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService();

  final DatabaseService _databaseService;

  Future<void> seedInitialData() async {
    final user = AppUser(
      id: 'user_001',
      name: 'Nguyen Thi Hoang Yen',
      phone: '0900000001',
      email: 'yen@example.com',
      rating: 5,
    );

    final driver = DriverProfile(
      id: 'driver_001',
      name: 'Nguyen Minh Khoa',
      phone: '0900000002',
      vehicleType: 'Xanh SM Car',
      vehicleNumber: '51G 123.45',
      latitude: 10.7769,
      longitude: 106.7009,
      status: 'available',
      rating: 4.9,
    );

    final pickup = RideLocation(
      address: 'Vi tri hien tai',
      latitude: 10.7769,
      longitude: 106.7009,
    );

    final destination = RideLocation(
      address: 'Landmark 81, Binh Thanh, TP. Ho Chi Minh',
      latitude: 10.7952,
      longitude: 106.7218,
    );

    final booking = BookingRecord(
      id: 'booking_001',
      userId: user.id,
      driverId: driver.id,
      vehicleType: driver.vehicleType,
      pickup: pickup,
      destination: destination,
      distance: 5.8,
      estimatedPrice: 82000,
      finalPrice: 82000,
      status: 'accepted',
    );

    final trip = TripRecord(
      id: 'trip_001',
      bookingId: booking.id,
      distance: booking.distance,
      duration: 18,
      price: booking.finalPrice,
    );

    await _databaseService.createUser(user);
    await _databaseService.createDriver(driver);
    await _databaseService.createBookingRecord(booking);
    await _databaseService.createTripRecord(trip);
    await _databaseService.logEvent(
      AppEventLog(
        eventName: 'seed_data_created',
        userId: user.id,
        bookingId: booking.id,
        timeStep: 1,
        location: pickup,
        device: 'development',
        screen: 'firestore_seed',
        metadata: {
          'driverId': driver.id,
          'tripId': trip.id,
        },
      ),
    );
  }
}
