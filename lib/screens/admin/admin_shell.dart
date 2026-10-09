import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'foods_screen.dart';
import 'orders_screen.dart';
import 'users_screen.dart';
import 'categories_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _i = 0;
  static const _titles = ['Dashboard', 'Orders', 'Foods', 'Categories', 'Users'];
  static const _pages = [
    DashboardScreen(),
    AdminOrdersScreen(),
    FoodsScreen(),
    CategoriesScreen(),
    UsersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 720;
        Future<void> logout() async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Logout?'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Logout')),
              ],
            ),
          );
          if (ok == true) {
            await AuthService().signOut();
          }
        }

        if (!wide) {
          return Scaffold(
            appBar: AppBar(
              title: Text(_titles[_i]),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  tooltip: 'Logout',
                  onPressed: logout,
                ),
              ],
            ),
            body: IndexedStack(index: _i, children: _pages),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _i,
              onDestinationSelected: (i) => setState(() => _i = i),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
                NavigationDestination(icon: Icon(Icons.fastfood_outlined), selectedIcon: Icon(Icons.fastfood_rounded), label: 'Foods'),
                NavigationDestination(icon: Icon(Icons.category_outlined), selectedIcon: Icon(Icons.category_rounded), label: 'Cats'),
                NavigationDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded), label: 'Users'),
              ],
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(_titles[_i]),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Logout',
                onPressed: logout,
              ),
            ],
          ),
          body: Row(
            children: [
              NavigationRail(
                extended: c.maxWidth >= 1100,
                selectedIndex: _i,
                onDestinationSelected: (i) => setState(() => _i = i),
                destinations: const [
                  NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), label: Text('Dashboard')),
                  NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), label: Text('Orders')),
                  NavigationRailDestination(icon: Icon(Icons.fastfood_outlined), label: Text('Foods')),
                  NavigationRailDestination(icon: Icon(Icons.category_outlined), label: Text('Categories')),
                  NavigationRailDestination(icon: Icon(Icons.people_outline_rounded), label: Text('Users')),
                ],
              ),
              const VerticalDivider(width: 1),
              const Expanded(child: MainShellPlaceholder()),
            ],
          ),
        );
      },
    );
  }
}

class MainShellPlaceholder extends StatelessWidget {
  const MainShellPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    // Wide layout reuses selected admin page via ancestor state.
    final state = context.findAncestorStateOfType<_AdminShellState>()!;
    return IndexedStack(index: state._i, children: _AdminShellState._pages);
  }
}
