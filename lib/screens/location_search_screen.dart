import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/ride_booking_details.dart';
import '../services/geocoding_service.dart';
import '../services/route_service.dart';
import '../widgets/ride_map.dart';
import 'pickup_confirmation_screen.dart';

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  static const routeName = '/location-search';

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final _pickupController = TextEditingController(text: 'Vi tri hien tai');
  final _destinationController = TextEditingController();
  final _geocodingService = GeocodingService();
  final _routeService = const RouteService();
  LatLng? _pickupPosition;
  PlaceSearchResult? _selectedDestination;
  List<PlaceSearchResult> _liveSuggestions = const [];
  Timer? _searchDebounce;
  int _suggestionRequestId = 0;
  bool _hasResolvedPickupAddress = false;
  bool _isSearching = false;
  bool _isLoadingSuggestions = false;

  final _popularPlaces = const [
    'San bay Tan Son Nhat',
    'Ben Thanh Market',
    'Landmark 81',
    'Nha tho Duc Ba',
    'Pho di bo Nguyen Hue',
  ];

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_destinationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui long chon diem den')));
      return;
    }

    setState(() => _isSearching = true);
    try {
      final result = _selectedDestination ??
          await _geocodingService.searchAddress(
            _destinationController.text,
          );
      final pickup = _pickupPosition ?? const LatLng(10.7769, 106.7009);
      RouteResult? route;
      if (_routeService.isConfigured) {
        try {
          route = await _routeService
              .getDrivingRoute(
                start: pickup,
                destination: result.position,
              )
              .timeout(const Duration(seconds: 15));
        } catch (_) {
          route = null;
        }
      }

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        PickupConfirmationScreen.routeName,
        arguments: RideBookingDetails(
          pickupAddress: _pickupController.text,
          pickupPosition: pickup,
          destinationAddress: result.address,
          destinationPosition: result.position,
          distanceMeters: route?.distanceMeters,
          durationSeconds: route?.durationSeconds,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_cleanErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  String _cleanErrorMessage(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('FormatException: ', '');
  }

  Future<void> _handleCurrentLocationChanged(LatLng position) async {
    setState(() => _pickupPosition = position);
    if (_hasResolvedPickupAddress) return;

    _hasResolvedPickupAddress = true;
    try {
      final result = await _geocodingService
          .reverseGeocode(position)
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _pickupPosition = result.position;
        _pickupController.text = result.address;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pickupController.text = 'Vi tri hien tai ${_formatPosition(position)}';
      });
    }
  }

  String _formatPosition(LatLng position) {
    return '(${position.latitude.toStringAsFixed(5)}, '
        '${position.longitude.toStringAsFixed(5)})';
  }

  void _onDestinationChanged(String value) {
    _searchDebounce?.cancel();
    _selectedDestination = null;
    final query = value.trim();
    final requestId = ++_suggestionRequestId;

    if (query.length < 2) {
      setState(() {
        _liveSuggestions = const [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    setState(() => _isLoadingSuggestions = true);
    _searchDebounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        final results = await _geocodingService
            .autocompleteAddress(query)
            .timeout(const Duration(seconds: 10));
        if (!mounted || requestId != _suggestionRequestId) return;
        setState(() {
          _liveSuggestions = results;
          _isLoadingSuggestions = false;
        });
      } catch (_) {
        if (!mounted || requestId != _suggestionRequestId) return;
        setState(() {
          _liveSuggestions = const [];
          _isLoadingSuggestions = false;
        });
      }
    });
  }

  void _selectSuggestion(PlaceSearchResult result) {
    _searchDebounce?.cancel();
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedDestination = result;
      _destinationController.text = result.address;
      _liveSuggestions = const [];
      _isLoadingSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chon lo trinh')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  RideMap(
                    height: 220,
                    showRoute: false,
                    onCurrentLocationChanged: _handleCurrentLocationChanged,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pickupController,
                    decoration: const InputDecoration(
                      labelText: 'Diem don',
                      prefixIcon: Icon(Icons.my_location_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _destinationController,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onChanged: _onDestinationChanged,
                    onSubmitted: (_) => _continue(),
                    decoration: InputDecoration(
                      labelText: 'Diem den',
                      prefixIcon: const Icon(Icons.location_on_rounded),
                      suffixIcon: _destinationController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _destinationController.clear();
                                _onDestinationChanged('');
                              },
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'Xoa diem den',
                            ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoadingSuggestions)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: _liveSuggestions.isNotEmpty
                  ? ListView.separated(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: _liveSuggestions.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final result = _liveSuggestions[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined),
                          title: Text(
                            result.address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: const Text('Goi y dia diem'),
                          onTap: () => _selectSuggestion(result),
                        );
                      },
                    )
                  : _destinationController.text.trim().length >= 2
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _routeService.isConfigured
                                  ? 'Khong tim thay goi y phu hop'
                                  : 'Hay them OPENROUTESERVICE_API_KEY vao file .env de xem goi y khi nhap',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ),
                        )
                      : ListView.separated(
                      itemCount: _popularPlaces.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final place = _popularPlaces[index];
                        return ListTile(
                          leading: const Icon(Icons.place_outlined),
                          title: Text(place),
                          subtitle: const Text('Dia diem pho bien'),
                          onTap: () {
                            _destinationController.text = place;
                            _selectedDestination = null;
                            _continue();
                          },
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: FilledButton(
                onPressed: _isSearching ? null : _continue,
                child: _isSearching
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Tim tren ban do'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
