import 'package:flutter/material.dart';

class FoodMenuItem {
  const FoodMenuItem({
    required this.id,
    required this.name,
    required this.restaurant,
    required this.category,
    required this.time,
    required this.distance,
    required this.rating,
    required this.price,
    required this.icon,
  });

  final String id;
  final String name;
  final String restaurant;
  final String category;
  final String time;
  final String distance;
  final double rating;
  final int price;
  final IconData icon;

  double get distanceKm {
    final match = RegExp(r'[0-9]+(?:[.,][0-9]+)?').firstMatch(distance);
    return double.tryParse(match?.group(0)?.replaceAll(',', '.') ?? '') ?? 0;
  }
}

class FoodCartItem {
  const FoodCartItem({
    required this.item,
    required this.quantity,
  });

  final FoodMenuItem item;
  final int quantity;

  int get totalPrice => item.price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': item.id,
      'name': item.name,
      'restaurant': item.restaurant,
      'category': item.category,
      'quantity': quantity,
      'unitPrice': item.price,
      'totalPrice': totalPrice,
    };
  }
}

class FoodOrderDetails {
  const FoodOrderDetails({
    required this.deliveryAddress,
    required this.items,
    this.voucherCode,
    this.discountAmount = 0,
    this.completionInteraction,
  });

  final String deliveryAddress;
  final List<FoodCartItem> items;
  final String? voucherCode;
  final int discountAmount;
  final Map<String, dynamic>? completionInteraction;

  int get subtotal {
    return items.fold(0, (total, item) => total + item.totalPrice);
  }

  double get deliveryDistanceKm {
    if (items.isEmpty) return 0;
    return items
        .map((cartItem) => cartItem.item.distanceKm)
        .reduce((current, next) => current > next ? current : next);
  }

  int get shippingFee => (10000 + deliveryDistanceKm * 5000).round();

  int get finalPrice {
    final total = subtotal + shippingFee - discountAmount;
    return total < 0 ? 0 : total;
  }

  String get restaurantSummary {
    final restaurants = {for (final cartItem in items) cartItem.item.restaurant};
    if (restaurants.length == 1) return restaurants.first;
    return '${restaurants.length} quan';
  }

  String get estimatedTime {
    if (items.isEmpty) return '15-20 phut';
    return items.first.item.time;
  }

  FoodOrderDetails copyWith({
    String? deliveryAddress,
    List<FoodCartItem>? items,
    String? voucherCode,
    int? discountAmount,
    Map<String, dynamic>? completionInteraction,
  }) {
    return FoodOrderDetails(
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      items: items ?? this.items,
      voucherCode: voucherCode ?? this.voucherCode,
      discountAmount: discountAmount ?? this.discountAmount,
      completionInteraction:
          completionInteraction ?? this.completionInteraction,
    );
  }
}

String formatVnd(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final reverseIndex = text.length - i;
    buffer.write(text[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }
  return '${buffer}d';
}
