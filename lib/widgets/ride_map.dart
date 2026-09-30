import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../config/map_config.dart';
import '../services/route_service.dart';

class RideMap extends StatefulWidget {
  const RideMap({
    super.key,
    this.pickupPosition,
    this.destinationPosition,
    this.height,
    this.showRoute = true,
    this.followCurrentLocation = true,
    this.trackCurrentLocation = true,
    this.locationButtonBottom = 42,
    this.onCurrentLocationChanged,
  });

  final LatLng? pickupPosition;
  final LatLng? destinationPosition;
  final double? height;
  final bool showRoute;
  final bool followCurrentLocation;
  final bool trackCurrentLocation;
  final double locationButtonBottom;
  final ValueChanged<LatLng>? onCurrentLocationChanged;

  @override
  State<RideMap> createState() => _RideMapState();
}

class _RideMapState extends State<RideMap> {
  static const _fallbackPosition = LatLng(10.7769, 106.7009);
  static const _destinationPosition = LatLng(10.7952, 106.7218);

  final MapController _controller = MapController();
  final RouteService _routeService = const RouteService();
  LatLng _currentPosition = _fallbackPosition;
  List<LatLng> _routePoints = const [];
  RouteResult? _routeResult;
  bool _hasLocationPermission = false;
  String? _locationMessage;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.pickupPosition ?? _fallbackPosition;
    if (widget.trackCurrentLocation) {
      _loadCurrentLocation();
    }
    if (widget.showRoute) {
      _loadRoute();
    }
  }

  @override
  void didUpdateWidget(covariant RideMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextPickup = widget.pickupPosition;
    if (nextPickup != null && nextPickup != oldWidget.pickupPosition) {
      setState(() => _currentPosition = nextPickup);
      if (widget.followCurrentLocation) {
        _controller.move(nextPickup, 15);
      }
      _loadRoute();
    } else if (widget.destinationPosition != oldWidget.destinationPosition) {
      _loadRoute();
    }
  }

  Future<void> _loadCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      setState(() => _locationMessage = 'GPS dang tat');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (!mounted) return;

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _hasLocationPermission = false;
        _locationMessage = 'Chua cap quyen vi tri';
      });
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;

      final nextPosition = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = nextPosition;
        _hasLocationPermission = true;
        _locationMessage = null;
      });
      widget.onCurrentLocationChanged?.call(nextPosition);
      await _loadRoute();

      if (widget.followCurrentLocation) {
        _controller.move(nextPosition, 15);
      }
    } catch (_) {
      setState(() {
        _hasLocationPermission = false;
        _locationMessage = 'Khong lay duoc vi tri hien tai';
      });
    }
  }

  Future<void> _loadRoute() async {
    if (!widget.showRoute) return;

    final destination = widget.destinationPosition ?? _destinationPosition;
    if (!_routeService.isConfigured) {
      if (!mounted) return;
      setState(() {
        _routePoints = [_currentPosition, destination];
        _routeResult = null;
      });
      return;
    }

    try {
      final result = await _routeService
          .getDrivingRoute(
            start: _currentPosition,
            destination: destination,
          )
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        _routePoints = result.points;
        _routeResult = result;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _routePoints = [_currentPosition, destination];
        _routeResult = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final map = Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: _currentPosition,
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: openStreetMapTileUrl,
              userAgentPackageName: mapUserAgentPackageName,
              maxNativeZoom: 19,
            ),
            if (widget.showRoute && _routePoints.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 5,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentPosition,
                  width: 46,
                  height: 46,
                  child: const _MapMarker(
                    icon: Icons.my_location_rounded,
                    label: 'Diem don',
                    color: Color(0xFF00B8C4),
                  ),
                ),
                if (widget.showRoute)
                  Marker(
                    point: widget.destinationPosition ?? _destinationPosition,
                    width: 46,
                    height: 46,
                    child: const _MapMarker(
                      icon: Icons.location_on_rounded,
                      label: 'Diem den',
                      color: Color(0xFFE84C4F),
                    ),
                  ),
              ],
            ),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        if (_hasLocationPermission)
          Positioned(
            right: 12,
            bottom: widget.locationButtonBottom,
            child: Material(
              color: Colors.white,
              elevation: 3,
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: _loadCurrentLocation,
                icon: const Icon(Icons.my_location_rounded),
                tooltip: 'Vi tri cua toi',
              ),
            ),
          ),
        if (_routeResult != null)
          Positioned(
            top: 12,
            left: 12,
            child: _RouteSummary(result: _routeResult!),
          ),
        if (_locationMessage != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_off_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_locationMessage!)),
                    TextButton(
                      onPressed: _loadCurrentLocation,
                      child: const Text('Thu lai'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );

    if (widget.height == null) return map;

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: map,
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 8),
          ],
        ),
        child: Icon(icon, color: color, size: 25),
      ),
    );
  }
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({required this.result});

  final RouteResult result;

  @override
  Widget build(BuildContext context) {
    final kilometers = result.distanceMeters / 1000;
    final minutes = (result.durationSeconds / 60).ceil();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Color(0x26000000), blurRadius: 10),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          '${kilometers.toStringAsFixed(1)} km - $minutes phut',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
