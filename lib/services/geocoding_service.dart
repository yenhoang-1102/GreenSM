import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/map_config.dart';

class PlaceSearchResult {
  const PlaceSearchResult({
    required this.address,
    required this.position,
  });

  final String address;
  final LatLng position;
}

class GeocodingService {
  DateTime? _lastRequestAt;

  Future<List<PlaceSearchResult>> autocompleteAddress(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 2 || openRouteServiceApiKey.isEmpty) {
      return const [];
    }

    final uri = Uri.https(
      'api.openrouteservice.org',
      '/geocode/autocomplete',
      {
        'text': trimmedQuery,
        'boundary.country': 'VN',
        'size': '6',
        'lang': 'vi',
      },
    );
    final response = await http.get(
      uri,
      headers: {
        'Authorization': openRouteServiceApiKey,
        'Accept': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Khong tai duoc goi y dia diem');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final features = body['features'] as List<dynamic>? ?? [];
    return features.map((feature) {
      final item = feature as Map<String, dynamic>;
      final properties = item['properties'] as Map<String, dynamic>? ?? {};
      final geometry = item['geometry'] as Map<String, dynamic>? ?? {};
      final coordinates = geometry['coordinates'] as List<dynamic>? ?? [];
      if (coordinates.length < 2) return null;

      return PlaceSearchResult(
        address: properties['label']?.toString() ?? trimmedQuery,
        position: LatLng(
          (coordinates[1] as num).toDouble(),
          (coordinates[0] as num).toDouble(),
        ),
      );
    }).whereType<PlaceSearchResult>().toList(growable: false);
  }

  Future<PlaceSearchResult> reverseGeocode(LatLng position) async {
    await _respectPublicApiLimit();
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      {
        'format': 'jsonv2',
        'lat': position.latitude.toString(),
        'lon': position.longitude.toString(),
        'accept-language': 'vi',
        'addressdetails': '1',
      },
    );

    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Khong ket noi duoc Nominatim');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final address = body['display_name']?.toString().trim() ?? '';
    if (address.isEmpty) {
      throw Exception('Khong lay duoc dia chi tu vi tri hien tai');
    }

    return PlaceSearchResult(
      address: address,
      position: position,
    );
  }

  Future<PlaceSearchResult> searchAddress(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      throw const FormatException('Vui long nhap dia chi can tim');
    }

    final lowerQuery = trimmedQuery.toLowerCase();
    final searchQuery = lowerQuery.contains('viet nam') ||
            lowerQuery.contains('vietnam') ||
            lowerQuery.endsWith(', vn')
        ? trimmedQuery
        : '$trimmedQuery, Viet Nam';

    await _respectPublicApiLimit();
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'format': 'jsonv2',
        'q': searchQuery,
        'countrycodes': 'vn',
        'accept-language': 'vi',
        'addressdetails': '1',
        'limit': '5',
      },
    );

    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Khong ket noi duoc Nominatim');
    }

    final results = jsonDecode(response.body) as List<dynamic>;
    if (results.isEmpty) {
      throw Exception('Khong tim thay dia chi phu hop: $trimmedQuery');
    }

    final firstResult = results.first as Map<String, dynamic>;
    final latitude = double.tryParse(firstResult['lat']?.toString() ?? '');
    final longitude = double.tryParse(firstResult['lon']?.toString() ?? '');
    if (latitude == null || longitude == null) {
      throw Exception('Dia chi tim thay khong co toa do hop le');
    }

    return PlaceSearchResult(
      address: firstResult['display_name']?.toString() ?? trimmedQuery,
      position: LatLng(latitude, longitude),
    );
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Accept-Language': 'vi',
        if (!kIsWeb) 'User-Agent': mapUserAgentPackageName,
      };

  Future<void> _respectPublicApiLimit() async {
    final previous = _lastRequestAt;
    if (previous != null) {
      final elapsed = DateTime.now().difference(previous);
      const minimumInterval = Duration(seconds: 1);
      if (elapsed < minimumInterval) {
        await Future<void>.delayed(minimumInterval - elapsed);
      }
    }
    _lastRequestAt = DateTime.now();
  }
}
