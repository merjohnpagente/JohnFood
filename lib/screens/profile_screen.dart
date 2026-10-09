import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/providers.dart';
import '../services/auth_service.dart';
import '../services/menu_service.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../utils/responsive.dart';
import '../widgets/ui_kit.dart';
import 'addresses_screen.dart';
import 'help_support_screen.dart';
import 'orders_screen.dart';
import 'payment_methods_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().refresh();
    });
  }

  void _settings() {
    final theme = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Settings',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dark mode'),
                secondary: const Icon(Icons.dark_mode_outlined),
                value: context.watch<ThemeProvider>().dark,
                onChanged: (_) => theme.toggle(),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.download_rounded),
                title: const Text('Import sample menu (admin)'),
                subtitle: const Text(
                    'Writes categories and foods to Firestore'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await MenuService().importSampleMenu();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Sample menu imported')),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Import failed. Only admins can do this.')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Log Out')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await AuthService().signOut();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logout failed. Try again.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final initial =
        (user?.name.isNotEmpty == true ? user!.name[0] : 'J').toUpperCase();
    return Scaffold(
      body: ContentWidth(
        maxWidth: 640,
        child: ListView(
          padding: EdgeInsets.all(context.pagePadding),
          children: [
            const SizedBox(height: 8),
            Entrance(
              child: Row(
                children: [
                  const Spacer(),
                  IconButton(
                    onPressed: _settings,
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Settings',
                  ),
                ],
              ),
            ),
            Entrance(
              delay: const Duration(milliseconds: 60),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.primary, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: AppColors.tint,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'Customer',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Entrance(
              delay: const Duration(milliseconds: 120),
              child: Card(
                child: Column(
                  children: [
                    MenuTile(
                      icon: Icons.receipt_long_outlined,
                      title: 'My Orders',
                      onTap: () => Navigator.push(
                          context,
                          slideRoute(const OrdersScreen())),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    MenuTile(
                      icon: Icons.location_on_outlined,
                      title: 'Addresses',
                      onTap: () => Navigator.push(
                          context,
                          slideRoute(const AddressesScreen())),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    MenuTile(
                      icon: Icons.credit_card_outlined,
                      title: 'Payment Methods',
                      onTap: () => Navigator.push(
                          context,
                          slideRoute(const PaymentMethodsScreen())),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    MenuTile(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      onTap: _settings,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    MenuTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      onTap: () => Navigator.push(
                          context,
                          slideRoute(const HelpSupportScreen())),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Entrance(
              delay: const Duration(milliseconds: 180),
              child: Card(
                child: MenuTile(
                  icon: Icons.logout_rounded,
                  title: 'Log Out',
                  iconColor: AppColors.error,
                  titleColor: AppColors.error,
                  onTap: _logout,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text('JohnFood v1.0.0',
                  style: TextStyle(
                      color: AppColors.muted, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
