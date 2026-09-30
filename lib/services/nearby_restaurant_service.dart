import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/map_config.dart';

class NearbyRestaurant {
  const NearbyRestaurant({
    required this.id,
    required this.name,
    required this.type,
    required this.position,
    required this.distanceKm,
    this.cuisine,
    this.openingHours,
    this.address,
  });

  final String id;
  final String name;
  final String type;
  final LatLng position;
  final double distanceKm;
  final String? cuisine;
  final String? openingHours;
  final String? address;
}

class NearbyRestaurantService {
  const NearbyRestaurantService();

  Future<List<NearbyRestaurant>> findNearby({
    required LatLng center,
    double radiusMeters = 3000,
  }) async {
    final query = '''
[out:json][timeout:25];
(
  nwr["amenity"="restaurant"](around:${radiusMeters.round()},${center.latitude},${center.longitude});
  nwr["amenity"="fast_food"](around:${radiusMeters.round()},${center.latitude},${center.longitude});
  nwr["amenity"="cafe"](around:${radiusMeters.round()},${center.latitude},${center.longitude});
  nwr["amenity"="food_court"](around:${radiusMeters.round()},${center.latitude},${center.longitude});
);
out center tags;
''';

    final response = await http
        .post(
          Uri.parse('https://overpass-api.de/api/interpreter'),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'Accept': 'application/json',
            if (!kIsWeb) 'User-Agent': mapUserAgentPackageName,
          },
          body: {'data': query},
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Khong tai duoc danh sach quan an gan ban');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = body['elements'] as List<dynamic>? ?? [];
    final distance = const Distance();
    final restaurants = <NearbyRestaurant>[];

    for (final rawElement in elements) {
      final element = rawElement as Map<String, dynamic>;
      final tags = element['tags'] as Map<String, dynamic>? ?? {};
      final name = tags['name']?.toString().trim() ?? '';
      if (name.isEmpty) continue;

      final centerData = element['center'] as Map<String, dynamic>?;
      final latitude = (element['lat'] as num?)?.toDouble() ??
          (centerData?['lat'] as num?)?.toDouble();
      final longitude = (element['lon'] as num?)?.toDouble() ??
          (centerData?['lon'] as num?)?.toDouble();
      if (latitude == null || longitude == null) continue;

      final position = LatLng(latitude, longitude);
      final distanceKm = distance.as(
        LengthUnit.Kilometer,
        center,
        position,
      );
      if (distanceKm > radiusMeters / 1000) continue;

      restaurants.add(
        NearbyRestaurant(
          id: '${element['type']}_${element['id']}',
          name: name,
          type: _typeLabel(tags['amenity']?.toString()),
          position: position,
          distanceKm: distanceKm,
          cuisine: _cleanTag(tags['cuisine']),
          openingHours: _cleanTag(tags['opening_hours']),
          address: _buildAddress(tags),
        ),
      );
    }

    restaurants.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return restaurants.take(30).toList(growable: false);
  }

  static String _typeLabel(String? amenity) {
    switch (amenity) {
      case 'fast_food':
        return 'Do an nhanh';
      case 'cafe':
        return 'Quan ca phe';
      case 'food_court':
        return 'Khu am thuc';
      default:
        return 'Nha hang';
    }
  }

  static String? _cleanTag(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text.replaceAll(';', ', ');
  }

  static String? _buildAddress(Map<String, dynamic> tags) {
    final parts = [
      tags['addr:housenumber']?.toString(),
      tags['addr:street']?.toString(),
      tags['addr:district']?.toString(),
      tags['addr:city']?.toString(),
    ].where((part) => part != null && part.trim().isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(', ');
  }
}
