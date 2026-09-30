import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/ride_booking_details.dart';
import '../services/firebase/firebase_bootstrap.dart';
import 'food_order_screen.dart';
import 'pickup_confirmation_screen.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  static const routeName = '/activity-history';

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  final _searchController = TextEditingController();
  _HistoryType _selectedType = _HistoryType.ride;
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hoat dong',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showSearch = !_showSearch),
            icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded),
            tooltip: _showSearch ? 'Dong tim kiem' : 'Tim kiem',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_showSearch)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Tim dia diem, nha hang hoac dich vu',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
            SizedBox(
              height: 66,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                  _FilterChip(
                    label: 'Di chuyen',
                    selected: _selectedType == _HistoryType.ride,
                    onTap: () => setState(() => _selectedType = _HistoryType.ride),
                  ),
                  const SizedBox(width: 10),
                  _FilterChip(
                    label: 'Do an',
                    selected: _selectedType == _HistoryType.food,
                    onTap: () => setState(() => _selectedType = _HistoryType.food),
                  ),
                ],
              ),
            ),
            Expanded(
              child: !FirebaseBootstrap.isReady || user == null
                  ? const _EmptyHistory(
                      message: 'Dang nhap de xem lich su hoat dong',
                    )
                  : _HistoryList(
                      userId: user.uid,
                      type: _selectedType,
                      searchText: _searchController.text,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _HistoryType { ride, food }

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.userId,
    required this.type,
    required this.searchText,
  });

  final String userId;
  final _HistoryType type;
  final String searchText;

  @override
  Widget build(BuildContext context) {
    final collection = type == _HistoryType.ride ? 'bookings' : 'food_orders';
    final stream = FirebaseFirestore.instance
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _EmptyHistory(
            message: 'Khong tai duoc lich su. Vui long thu lai.',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final query = searchText.trim().toLowerCase();
        final entries = snapshot.data!.docs
            .map((doc) => _HistoryEntry.fromDocument(doc, type))
            .where((entry) => query.isEmpty || entry.searchText.contains(query))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (entries.isEmpty) {
          return _EmptyHistory(
            message: query.isEmpty
                ? 'Chua co hoat dong nao'
                : 'Khong tim thay hoat dong phu hop',
          );
        }

        final grouped = <String, List<_HistoryEntry>>{};
        for (final entry in entries) {
          grouped.putIfAbsent(_dateKey(entry.createdAt), () => []).add(entry);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            for (final group in grouped.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 10),
                child: Text(
                  _formatDate(group.value.first.createdAt),
                  style: const TextStyle(color: Colors.black54, fontSize: 15),
                ),
              ),
              for (final entry in group.value)
                _HistoryCard(entry: entry),
            ],
          ],
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  final _HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final statusColor = entry.status == 'completed'
        ? const Color(0xFF008E98)
        : entry.status == 'cancelled'
            ? Colors.black87
            : const Color(0xFFB26A00);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${entry.title} - ${_formatTime(entry.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _LocationLine(icon: Icons.trip_origin_rounded, text: entry.origin),
          const SizedBox(height: 8),
          _LocationLine(icon: Icons.stop_rounded, text: entry.destination),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatPrice(entry.price),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              OutlinedButton(
                onPressed: () => entry.reorder(context),
                child: const Text('Dat lai'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationLine extends StatelessWidget {
  const _LocationLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF899394)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: const Color(0xFF303536),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded, size: 56, color: Colors.black26),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _HistoryEntry {
  const _HistoryEntry({
    required this.type,
    required this.title,
    required this.origin,
    required this.destination,
    required this.price,
    required this.status,
    required this.createdAt,
    required this.data,
  });

  factory _HistoryEntry.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    _HistoryType type,
  ) {
    final data = document.data();
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
    if (type == _HistoryType.ride) {
      final pickup = _map(data['pickup']);
      final destination = _map(data['destination']);
      return _HistoryEntry(
        type: type,
        title: data['vehicleType']?.toString() ?? 'Chuyen xe',
        origin: pickup['address']?.toString() ?? 'Diem don',
        destination: destination['address']?.toString() ?? 'Diem den',
        price: _number(data['finalPrice']),
        status: data['status']?.toString() ?? 'requested',
        createdAt: createdAt,
        data: data,
      );
    }

    return _HistoryEntry(
      type: type,
      title: data['restaurant']?.toString() ?? 'Don Food',
      origin: data['restaurant']?.toString() ?? 'Nha hang',
      destination: data['deliveryAddress']?.toString() ?? 'Dia chi giao hang',
      price: _number(data['totalPrice']),
      status: data['status']?.toString() ?? 'requested',
      createdAt: createdAt,
      data: data,
    );
  }

  final _HistoryType type;
  final String title;
  final String origin;
  final String destination;
  final double price;
  final String status;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  String get searchText => '$title $origin $destination'.toLowerCase();

  String get statusLabel {
    switch (status) {
      case 'completed':
        return 'Hoan thanh';
      case 'cancelled':
        return 'Da huy';
      case 'active':
        return 'Dang di';
      default:
        return 'Da dat';
    }
  }

  void reorder(BuildContext context) {
    if (type == _HistoryType.food) {
      Navigator.pushNamed(context, FoodOrderScreen.routeName);
      return;
    }

    final pickup = _map(data['pickup']);
    final destinationData = _map(data['destination']);
    Navigator.pushNamed(
      context,
      PickupConfirmationScreen.routeName,
      arguments: RideBookingDetails(
        pickupAddress: origin,
        pickupPosition: LatLng(
          _number(pickup['latitude']),
          _number(pickup['longitude']),
        ),
        destinationAddress: destination,
        destinationPosition: LatLng(
          _number(destinationData['latitude']),
          _number(destinationData['longitude']),
        ),
        vehicleName: title,
        distanceMeters: _numberOrNull(data['distance']) == null
            ? null
            : _number(data['distance']) * 1000,
        durationSeconds: _numberOrNull(data['estimatedDuration']) == null
            ? null
            : _number(data['estimatedDuration']) * 60,
      ),
    );
  }
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

double _number(dynamic value) => value is num ? value.toDouble() : 0;
double? _numberOrNull(dynamic value) => value is num ? value.toDouble() : null;

String _dateKey(DateTime value) => '${value.year}-${value.month}-${value.day}';
String _formatDate(DateTime value) => '${value.day} thg ${value.month} ${value.year}';
String _formatTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _formatPrice(double value) {
  final digits = value.round().toString();
  final formatted = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return '${formatted}d';
}
