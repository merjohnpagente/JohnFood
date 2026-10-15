import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
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
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _assignSub;
  final Set<String> _seen = {};
  String _watchingUid = '';
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

  String _short(String id) =>
      id.length > 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase();

  /// Sort rank: work in progress first, finished orders last.
  int _rank(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    switch ((d.data()['status'] ?? '') as String) {
      case 'assigned':
        return 0;
      case 'preparing':
        return 1;
      case 'on_the_way':
        return 2;
      case 'delivered':
        return 4;
      default:
        return 3;
    }
  }

  /// Watches every order the admin has assigned to this rider and raises a
  /// local alert for new ones. Works without Cloud Functions because the
  /// rider's own document stream is the signal.
  void _watchAssignments(String uid) {
    _assignSub?.cancel();
    _seen.clear();
    _assignSub = FirebaseFirestore.instance
        .collection('orders')
        .where('riderId', isEqualTo: uid)
        .where('status', isEqualTo: 'assigned')
        .snapshots()
        .listen((s) {
      for (final d in s.docs) {
        if (_seen.add(d.id)) {
          if (_seen.length > 1) {
            // First entry is the initial load, not a new job.
            final m = d.data();
            final where = (m['address'] ?? '') as String;
            NotificationService().showLocal(
              'New order assigned',
              '${formatPeso(((m['total'] ?? 0) as num).toDouble())}  •  '
                  '${where.length > 60 ? '${where.substring(0, 60)}...' : where}',
            );
          }
        }
      }
    }, onError: (_) {/* offline: the list itself shows the error */});
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _assignSub?.cancel();
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

  Future<void> _accept(
      String orderId, String customerId, String riderId) async {
    setState(() => _busy = true);
    try {
      await OrderService().acceptAssignment(
        orderId: orderId,
        customerId: customerId,
        riderId: riderId,
      );
      // Start sharing location right away so the customer sees the rider.
      if (!_autoTrack) await _toggleAuto(true);
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

  Future<void> _deliver(
      String orderId, String customerId, String riderId) async {
    setState(() => _busy = true);
    try {
      await OrderService().changeStatus(
        orderId: orderId,
        userId: customerId,
        status: 'delivered',
        riderId: riderId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Marked as delivered')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Update failed: $e')));
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
    if (uid.isNotEmpty && uid != _watchingUid) {
      _watchingUid = uid;
      _watchAssignments(uid);
    }
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
            // New work first: active statuses above finished ones, then
            // newest first inside each group.
            final sorted = [...docs]..sort((a, b) {
                final rank = _rank(a) .compareTo(_rank(b));
                if (rank != 0) return rank;
                return (b.data()['createdAt'] as Timestamp?)
                        ?.compareTo(
                            a.data()['createdAt'] as Timestamp?) ??
                    0;
              });
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              itemBuilder: (_, i) {
                final d = sorted[i];
                final m = d.data();
                final status = (m['status'] ?? 'pending') as String;
                final customerId = (m['userId'] ?? '') as String;
                final phone = (m['phone'] ?? '') as String;
                final customerName =
                    (m['customerName'] ?? '').toString().trim();
                final isAssigned = status == 'assigned';
                final items = ((m['items'] ?? []) as List)
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList();
                final payable = m['paymentMethod'] == 'GCash' ||
                    m['paymentMethod'] == 'Maya';
                return Entrance(
                  delay:
                      Duration(milliseconds: (i * 50).clamp(0, 300)),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                    'Order ${_short(d.id)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800),
                                ),
                              ),
                              Text(
                                  formatPeso(((m['total'] ?? 0) as num)
                                      .toDouble()),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary)),
                              const SizedBox(width: 8),
                              StatusChip(status),
                            ],
                          ),
                          if (customerName.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.person_outline_rounded,
                                    size: 16, color: AppColors.muted),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(customerName,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                ),
                                if (payable)
                                  Text(
                                    m['paymentVerified'] == true
                                        ? 'Paid'
                                        : 'Verify first',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: m['paymentVerified'] == true
                                          ? AppColors.success
                                          : AppColors.warning,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 16, color: AppColors.muted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text('${m['address'] ?? ''}',
                                    style: const TextStyle(fontSize: 13)),
                              ),
                            ],
                          ),
                          if (phone.isNotEmpty)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.phone_outlined,
                                    size: 16, color: AppColors.muted),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(phone,
                                      style: const TextStyle(fontSize: 13)),
                                ),
                              ],
                            ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.canvas,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${items.length} item(s)',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.muted),
                                ),
                                const SizedBox(height: 4),
                                for (final it in items.take(5))
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 2),
                                    child: Text(
                                      '${(it['qty'] ?? 1)}x ${it['name'] ?? ''}${((it['option'] ?? '') as String).isEmpty ? '' : ' (${it['option']})'}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                if (items.length > 5)
                                  Text('+${items.length - 5} more',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.muted)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (isAssigned)
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _accept(
                                            d.id, customerId, uid),
                                    child: const Text('Accept order'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _decline(
                                            d.id, customerId),
                                    child: const Text('Decline'),
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.tonal(
                                    onPressed: () => _share(d.id),
                                    child: const Text('Share location'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _statusDropdown(
                                    status,
                                    (v) => _updateStatus(
                                        d.id, customerId, uid, v),
                                  ),
                                ),
                              ],
                            ),
                            if (status == 'on_the_way') ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () => _deliver(
                                          d.id, customerId, uid),
                                  icon: const Icon(
                                      Icons.check_circle_rounded,
                                      size: 18,
                                      color: AppColors.onPrimary),
                                  label: const Text('Mark as delivered'),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
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
