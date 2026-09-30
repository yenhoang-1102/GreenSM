import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/map_config.dart';

class RouteResult {
  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
}

class RouteService {
  const RouteService();

  bool get isConfigured => openRouteServiceApiKey.trim().isNotEmpty;

  Future<RouteResult> getDrivingRoute({
    required LatLng start,
    required LatLng destination,
  }) async {
    if (!isConfigured) {
      throw const FormatException(
        'Chua cau hinh OPENROUTESERVICE_API_KEY',
      );
    }

    final response = await http.post(
      Uri.parse(
        'https://api.openrouteservice.org/v2/directions/driving-car/geojson',
      ),
      headers: {
        'Authorization': openRouteServiceApiKey,
        'Accept': 'application/json, application/geo+json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'coordinates': [
          [start.longitude, start.latitude],
          [destination.longitude, destination.latitude],
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'OpenRouteService loi ${response.statusCode}: ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final features = body['features'] as List<dynamic>? ?? [];
    if (features.isEmpty) {
      throw Exception('OpenRouteService khong tim thay tuyen duong');
    }

    final feature = features.first as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>? ?? {};
    final coordinates = geometry['coordinates'] as List<dynamic>? ?? [];
    final properties = feature['properties'] as Map<String, dynamic>? ?? {};
    final summary = properties['summary'] as Map<String, dynamic>? ?? {};
    final points = coordinates.map((coordinate) {
      final values = coordinate as List<dynamic>;
      return LatLng(
        (values[1] as num).toDouble(),
        (values[0] as num).toDouble(),
      );
    }).toList(growable: false);

    if (points.length < 2) {
      throw Exception('OpenRouteService tra ve tuyen duong khong hop le');
    }

    return RouteResult(
      points: points,
      distanceMeters: (summary['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: (summary['duration'] as num?)?.toDouble() ?? 0,
    );
  }
}
