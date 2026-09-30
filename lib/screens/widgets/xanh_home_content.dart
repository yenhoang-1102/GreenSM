import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/firebase/firebase_bootstrap.dart';
import '../food_order_screen.dart';
import '../location_search_screen.dart';

class XanhHomeContent extends StatelessWidget {
  const XanhHomeContent({
    super.key,
    required this.onNotifications,
    required this.onLogout,
    required this.onHistory,
  });

  final VoidCallback onNotifications;
  final VoidCallback onLogout;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 126),
            children: [
              _TopBar(onProfile: () => _showAccount(context)),
              const SizedBox(height: 26),
              const _Greeting(),
              const SizedBox(height: 18),
              const _Services(),
              const SizedBox(height: 24),
              const _PromoCarousel(),
              const SizedBox(height: 28),
              const Text(
                'Uu dai danh cho ban',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const _Offers(),
            ],
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 16,
            child: _BottomBar(
              onHistory: onHistory,
              onNotifications: onNotifications,
              onProfile: () => _showAccount(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAccount(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(0xFFE2F9FA),
                  child: Icon(Icons.person_rounded, color: Color(0xFF00AAB7)),
                ),
                title: _Greeting(compact: true),
                subtitle: Text('Tai khoan Xanh SM'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Dang xuat'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onLogout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onProfile});

  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.white,
            elevation: 3,
            shadowColor: const Color(0x24005860),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, LocationSearchScreen.routeName),
              borderRadius: BorderRadius.circular(20),
              child: const SizedBox(
                height: 64,
                child: Row(
                  children: [
                    SizedBox(width: 20),
                    Icon(Icons.search_rounded, size: 30),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Ban muon di dau?',
                        style: TextStyle(
                          color: Color(0xFF747B7C),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: Colors.white,
          elevation: 3,
          shadowColor: const Color(0x24005860),
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: onProfile,
            icon: const Icon(Icons.person_rounded),
            iconSize: 28,
            tooltip: 'Tai khoan',
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}

class _Services extends StatelessWidget {
  const _Services();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _ServiceCard(
            title: 'Dat do an',
            eta: '3 phut',
            icon: Icons.fastfood_rounded,
            height: 170,
            background: const Color(0xFFFFF8E8),
            accent: const Color(0xFFFFA000),
            onTap: () => Navigator.pushNamed(context, FoodOrderScreen.routeName),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ServiceCard(
            title: 'Di chuyen',
            eta: '1 phut',
            icon: Icons.electric_car_rounded,
            height: 170,
            background: const Color(0xFFE7FAFB),
            accent: const Color(0xFF00B8C4),
            onTap: () => Navigator.pushNamed(context, LocationSearchScreen.routeName),
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.title,
    required this.eta,
    required this.icon,
    required this.height,
    required this.background,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String eta;
  final IconData icon;
  final double height;
  final Color background;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(icon, size: height * .48, color: accent),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(eta, style: const TextStyle(color: Color(0xFF7A8586), fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoCarousel extends StatefulWidget {
  const _PromoCarousel();

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  static const _banners = [
    _PromoData(
      eyebrow: 'XANH SM',
      title: 'CHON SAN SANG.\nCHON VUNG VANG.',
      subtitle: 'Di chuyen xanh, an tam moi hanh trinh',
      icon: Icons.electric_car_rounded,
      background: Color(0xFF00B8C4),
    ),
    _PromoData(
      eyebrow: 'UU DAI DI CHUYEN',
      title: 'GIAM 25%\nCHUYEN DAU TIEN',
      subtitle: 'Ap dung cho khach hang moi',
      icon: Icons.local_offer_rounded,
      background: Color(0xFF009B77),
    ),
    _PromoData(
      eyebrow: 'XANH SM FOOD',
      title: 'MON NGON DEN\nTHAT NHANH',
      subtitle: 'Mien phi giao cho don hang dau tien',
      icon: Icons.delivery_dining_rounded,
      background: Color(0xFF087F8C),
    ),
  ];

  final _controller = PageController();
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      final nextPage = (_currentPage + 1) % _banners.length;
      _controller.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 172,
          child: PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) => _PromoBanner(data: _banners[index]),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: index == _currentPage ? 30 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: index == _currentPage
                    ? const Color(0xFF00B8C4)
                    : const Color(0xFFD3D8D8),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.data});

  final _PromoData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: data.background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.energy_savings_leaf_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        data.eyebrow,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Icon(data.icon, color: Colors.white, size: 78),
          ),
        ],
      ),
    );
  }
}

class _PromoData {
  const _PromoData({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.background,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
}

class _Offers extends StatelessWidget {
  const _Offers();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _offer(Icons.local_offer_rounded, 'Giam 25%\nchuyen dau tien', const Color(0xFFE2F9FA), const Color(0xFF00AAB7))),
        const SizedBox(width: 12),
        Expanded(child: _offer(Icons.delivery_dining_rounded, 'Mien phi giao\ndon Food moi', const Color(0xFFFFF5E1), const Color(0xFFFF9800))),
      ],
    );
  }

  Widget _offer(IconData icon, String text, Color color, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.onHistory,
    required this.onNotifications,
    required this.onProfile,
  });

  final VoidCallback onHistory;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF7FFFFFF),
      elevation: 12,
      shadowColor: const Color(0x33005860),
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 72,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const _NavIcon(icon: Icons.home_rounded, active: true, tooltip: 'Trang chu'),
            _NavIcon(icon: Icons.history_rounded, tooltip: 'Lich su', onTap: onHistory),
            _NavIcon(icon: Icons.notifications_rounded, tooltip: 'Thong bao', onTap: onNotifications),
            _NavIcon(icon: Icons.person_rounded, tooltip: 'Tai khoan', onTap: onProfile),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, required this.tooltip, this.active = false, this.onTap});

  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFE1F9FA) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: active ? const Color(0xFF00AAB7) : const Color(0xFF7B8485)),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final fallback = _fromUser(user);
    final style = TextStyle(fontSize: compact ? 17 : 24, fontWeight: FontWeight.w800);
    if (!FirebaseBootstrap.isReady || user == null) return Text('Xin chao, $fallback', style: style);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final saved = data?['name']?.toString().trim() ?? data?['displayName']?.toString().trim() ?? '';
        return Text('Xin chao, ${saved.isNotEmpty ? saved : fallback}', style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
      },
    );
  }

  static String _fromUser(User? user) {
    final name = user?.displayName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    final email = user?.email?.trim() ?? '';
    if (email.isNotEmpty) return email.split('@').first;
    final phone = user?.phoneNumber?.trim() ?? '';
    return phone.isNotEmpty ? phone : 'ban';
  }
}
