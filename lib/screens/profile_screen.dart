import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/providers.dart';
import '../services/auth_service.dart';
import '../services/menu_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/ui_kit.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Pick up role changes (e.g. just promoted) without a restart.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final theme = context.watch<ThemeProvider>();
    return Scaffold(
      body: ContentWidth(
        maxWidth: 640,
        child: ListView(
          padding: EdgeInsets.all(context.pagePadding),
          children: [
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.tint,
                      child: Text(
                        (user?.name.isNotEmpty == true ? user!.name[0] : 'J').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
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
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Dark mode'),
                    secondary: const Icon(Icons.dark_mode_outlined),
                    value: theme.dark,
                    onChanged: (_) => theme.toggle(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text('Notifications'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.download_rounded),
                    title: const Text('Import sample menu (admin)'),
                    subtitle: const Text('Writes categories and foods to Firestore'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      try {
                        await MenuService().importSampleMenu();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sample menu imported')),
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
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                title: const Text('Logout'),
                onTap: () async {
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
                },
              ),
            ),
            const SizedBox(height: 32),
            const Center(
              child: Text('JohnFood v1.0.0',
                  style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
