import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'admin_settings_screen.dart';
import 'categories_screen.dart';
import 'dashboard_screen.dart';
import 'foods_screen.dart';
import 'orders_screen.dart';
import 'promos_screen.dart';
import 'users_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _i = 0;
  static const _titles = [
    'Dashboard',
    'Orders',
    'Foods',
    'Categories',
    'Promos',
    'Users',
    'Settings',
  ];
  static const _pages = <Widget>[
    DashboardScreen(),
    AdminOrdersScreen(),
    FoodsScreen(),
    CategoriesScreen(),
    AdminPromosScreen(),
    UsersScreen(),
    AdminSettingsScreen(),
  ];

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await AuthService().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 720;
        return Scaffold(
          appBar: AppBar(
            title: Text(_titles[_i]),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Logout',
                onPressed: _logout,
              ),
            ],
          ),
          body: wide
              ? Row(
                  children: [
                    NavigationRail(
                      extended: c.maxWidth >= 1100,
                      selectedIndex: _i,
                      onDestinationSelected: (i) => setState(() => _i = i),
                      destinations: const [
                        NavigationRailDestination(
                            icon: Icon(Icons.dashboard_outlined),
                            label: Text('Dashboard')),
                        NavigationRailDestination(
                            icon: Icon(Icons.receipt_long_outlined),
                            label: Text('Orders')),
                        NavigationRailDestination(
                            icon: Icon(Icons.fastfood_outlined),
                            label: Text('Foods')),
                        NavigationRailDestination(
                            icon: Icon(Icons.category_outlined),
                            label: Text('Categories')),
                        NavigationRailDestination(
                            icon: Icon(Icons.local_offer_outlined),
                            label: Text('Promos')),
                        NavigationRailDestination(
                            icon: Icon(Icons.people_outline_rounded),
                            label: Text('Users')),
                        NavigationRailDestination(
                            icon: Icon(Icons.settings_outlined),
                            label: Text('Settings')),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    const Expanded(child: _AdminBody()),
                  ],
                )
              : const _AdminBody(),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _i >= 4 ? 4 : _i,
                  onDestinationSelected: (i) {
                    if (i == 4) {
                      showModalBottomSheet(
                        context: context,
                        showDragHandle: true,
                        builder: (_) => AdminMoreSheet(
                          onPick: (index) => setState(() => _i = index),
                          onLogout: _logout,
                        ),
                      );
                      return;
                    }
                    setState(() => _i = i);
                  },
                  destinations: const [
                    NavigationDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard_rounded),
                        label: 'Home'),
                    NavigationDestination(
                        icon: Icon(Icons.receipt_long_outlined),
                        selectedIcon: Icon(Icons.receipt_long_rounded),
                        label: 'Orders'),
                    NavigationDestination(
                        icon: Icon(Icons.fastfood_outlined),
                        selectedIcon: Icon(Icons.fastfood_rounded),
                        label: 'Foods'),
                    NavigationDestination(
                        icon: Icon(Icons.category_outlined),
                        selectedIcon: Icon(Icons.category_rounded),
                        label: 'Cats'),
                    NavigationDestination(
                        icon: Icon(Icons.more_horiz_rounded),
                        selectedIcon: Icon(Icons.more_rounded),
                        label: 'More'),
                  ],
                ),
        );
      },
    );
  }
}

class _AdminBody extends StatelessWidget {
  const _AdminBody();

  @override
  Widget build(BuildContext context) {
    final shell = context.findAncestorStateOfType<_AdminShellState>();
    if (shell == null) return const SizedBox.shrink();
    // The five bar destinations stay mounted; picking one from the More
    // sheet swaps the visible page without losing stream state.
    return IndexedStack(index: shell._i, children: _AdminShellState._pages);
  }
}

/// Sheet listing the admin sections that did not fit in the bottom bar.
class AdminMoreSheet extends StatelessWidget {
  const AdminMoreSheet({required this.onPick, required this.onLogout, super.key});
  final void Function(int index) onPick;
  final VoidCallback onLogout;

  static const _extra = [
    (Icons.local_offer_outlined, 'Promo codes'),
    (Icons.people_outline_rounded, 'Users'),
    (Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, label) in _extra.indexed)
            ListTile(
              leading: Icon(label.$1, color: AppColors.primary),
              title: Text(label.$2),
              onTap: () {
                Navigator.pop(context);
                // 4 = Promos, 5 = Users, 6 = Settings in _AdminShellState.
                onPick(i + 4);
              },
            ),
          ListTile(
            leading:
                const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}