import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/providers.dart';
import '../services/auth_service.dart';
import '../services/menu_service.dart';
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
      appBar: AppBar(title: const Text('Profile')),
      body: ContentWidth(
        maxWidth: 640,
        child: ListView(
          padding: EdgeInsets.all(context.pagePadding),
          children: [
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text((user?.name.isNotEmpty == true ? user!.name[0] : 'J').toUpperCase()),
                ),
                title: Text(user?.name ?? 'Customer'),
                subtitle: Text(user?.email ?? ''),
              ),
            ),
            SwitchListTile(
              title: const Text('Dark mode'),
              value: theme.dark,
              onChanged: (_) => theme.toggle(),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.download_rounded),
              title: const Text('Import sample menu (admin)'),
              subtitle: const Text('Writes categories and foods to Firestore'),
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
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Logout'),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Logout?'),
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
            const SizedBox(height: 24),
            const Center(
              child: Text('By MerjDev',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
