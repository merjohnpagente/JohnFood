import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../utils/formatters.dart';
import '../../utils/responsive.dart';
import '../../widgets/ui_kit.dart';

class RiderScreen extends StatefulWidget {
  const RiderScreen({super.key});
  @override
  State<RiderScreen> createState() => _RiderScreenState();
}

class _RiderScreenState extends State<RiderScreen> {
  DateTime _lastWrite = DateTime.fromMillisecondsSinceEpoch(0);

  static const _statuses = [
    'pending',
    'preparing',
    'on_the_way',
    'delivered',
    'cancelled',
  ];

  /// Dropdown never crashes: unknown statuses fall back to a read-only chip.
  Widget _statusDropdown(String status, ValueChanged<String> onChanged) {
    if (!_statuses.contains(status)) return StatusChip(status);
    return DropdownButton<String>(
      value: status,
      items: const [
        DropdownMenuItem(value: 'pending', child: Text('Pending')),
        DropdownMenuItem(value: 'preparing', child: Text('Preparing')),
        DropdownMenuItem(value: 'on_the_way', child: Text('On the way')),
        DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
        DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
      ],
      onChanged: (v) {
        if (v == null) return;
        onChanged(v);
      },
    );
  }

  Future<void> _share(String orderId) async {
    final now = DateTime.now();
    if (now.difference(_lastWrite).inSeconds < 10) return;
    _lastWrite = now;
    try {
      final p = await Geolocator.getCurrentPosition();
      await OrderService().updateRiderPosition(orderId, p.latitude, p.longitude);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Location shared')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not get location. Check permission and retry.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().user?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Logout?'),
                  content:
                      const Text('Are you sure you want to logout?'),
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
        ],
      ),
      body: ContentWidth(
        maxWidth: 640,
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('riderId', isEqualTo: uid)
              .orderBy('createdAt', descending: true)
              .limit(20)
              .snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (docs.isEmpty) {
              return const EmptyState(
                  icon: Icons.delivery_dining_outlined,
                  message: 'No assigned orders.');
            }
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final d = docs[i];
                final m = d.data();
                return Card(
                  child: ListTile(
                    title: Text('Order ${d.id.substring(0, 6)} - ${formatPeso(((m['total'] ?? 0) as num).toDouble())}'),
                    subtitle: Text('${m['address']} • ${m['status']}'),
                    trailing: Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.my_location_rounded),
                          tooltip: 'Share location',
                          onPressed: () => _share(d.id),
                        ),
                        _statusDropdown(
                          (m['status'] ?? 'pending') as String,
                          (v) => OrderService().changeStatus(
                            orderId: d.id,
                            userId: (m['userId'] ?? '') as String,
                            status: v,
                            riderId: uid,
                          ),
                        ),
                      ],
                    ),
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
