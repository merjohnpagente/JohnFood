import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
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
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final n = items[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: n.read ? null : AppColors.tint.withOpacity(0.4),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: n.read ? AppColors.canvas : AppColors.tint,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        n.read
                            ? Icons.notifications_outlined
                            : Icons.notifications_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      n.title,
                      style: TextStyle(
                          fontWeight:
                              n.read ? FontWeight.w500 : FontWeight.w700),
                    ),
                    subtitle: Text(n.body,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!n.read)
                          Container(
                            width: 10,
                            height: 10,
                            margin:
                                const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.muted),
                      ],
                    ),
                    onTap: () =>
                        NotificationService().markRead(uid, n.id),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
