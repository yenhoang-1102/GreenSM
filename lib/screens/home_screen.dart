import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firebase/auth_service.dart';
import '../services/firebase/firebase_bootstrap.dart';
import 'food_order_screen.dart';
import 'activity_history_screen.dart';
import 'location_search_screen.dart';
import 'login_screen.dart';
import 'widgets/xanh_home_content.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: XanhHomeContent(
        onHistory: () => Navigator.pushNamed(
          context,
          ActivityHistoryScreen.routeName,
        ),
        onNotifications: () => _showNotifications(context),
        onLogout: () => _confirmLogout(context),
      ),
    );
  }

  Future<void> _showNotifications(BuildContext context) {
    const notifications = <_AppNotification>[];

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Thong bao',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Dong',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (notifications.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Text('Khong co thong bao nao'),
                    ),
                  )
                else
                  for (final notification in notifications)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(child: Icon(notification.icon)),
                      title: Text(notification.title),
                      subtitle: Text(notification.message),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Dang xuat'),
          content: const Text('Ban co chac muon dang xuat khoi Xanh SM?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Huy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Dang xuat'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !context.mounted) return;

    try {
      if (FirebaseBootstrap.isReady) {
        await AuthService().logout();
      }
    } finally {
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        LoginScreen.routeName,
        (route) => false,
      );
    }
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.onNotifications,
    required this.onLogout,
  });

  final VoidCallback onNotifications;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 54),
      decoration: const BoxDecoration(
        color: Color(0xFF00B14F),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.energy_savings_leaf_rounded,
                  color: Color(0xFF00B14F),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Xanh SM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _HeaderIconButton(
                icon: Icons.notifications_none_rounded,
                onTap: onNotifications,
                tooltip: 'Thong bao',
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                icon: Icons.logout_rounded,
                onTap: onLogout,
                tooltip: 'Dang xuat',
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _GreetingTitle(light: true),
          const SizedBox(height: 6),
          const Text(
            'Dat xe xanh, goi Food nhanh trong mot app',
            style: TextStyle(
              color: Color(0xE6FFFFFF),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18005B2C),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFE7F8EE),
                child: Icon(Icons.search_rounded, color: Color(0xFF00A64B)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ban muon di dau?',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppNotification {
  const _AppNotification({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;
}

class _GreetingTitle extends StatelessWidget {
  const _GreetingTitle({this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final fallbackName = _nameFromUser(user);
    final textStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: light ? Colors.white : const Color(0xFF062D1D),
          fontWeight: FontWeight.w900,
        );

    if (!FirebaseBootstrap.isReady || user == null) {
      return Text('Xin chao, $fallbackName', style: textStyle);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final firestoreName = _nameFromProfile(data);
        final displayName =
            firestoreName.isNotEmpty ? firestoreName : fallbackName;

        return Text('Xin chao, $displayName', style: textStyle);
      },
    );
  }

  static String _nameFromProfile(Map<String, dynamic>? data) {
    if (data == null) return '';
    final name = data['name']?.toString().trim() ?? '';
    if (name.isNotEmpty) return name;
    return data['displayName']?.toString().trim() ?? '';
  }

  static String _nameFromUser(User? user) {
    final displayName = user?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;

    final email = user?.email?.trim() ?? '';
    if (email.isNotEmpty) return email.split('@').first;

    final phone = user?.phoneNumber?.trim() ?? '';
    if (phone.isNotEmpty) return phone;

    return 'ban';
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.electric_car_rounded,
            label: 'Dat xe',
            subtitle: 'Xe xanh gan ban',
            onTap: () {
              Navigator.pushNamed(context, LocationSearchScreen.routeName);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionTile(
            icon: Icons.restaurant_rounded,
            label: 'Food',
            subtitle: 'Mon ngon giao nhanh',
            onTap: () {
              Navigator.pushNamed(context, FoodOrderScreen.routeName);
            },
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE4F4EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F8EE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: const Color(0xFF00A64B)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF062D1D),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
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

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F8EE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBEFDB)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFF00B14F),
            foregroundColor: Colors.white,
            child: Icon(Icons.local_offer_rounded),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Giam 25% cho chuyen dat xe hoac don Food dau tien trong ngay.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF062D1D),
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RecentPlace extends StatelessWidget {
  const _RecentPlace({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 2),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE7F8EE),
        child: Icon(icon, color: const Color(0xFF00A64B)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
    );
  }
}
