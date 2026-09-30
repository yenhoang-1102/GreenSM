import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.rating = 5,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final double rating;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'rating': rating,
    };
  }
}

class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.latitude,
    required this.longitude,
    this.status = 'available',
    this.rating = 5,
  });

  final String id;
  final String name;
  final String phone;
  final String vehicleType;
  final String vehicleNumber;
  final double latitude;
  final double longitude;
  final String status;
  final double rating;

  LatLng get position => LatLng(latitude, longitude);

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'rating': rating,
    };
  }
}

class RideLocation {
  const RideLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String address;
  final double latitude;
  final double longitude;

  factory RideLocation.fromLatLng({
    required String address,
    required LatLng position,
  }) {
    return RideLocation(
      address: address,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class BookingRecord {
  const BookingRecord({
    required this.id,
    required this.userId,
    required this.driverId,
    required this.vehicleType,
    required this.pickup,
    required this.destination,
    required this.distance,
    required this.estimatedPrice,
    required this.finalPrice,
    this.status = 'requested',
  });

  final String id;
  final String userId;
  final String driverId;
  final String vehicleType;
  final RideLocation pickup;
  final RideLocation destination;
  final double distance;
  final double estimatedPrice;
  final double finalPrice;
  final String status;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'driverId': driverId,
      'vehicleType': vehicleType,
      'pickup': pickup.toMap(),
      'destination': destination.toMap(),
      'distance': distance,
      'estimatedPrice': estimatedPrice,
      'finalPrice': finalPrice,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class TripRecord {
  const TripRecord({
    required this.id,
    required this.bookingId,
    required this.distance,
    required this.duration,
    required this.price,
  });

  final String id;
  final String bookingId;
  final double distance;
  final int duration;
  final double price;

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'startedAt': FieldValue.serverTimestamp(),
      'completedAt': null,
      'distance': distance,
      'duration': duration,
      'price': price,
    };
  }
}

class AppEventLog {
  const AppEventLog({
    required this.eventName,
    required this.screen,
    required this.device,
    required this.timeStep,
    this.userId,
    this.bookingId,
    this.location,
    this.metadata = const {},
  });

  final String eventName;
  final String screen;
  final String device;
  final int timeStep;
  final String? userId;
  final String? bookingId;
  final RideLocation? location;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() {
    return {
      'eventName': eventName,
      'userId': userId,
      'bookingId': bookingId,
      'time_step': timeStep,
      'location': location?.toMap(),
      'device': device,
      'screen': screen,
      'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
