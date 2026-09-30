import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/food_order_details.dart';
import '../services/geocoding_service.dart';
import '../services/nearby_restaurant_service.dart';
import 'food_order_confirmation_screen.dart';

const _cafeMenuTemplates = [
  _GeneratedMenuItem('ca_phe_sua', 'Ca phe sua da', 'Do uong', 29000, Icons.coffee_rounded),
  _GeneratedMenuItem('bac_xiu', 'Bac xiu', 'Do uong', 35000, Icons.local_cafe_rounded),
  _GeneratedMenuItem('tra_dao', 'Tra dao cam sa', 'Do uong', 39000, Icons.local_drink_rounded),
  _GeneratedMenuItem('matcha', 'Matcha latte', 'Do uong', 49000, Icons.emoji_food_beverage_rounded),
  _GeneratedMenuItem('banh_ngot', 'Banh ngot trong ngay', 'Trang mieng', 32000, Icons.cake_rounded),
];

const _fastFoodMenuTemplates = [
  _GeneratedMenuItem('burger_bo', 'Burger bo pho mai', 'An nhanh', 59000, Icons.lunch_dining_rounded),
  _GeneratedMenuItem('ga_ran', 'Ga ran gion', 'An nhanh', 49000, Icons.fastfood_rounded),
  _GeneratedMenuItem('khoai_tay', 'Khoai tay chien', 'An nhanh', 29000, Icons.fastfood_rounded),
  _GeneratedMenuItem('combo_ga', 'Combo ga ran', 'Combo', 89000, Icons.takeout_dining_rounded),
  _GeneratedMenuItem('nuoc_ngot', 'Nuoc ngot', 'Do uong', 19000, Icons.local_drink_rounded),
];

const _restaurantMenuTemplates = [
  _GeneratedMenuItem('com_suon', 'Com suon nuong', 'Com', 55000, Icons.rice_bowl_rounded),
  _GeneratedMenuItem('com_ga', 'Com ga', 'Com', 59000, Icons.restaurant_rounded),
  _GeneratedMenuItem('pho_bo', 'Pho bo tai nam', 'Bun/Pho', 65000, Icons.ramen_dining_rounded),
  _GeneratedMenuItem('bun_bo', 'Bun bo', 'Bun/Pho', 62000, Icons.ramen_dining_rounded),
  _GeneratedMenuItem('salad', 'Salad ga nuong', 'Healthy', 69000, Icons.eco_rounded),
];

class FoodOrderScreen extends StatefulWidget {
  const FoodOrderScreen({super.key});

  static const routeName = '/food-order';

  @override
  State<FoodOrderScreen> createState() => _FoodOrderScreenState();
}

class _FoodOrderScreenState extends State<FoodOrderScreen> {
  final _deliveryAddressController =
      TextEditingController(text: 'Giao den vi tri hien tai');
  final _searchController = TextEditingController();
  final _geocodingService = GeocodingService();
  final _nearbyRestaurantService = const NearbyRestaurantService();
  List<NearbyRestaurant> _nearbyRestaurants = const [];
  LatLng? _currentPosition;
  bool _isLoadingLocation = true;
  String? _locationError;

  final _items = const [
    FoodMenuItem(
      id: 'com_tam_suon',
      name: 'Com tam suon bi cha',
      restaurant: 'Quan Com Sai Gon',
      category: 'Com',
      time: '20-25 phut',
      distance: '1.2 km',
      rating: 4.8,
      price: 55000,
      icon: Icons.rice_bowl_rounded,
    ),
    FoodMenuItem(
      id: 'com_ga_xoi_mo',
      name: 'Com ga xoi mo',
      restaurant: 'Com Ga Tan Dinh',
      category: 'Com',
      time: '22-28 phut',
      distance: '1.8 km',
      rating: 4.7,
      price: 59000,
      icon: Icons.restaurant_rounded,
    ),
    FoodMenuItem(
      id: 'bun_bo_hue',
      name: 'Bun bo Hue',
      restaurant: 'Bep Co Hue',
      category: 'Bun/Pho',
      time: '25-30 phut',
      distance: '2.4 km',
      rating: 4.9,
      price: 62000,
      icon: Icons.ramen_dining_rounded,
    ),
    FoodMenuItem(
      id: 'pho_bo_tai_nam',
      name: 'Pho bo tai nam',
      restaurant: 'Pho Ha Noi 36',
      category: 'Bun/Pho',
      time: '18-24 phut',
      distance: '1.5 km',
      rating: 4.6,
      price: 68000,
      icon: Icons.ramen_dining_rounded,
    ),
    FoodMenuItem(
      id: 'mi_quang_ga',
      name: 'Mi quang ga',
      restaurant: 'Mi Quang Da Nang',
      category: 'Bun/Pho',
      time: '25-35 phut',
      distance: '3.1 km',
      rating: 4.5,
      price: 58000,
      icon: Icons.ramen_dining_rounded,
    ),
    FoodMenuItem(
      id: 'banh_mi_dac_biet',
      name: 'Banh mi dac biet',
      restaurant: 'Banh Mi Pho Cu',
      category: 'An nhanh',
      time: '10-15 phut',
      distance: '0.7 km',
      rating: 4.8,
      price: 32000,
      icon: Icons.bakery_dining_rounded,
    ),
    FoodMenuItem(
      id: 'ga_ran_combo',
      name: 'Ga ran combo 2 mieng',
      restaurant: 'Crispy Chicken',
      category: 'An nhanh',
      time: '20-25 phut',
      distance: '2.0 km',
      rating: 4.4,
      price: 79000,
      icon: Icons.fastfood_rounded,
    ),
    FoodMenuItem(
      id: 'burger_bo_pho_mai',
      name: 'Burger bo pho mai',
      restaurant: 'Burger Corner',
      category: 'An nhanh',
      time: '18-24 phut',
      distance: '1.9 km',
      rating: 4.5,
      price: 72000,
      icon: Icons.lunch_dining_rounded,
    ),
    FoodMenuItem(
      id: 'pizza_hai_san',
      name: 'Pizza hai san',
      restaurant: 'Pizza Roma',
      category: 'Pizza',
      time: '30-40 phut',
      distance: '3.4 km',
      rating: 4.6,
      price: 139000,
      icon: Icons.local_pizza_rounded,
    ),
    FoodMenuItem(
      id: 'pizza_pepperoni',
      name: 'Pizza pepperoni',
      restaurant: 'Pizza Roma',
      category: 'Pizza',
      time: '30-40 phut',
      distance: '3.4 km',
      rating: 4.7,
      price: 129000,
      icon: Icons.local_pizza_rounded,
    ),
    FoodMenuItem(
      id: 'tra_sua_tran_chau',
      name: 'Tra sua tran chau',
      restaurant: 'Milk Tea House',
      category: 'Do uong',
      time: '15-20 phut',
      distance: '1.1 km',
      rating: 4.8,
      price: 39000,
      icon: Icons.local_cafe_rounded,
    ),
    FoodMenuItem(
      id: 'ca_phe_sua_da',
      name: 'Ca phe sua da',
      restaurant: 'Ca Phe Goc Pho',
      category: 'Do uong',
      time: '10-15 phut',
      distance: '0.6 km',
      rating: 4.7,
      price: 29000,
      icon: Icons.coffee_rounded,
    ),
    FoodMenuItem(
      id: 'sinh_to_bo',
      name: 'Sinh to bo',
      restaurant: 'Fresh Juice Bar',
      category: 'Do uong',
      time: '12-18 phut',
      distance: '1.4 km',
      rating: 4.5,
      price: 42000,
      icon: Icons.local_drink_rounded,
    ),
    FoodMenuItem(
      id: 'salad_ga_nuong',
      name: 'Salad ga nuong',
      restaurant: 'Green Bowl',
      category: 'Healthy',
      time: '20-25 phut',
      distance: '2.2 km',
      rating: 4.9,
      price: 76000,
      icon: Icons.eco_rounded,
    ),
    FoodMenuItem(
      id: 'poke_ca_hoi',
      name: 'Poke ca hoi',
      restaurant: 'Fresh Poke',
      category: 'Healthy',
      time: '25-30 phut',
      distance: '2.8 km',
      rating: 4.8,
      price: 99000,
      icon: Icons.set_meal_rounded,
    ),
    FoodMenuItem(
      id: 'banh_flan_caramel',
      name: 'Banh flan caramel',
      restaurant: 'Sweet Home',
      category: 'Trang mieng',
      time: '15-20 phut',
      distance: '1.6 km',
      rating: 4.6,
      price: 35000,
      icon: Icons.icecream_rounded,
    ),
  ];

  final Map<String, FoodCartItem> _cart = {};
  String _selectedCategory = 'Tat ca';

  @override
  void initState() {
    super.initState();
    _loadCurrentLocationAndRestaurants();
  }

  List<String> get _categories {
    return ['Tat ca', ...{for (final item in _items) item.category}];
  }

  List<FoodMenuItem> get _filteredItems {
    final keyword = _searchController.text.trim().toLowerCase();
    return _items.where((item) {
      final matchesCategory =
          _selectedCategory == 'Tat ca' || item.category == _selectedCategory;
      final matchesSearch = keyword.isEmpty ||
          item.name.toLowerCase().contains(keyword) ||
          item.restaurant.toLowerCase().contains(keyword);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<NearbyRestaurant> get _filteredRestaurants {
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isEmpty) return _nearbyRestaurants;
    return _nearbyRestaurants.where((restaurant) {
      return restaurant.name.toLowerCase().contains(keyword) ||
          restaurant.type.toLowerCase().contains(keyword) ||
          (restaurant.cuisine?.toLowerCase().contains(keyword) ?? false);
    }).toList(growable: false);
  }

  int get _cartCount {
    return _cart.values.fold(0, (total, cartItem) => total + cartItem.quantity);
  }

  int get _cartTotal {
    return _cart.values.fold(0, (total, cartItem) => total + cartItem.totalPrice);
  }

  @override
  void dispose() {
    _deliveryAddressController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocationAndRestaurants() async {
    if (mounted) {
      setState(() {
        _isLoadingLocation = true;
        _locationError = null;
      });
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('GPS dang tat. Hay bat vi tri de tim quan gan ban.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception('Ban chua cap quyen truy cap vi tri.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Quyen vi tri da bi tu choi vinh vien. Hay bat lai trong Cai dat.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 15));
      final current = LatLng(position.latitude, position.longitude);

      String? address;
      try {
        final result = await _geocodingService
            .reverseGeocode(current)
            .timeout(const Duration(seconds: 12));
        address = result.address;
      } catch (_) {
        address =
            '${current.latitude.toStringAsFixed(5)}, ${current.longitude.toStringAsFixed(5)}';
      }

      final restaurants = await _nearbyRestaurantService.findNearby(
        center: current,
        radiusMeters: 3000,
      );
      if (!mounted) return;
      setState(() {
        _currentPosition = current;
        _deliveryAddressController.text = address!;
        _nearbyRestaurants = restaurants;
        _isLoadingLocation = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = false;
        _locationError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _showRestaurantDetails(NearbyRestaurant restaurant) {
    final menu = _generateRestaurantMenu(restaurant);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.86,
          minChildSize: 0.55,
          maxChildSize: 0.94,
          builder: (context, scrollController) => SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              restaurant.name,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close_rounded),
                            tooltip: 'Dong menu',
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          _MetaText(
                            icon: Icons.near_me_rounded,
                            text:
                                '${restaurant.distanceKm.toStringAsFixed(1)} km',
                          ),
                          _MetaText(
                            icon: Icons.restaurant_rounded,
                            text: restaurant.cuisine ?? restaurant.type,
                          ),
                          if (restaurant.openingHours != null)
                            _MetaText(
                              icon: Icons.schedule_rounded,
                              text: restaurant.openingHours!,
                            ),
                        ],
                      ),
                      if (restaurant.address != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          restaurant.address!,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                      const SizedBox(height: 14),
                      const Text(
                        'Menu quan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    itemCount: menu.length,
                    itemBuilder: (context, index) {
                      final item = menu[index];
                      return _FoodTile(
                        item: item,
                        quantity: _cart[item.id]?.quantity ?? 0,
                        onAdd: () {
                          _addToCart(item);
                          setSheetState(() {});
                        },
                        onRemove: () {
                          _decreaseCartItem(item);
                          setSheetState(() {});
                        },
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE7ECEC))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$_cartCount mon - ${formatVnd(_cartTotal)}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      _SmallActionButton(
                        label: 'Xem gio hang',
                        enabled: _cartCount > 0,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _continueToConfirmation();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<FoodMenuItem> _generateRestaurantMenu(NearbyRestaurant restaurant) {
    final normalizedType =
        '${restaurant.type} ${restaurant.cuisine ?? ''}'.toLowerCase();
    final templates = normalizedType.contains('cafe') ||
            normalizedType.contains('coffee') ||
            normalizedType.contains('ca phe')
        ? _cafeMenuTemplates
        : normalizedType.contains('fast') ||
                normalizedType.contains('an nhanh') ||
                normalizedType.contains('burger')
            ? _fastFoodMenuTemplates
            : _restaurantMenuTemplates;
    final deliveryMinutes = 15 + (restaurant.distanceKm * 5).round();
    final safeRestaurantId = restaurant.id.replaceAll(
      RegExp(r'[^a-zA-Z0-9_]'),
      '_',
    );

    return List.generate(templates.length, (index) {
      final template = templates[index];
      return FoodMenuItem(
        id: '${safeRestaurantId}_${template.id}',
        name: template.name,
        restaurant: restaurant.name,
        category: template.category,
        time: '$deliveryMinutes-${deliveryMinutes + 10} phut',
        distance: '${restaurant.distanceKm.toStringAsFixed(1)} km',
        rating: 4.5 + (index % 5) * 0.1,
        price: template.price,
        icon: template.icon,
      );
    }, growable: false);
  }

  void _addToCart(FoodMenuItem item) {
    setState(() {
      final current = _cart[item.id];
      _cart[item.id] = FoodCartItem(
        item: item,
        quantity: (current?.quantity ?? 0) + 1,
      );
    });
  }

  void _decreaseCartItem(FoodMenuItem item) {
    setState(() {
      final current = _cart[item.id];
      if (current == null) return;
      if (current.quantity <= 1) {
        _cart.remove(item.id);
      } else {
        _cart[item.id] = FoodCartItem(
          item: item,
          quantity: current.quantity - 1,
        );
      }
    });
  }

  void _continueToConfirmation() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui long them mon vao gio hang')),
      );
      return;
    }
    if (_deliveryAddressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui long nhap dia chi giao hang')),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      FoodOrderConfirmationScreen.routeName,
      arguments: FoodOrderDetails(
        deliveryAddress: _deliveryAddressController.text.trim(),
        items: _cart.values.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _filteredItems;

    return Scaffold(
      appBar: AppBar(title: const Text('Dat Food')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextField(
                    controller: _deliveryAddressController,
                    decoration: InputDecoration(
                      labelText: 'Dia chi giao hang',
                      prefixIcon: const Icon(Icons.location_on_rounded),
                      suffixIcon: _isLoadingLocation
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.3,
                                ),
                              ),
                            )
                          : IconButton(
                              onPressed: _loadCurrentLocationAndRestaurants,
                              icon: const Icon(Icons.my_location_rounded),
                              tooltip: 'Cap nhat vi tri hien tai',
                            ),
                    ),
                  ),
                  if (_locationError != null) ...[
                    const SizedBox(height: 10),
                    _LocationMessage(
                      message: _locationError!,
                      isError: true,
                      onRetry: _loadCurrentLocationAndRestaurants,
                    ),
                  ] else if (_currentPosition != null) ...[
                    const SizedBox(height: 10),
                    const _LocationMessage(
                      message: 'Da xac nhan vi tri - dang tim trong ban kinh 3 km',
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Tim mon an hoac quan',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Quan gan ban trong 3 km',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (!_isLoadingLocation)
                        Text('${_filteredRestaurants.length} quan'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingLocation)
                    const SizedBox(
                      height: 132,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_nearbyRestaurants.isEmpty)
                    const SizedBox(
                      height: 96,
                      child: Center(
                        child: Text('Chua tim thay quan an trong ban kinh 3 km'),
                      ),
                    )
                  else if (_filteredRestaurants.isEmpty)
                    const SizedBox(
                      height: 96,
                      child: Center(
                        child: Text('Khong co quan phu hop tu khoa'),
                      ),
                    )
                  else
                    SizedBox(
                      height: 142,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filteredRestaurants.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final restaurant = _filteredRestaurants[index];
                          return _NearbyRestaurantCard(
                            restaurant: restaurant,
                            onTap: () => _showRestaurantDetails(restaurant),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return ChoiceChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (_) {
                            setState(() => _selectedCategory = category);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mon goi y',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text('${visibleItems.length} mon'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (visibleItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(child: Text('Khong tim thay mon phu hop')),
                    )
                  else
                    ...visibleItems.map(
                      (item) => _FoodTile(
                        item: item,
                        quantity: _cart[item.id]?.quantity ?? 0,
                        onAdd: () => _addToCart(item),
                        onRemove: () => _decreaseCartItem(item),
                      ),
                    ),
                ],
              ),
            ),
            _CartBar(
              count: _cartCount,
              total: _cartTotal,
              onConfirm: _continueToConfirmation,
            ),
          ],
        ),
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  const _CartBar({
    required this.count,
    required this.total,
    required this.onConfirm,
  });

  final int count;
  final int total;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.shopping_cart_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count == 0 ? 'Gio hang dang trong' : '$count mon trong gio',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(formatVnd(total)),
              ],
            ),
          ),
          _SmallActionButton(
            label: 'Xac nhan',
            enabled: count > 0,
            onTap: onConfirm,
          ),
        ],
      ),
    );
  }
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({
    required this.item,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  final FoodMenuItem item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final selected = quantity > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: selected
                          ? Theme.of(context).colorScheme.primary
                          : const Color(0xFFEFF3F6),
                      child: Icon(
                        item.icon,
                        color: selected ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(item.restaurant),
                        ],
                      ),
                    ),
                    Text(
                      formatVnd(item.price),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    _MetaText(
                      icon: Icons.star_rounded,
                      text: item.rating.toStringAsFixed(1),
                    ),
                    _MetaText(
                      icon: Icons.schedule_rounded,
                      text: item.time,
                    ),
                    _MetaText(
                      icon: Icons.near_me_rounded,
                      text: item.distance,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: quantity == 0
                      ? _SmallActionButton(
                          label: 'Them',
                          icon: Icons.add_rounded,
                          onTap: onAdd,
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: onRemove,
                              icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                              ),
                              tooltip: 'Giam so luong',
                            ),
                            Text(
                              '$quantity',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            IconButton(
                              onPressed: onAdd,
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                              ),
                              tooltip: 'Tang so luong',
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor =
        enabled ? colorScheme.primary : const Color(0xFFE6ECE8);
    final foregroundColor = enabled ? Colors.white : Colors.black45;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 104, minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: foregroundColor),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.black54),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }
}

class _LocationMessage extends StatelessWidget {
  const _LocationMessage({
    required this.message,
    this.isError = false,
    this.onRetry,
  });

  final String message;
  final bool isError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isError ? Icons.location_off_rounded : Icons.check_circle_rounded,
          size: 18,
          color: isError ? Colors.redAccent : const Color(0xFF00AAB7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Thu lai')),
      ],
    );
  }
}

class _NearbyRestaurantCard extends StatelessWidget {
  const _NearbyRestaurantCard({
    required this.restaurant,
    required this.onTap,
  });

  final NearbyRestaurant restaurant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFE2F9FA),
                      child: Icon(
                        Icons.restaurant_rounded,
                        color: Color(0xFF00AAB7),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        restaurant.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  restaurant.cuisine ?? restaurant.type,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${restaurant.distanceKm.toStringAsFixed(1)} km tu ban',
                  style: const TextStyle(
                    color: Color(0xFF008C96),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GeneratedMenuItem {
  const _GeneratedMenuItem(
    this.id,
    this.name,
    this.category,
    this.price,
    this.icon,
  );

  final String id;
  final String name;
  final String category;
  final int price;
  final IconData icon;
}
