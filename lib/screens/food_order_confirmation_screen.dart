import 'package:flutter/material.dart';

import '../models/food_order_details.dart';
import '../services/firebase/auth_service.dart';
import '../services/firebase/database_service.dart';
import '../services/firebase/event_tracking_service.dart';
import '../services/firebase/firebase_bootstrap.dart';

class FoodOrderConfirmationScreen extends StatefulWidget {
  const FoodOrderConfirmationScreen({super.key});

  static const routeName = '/food-order-confirmation';

  @override
  State<FoodOrderConfirmationScreen> createState() =>
      _FoodOrderConfirmationScreenState();
}

class _FoodOrderConfirmationScreenState
    extends State<FoodOrderConfirmationScreen> {
  final _databaseService = DatabaseService();
  final _authService = AuthService();
  final _eventTrackingService = EventTrackingService();
  final _screenStopwatch = Stopwatch();

  final _vouchers = const [
    _VoucherOption(code: 'Khong dung voucher', discountAmount: 0),
    _VoucherOption(code: 'FOOD15', discountAmount: 15000),
    _VoucherOption(code: 'FREESHIP20', discountAmount: 20000),
    _VoucherOption(code: 'NEWFOOD30', discountAmount: 30000),
  ];

  int _selectedVoucherIndex = 0;
  bool _isOrdering = false;
  String? _lastButtonBeforeCompletion;

  @override
  void initState() {
    super.initState();
    _screenStopwatch.start();
  }

  Map<String, dynamic> _buildCompletionInteraction({
    required String buttonLabel,
  }) {
    final duration = _screenStopwatch.elapsed;
    return {
      'screen': 'food_order_confirmation_screen',
      'completionButton': buttonLabel,
      'lastButtonBeforeCompletion': _lastButtonBeforeCompletion,
      'screenDurationMs': duration.inMilliseconds,
      'screenDurationSeconds': duration.inSeconds,
      'buttonClickedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _showVoucherPicker() async {
    _lastButtonBeforeCompletion = 'Mo chon voucher';
    final selectedIndex = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            const Text(
              'Chon voucher',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            for (var index = 0; index < _vouchers.length; index++)
              _VoucherTile(
                voucher: _vouchers[index],
                selected: _selectedVoucherIndex == index,
                onTap: () => Navigator.pop(sheetContext, index),
              ),
          ],
        ),
      ),
    );

    if (selectedIndex != null && mounted) {
      _lastButtonBeforeCompletion = 'Chon voucher: '
          '${_vouchers[selectedIndex].code}';
      setState(() => _selectedVoucherIndex = selectedIndex);
    }
  }

  Future<void> _placeOrder(
    FoodOrderDetails details, {
    required Map<String, dynamic> completionInteraction,
  }) async {
    setState(() => _isOrdering = true);

    final voucher = _vouchers[_selectedVoucherIndex];
    final finalDetails = details.copyWith(
      voucherCode: voucher.discountAmount == 0 ? null : voucher.code,
      discountAmount: voucher.discountAmount,
      completionInteraction: completionInteraction,
    );

    try {
      if (FirebaseBootstrap.isReady) {
        final orderId = await _databaseService.createFoodOrder(
          userId: _authService.currentUser?.uid,
          data: {
            'deliveryAddress': finalDetails.deliveryAddress,
            'restaurant': finalDetails.restaurantSummary,
            'items': finalDetails.items.map((item) => item.toMap()).toList(),
            'subtotal': finalDetails.subtotal,
            'deliveryDistanceKm': finalDetails.deliveryDistanceKm,
            'shippingFee': finalDetails.shippingFee,
            'voucherCode': finalDetails.voucherCode,
            'discountAmount': finalDetails.discountAmount,
            'totalPrice': finalDetails.finalPrice,
            'estimatedTime': finalDetails.estimatedTime,
            'completionInteraction': finalDetails.completionInteraction,
          },
        );

        await _eventTrackingService.trackFoodOrderCreated(
          orderId: orderId,
          restaurant: finalDetails.restaurantSummary,
          itemName: finalDetails.items.map((item) => item.item.name).join(', '),
          category: 'cart',
          quantity: finalDetails.items.fold(
            0,
            (total, item) => total + item.quantity,
          ),
          totalPrice: finalDetails.finalPrice,
          completionInteraction: completionInteraction,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Da gui don Food thanh cong')),
      );
      Navigator.popUntil(context, ModalRoute.withName('/home'));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isOrdering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final details =
        ModalRoute.of(context)?.settings.arguments as FoodOrderDetails?;
    if (details == null || details.items.isEmpty) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: Text('Chua co mon nao trong gio hang')),
        ),
      );
    }

    final voucher = _vouchers[_selectedVoucherIndex];
    final discount = voucher.discountAmount;
    final discountedTotal = details.subtotal + details.shippingFee - discount;
    final total = discountedTotal < 0 ? 0 : discountedTotal;

    return Scaffold(
      appBar: AppBar(title: const Text('Xac nhan don Food')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _InfoBox(
              icon: Icons.location_on_rounded,
              title: 'Giao den',
              value: details.deliveryAddress,
            ),
            const SizedBox(height: 16),
            const Text(
              'Gio hang',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final cartItem in details.items)
              _CartSummaryTile(cartItem: cartItem),
            const SizedBox(height: 16),
            const Text(
              'Voucher',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _showVoucherPicker,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_offer_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              voucher.code,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              voucher.discountAmount == 0
                                  ? 'Chon ma giam gia'
                                  : 'Giam ${formatVnd(voucher.discountAmount)}',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _PriceSummary(
              subtotal: details.subtotal,
              deliveryDistanceKm: details.deliveryDistanceKm,
              shippingFee: details.shippingFee,
              discount: discount,
              total: total,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isOrdering
                  ? null
                  : () => _placeOrder(
                        details,
                        completionInteraction: _buildCompletionInteraction(
                          buttonLabel: 'Dat don - ${formatVnd(total)}',
                        ),
                      ),
              icon: _isOrdering
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : const Icon(Icons.check_circle_rounded),
              label: Text('Dat don - ${formatVnd(total)}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartSummaryTile extends StatelessWidget {
  const _CartSummaryTile({required this.cartItem});

  final FoodCartItem cartItem;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Icon(cartItem.item.icon)),
      title: Text(
        cartItem.item.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text('${cartItem.quantity} x ${formatVnd(cartItem.item.price)}'),
      trailing: Text(
        formatVnd(cartItem.totalPrice),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _VoucherTile extends StatelessWidget {
  const _VoucherTile({
    required this.voucher,
    required this.selected,
    required this.onTap,
  });

  final _VoucherOption voucher;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_offer_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    voucher.code,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  voucher.discountAmount == 0
                      ? '0d'
                      : '-${formatVnd(voucher.discountAmount)}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  const _PriceSummary({
    required this.subtotal,
    required this.deliveryDistanceKm,
    required this.shippingFee,
    required this.discount,
    required this.total,
  });

  final int subtotal;
  final double deliveryDistanceKm;
  final int shippingFee;
  final int discount;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _PriceRow(label: 'Tam tinh', value: formatVnd(subtotal)),
          const SizedBox(height: 8),
          _PriceRow(
            label: 'Phi giao (${deliveryDistanceKm.toStringAsFixed(1)} km)',
            value: formatVnd(shippingFee),
          ),
          const SizedBox(height: 8),
          _PriceRow(label: 'Voucher', value: '-${formatVnd(discount)}'),
          const Divider(height: 24),
          _PriceRow(
            label: 'Tong tien',
            value: formatVnd(total),
            strong: true,
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
      fontSize: strong ? 18 : 14,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}

class _VoucherOption {
  const _VoucherOption({
    required this.code,
    required this.discountAmount,
  });

  final String code;
  final int discountAmount;
}
