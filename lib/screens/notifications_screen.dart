import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../utils/responsive.dart';
import '../widgets/ui_kit.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().user?.uid ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ContentWidth(
        maxWidth: 640,
        child: StreamBuilder(
          stream: NotificationService().watch(uid),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return const EmptyState(
                  icon: Icons.notifications_outlined,
                  message: 'No notifications yet.');
            }
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) => Card(
                child: ListTile(
                  leading: Icon(
                    items[i].read
                        ? Icons.notifications_outlined
                        : Icons.notifications_rounded,
                  ),
                  title: Text(items[i].title),
                  subtitle: Text(items[i].body),
                  onTap: () =>
                      NotificationService().markRead(uid, items[i].id),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
