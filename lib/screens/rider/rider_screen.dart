import 'dart:async';
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
  DateTime _lastAutoWrite = DateTime.fromMillisecondsSinceEpoch(0);
  StreamSubscription<Position>? _posSub;
  bool _autoTrack = false;
  List<String> _activeIds = [];
  bool _busy = false;

  static const _statuses = [
    'assigned',
    'preparing',
    'on_the_way',
    'delivered',
    'cancelled',
  ];

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  /// Dropdown never crashes: unknown statuses fall back to a read-only chip.
  Widget _statusDropdown(String status, ValueChanged<String> onChanged) {
    if (!_statuses.contains(status)) return StatusChip(status);
    return DropdownButton<String>(
      value: status,
      items: const [
        DropdownMenuItem(value: 'assigned', child: Text('Assigned')),
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
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
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

  Future<void> _toggleAuto(bool on) async {
    setState(() => _autoTrack = on);
    if (!on) {
      await _posSub?.cancel();
      _posSub = null;
      return;
    }
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          setState(() => _autoTrack = false);
        }
        return;
      }
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
        ),
      ).listen((p) async {
        final now = DateTime.now();
        if (now.difference(_lastAutoWrite).inSeconds < 15) return;
        if (_activeIds.isEmpty) return;
        _lastAutoWrite = now;
        for (final id in _activeIds) {
          try {
            await OrderService()
                .updateRiderPosition(id, p.latitude, p.longitude);
          } catch (_) {
            // Best effort: one failing order must not stop the rest.
          }
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start auto tracking')),
        );
        setState(() => _autoTrack = false);
      }
    }
  }

  Future<void> _accept(String orderId, String customerId, String riderId) async {
    setState(() => _busy = true);
    try {
      await OrderService().acceptAssignment(
        orderId: orderId,
        customerId: customerId,
        riderId: riderId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Order accepted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Accept failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline(String orderId, String customerId) async {
    setState(() => _busy = true);
    try {
      await OrderService()
          .declineAssignment(orderId: orderId, customerId: customerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order declined, back to pending')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Decline failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _updateStatus(
      String orderId, String customerId, String riderId, String status) async {
    try {
      await OrderService().changeStatus(
        orderId: orderId,
        userId: customerId,
        status: status,
        riderId: riderId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Update failed: $e')));
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Auto', style: TextStyle(fontSize: 12)),
              Switch(
                value: _autoTrack,
                onChanged: _toggleAuto,
              ),
            ],
          ),
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
                await _posSub?.cancel();
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
            if (snap.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not load orders. Check connection.'),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            final docs = snap.data?.docs ?? [];
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // Keep auto-track list fresh for the position stream.
            _activeIds = docs
                .where((d) {
                  final s = (d.data()['status'] ?? '') as String;
                  return s == 'assigned' ||
                      s == 'preparing' ||
                      s == 'on_the_way';
                })
                .map((d) => d.id)
                .toList();
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
                final status = (m['status'] ?? 'pending') as String;
                final customerId = (m['userId'] ?? '') as String;
                final phone = (m['phone'] ?? '') as String;
                final isAssigned = status == 'assigned';
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                  'Order ${d.id.substring(0, d.id.length > 6 ? 6 : d.id.length)} - ${formatPeso(((m['total'] ?? 0) as num).toDouble())}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ),
                            StatusChip(status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${m['address'] ?? ''}',
                            style: const TextStyle(fontSize: 13)),
                        if (phone.isNotEmpty)
                          Text('Phone: $phone',
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 8),
                        if (isAssigned)
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _accept(d.id, customerId, uid),
                                  child: const Text('Accept'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _decline(d.id, customerId),
                                  child: const Text('Decline'),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.my_location_rounded),
                                tooltip: 'Share location',
                                onPressed: () => _share(d.id),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _statusDropdown(
                                  status,
                                  (v) => _updateStatus(
                                      d.id, customerId, uid, v),
                                ),
                              ),
                            ],
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
