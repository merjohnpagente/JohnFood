import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/image_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/motion.dart';
import '../../utils/error_mapper.dart';
import '../../utils/formatters.dart';
import '../../utils/responsive.dart';
import '../../widgets/ui_kit.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});
  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _filter = '';
  Map<String, String?> _riderPick = {};

  /// One rider subscription for the whole screen. Creating the stream inside
  /// each order row spawned one Firestore listener per row.
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ridersSub;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _riders = [];

  static const _statuses = [
    '',
    'pending',
    'assigned',
    'preparing',
    'on_the_way',
    'delivered',
    'cancelled'
  ];
  static const _labels = [
    'All',
    'Pending',
    'Assigned',
    'Preparing',
    'On the way',
    'Delivered',
    'Cancelled'
  ];

  /// Statuses that mean the rider is still working on the order.
  static const _activeStatuses = {
    'assigned',
    'preparing',
    'on_the_way',
  };

  @override
  void initState() {
    super.initState();
    _ridersSub = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'rider')
        .limit(50)
        .snapshots()
        .listen((s) {
      if (mounted) setState(() => _riders = s.docs);
    });
  }

  @override
  void dispose() {
    _ridersSub?.cancel();
    super.dispose();
  }

  String _label(String s) {
    final i = _statuses.indexOf(s);
    return i < 0 ? s : _labels[i];
  }

  String _short(String id) =>
      id.length > 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase();

  /// How many active orders each rider is carrying (from the loaded page).
  Map<String, int> _busyCounts(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final counts = <String, int>{};
    for (final d in docs) {
      final m = d.data();
      final r = (m['riderId'] as String?) ?? '';
      final s = (m['status'] ?? '') as String;
      if (r.isEmpty || !_activeStatuses.contains(s)) continue;
      counts[r] = (counts[r] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(20);
    if (_filter.isNotEmpty) {
      q = FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: _filter)
          .orderBy('createdAt', descending: true)
          .limit(20);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: ContentWidth(
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                itemCount: _statuses.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final s = _statuses[i];
                  final on = _filter == s;
                  return ChoiceChip(
                    label: Text(_label(s)),
                    selected: on,
                    showCheckmark: false,
                    onSelected: (_) =>
                        setState(() => _filter = s),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color:
                          on ? AppColors.onPrimary : AppColors.ink,
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: q.snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState ==
                      ConnectionState.waiting) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 4,
                      itemBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: ShimmerBox(height: 84, radius: 16),
                      ),
                    );
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        message: 'No orders.');
                  }
                  final busy = _busyCounts(docs);
                  final wide = context.isDesktop;
                  if (wide) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(16),
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Order')),
                          DataColumn(label: Text('Total')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: [
                          for (final d in docs)
                            DataRow(cells: [
                              DataCell(Text(d.id.substring(
                                  0,
                                  d.id.length > 6
                                      ? 6
                                      : d.id.length))),
                              DataCell(Text(formatPeso(
                                  ((d.data()['total'] ?? 0)
                                          as num)
                                      .toDouble()))),
                              DataCell(StatusChip(
                                  (d.data()['status'] ?? '')
                                      as String)),
                              DataCell(_actions(d, busy)),
                            ]),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i];
                      final m = d.data();
                      return Entrance(
                        delay: Duration(
                            milliseconds:
                                (i * 40).clamp(0, 320)),
                        child: Card(
                          margin: const EdgeInsets.only(
                              bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                                AppRadius.card),
                            onTap: () => showModalBottomSheet(
                              context: context,
                              shape:
                                  const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.vertical(
                                        top: Radius.circular(
                                            20)),
                              ),
                              builder: (_) => Padding(
                                padding:
                                    const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize:
                                      MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Order #${d.id.length > 6 ? d.id.substring(0, 6).toUpperCase() : d.id.toUpperCase()}',
                                        style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight:
                                                FontWeight.w800)),
                                    const SizedBox(height: 4),
                                    Text(
                                        (m['address'] ?? '')
                                            as String,
                                        style: const TextStyle(
                                            color: AppColors
                                                .muted)),
                                    const SizedBox(height: 12),
                                    _actions(d, busy),
                                  ],
                                ),
                              ),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Order #${d.id.length > 6 ? d.id.substring(0, 6).toUpperCase() : d.id.toUpperCase()}',
                                          style: const TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .w700),
                                        ),
                                      ),
                                      StatusChip(
                                          (m['status'] ?? '')
                                              as String),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          (m['address'] ?? '')
                                              as String,
                                          maxLines: 1,
                                          overflow: TextOverflow
                                              .ellipsis,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors
                                                  .muted),
                                        ),
                                      ),
                                      Text(
                                        formatPeso(((m['total'] ??
                                                    0)
                                                as num)
                                            .toDouble()),
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.w800,
                                            color: AppColors
                                                .primary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions(
    QueryDocumentSnapshot<Map<String, dynamic>> d,
    Map<String, int> busy,
  ) {
    final m = d.data();
    final uid = (m['userId'] ?? '') as String;
    final current = (m['status'] ?? '') as String;
    final currentRider = (m['riderId'] as String?) ?? '';
    final phone = (m['phone'] ?? '') as String;
    final payMethod = (m['paymentMethod'] ?? 'Cash on delivery') as String;
    final payRef = (m['paymentRef'] ?? '') as String;
    final payProof = (m['paymentProofUrl'] ?? '') as String;
    final payVerified = (m['paymentVerified'] ?? false) as bool;
    final needsVerify = (payMethod == 'GCash' || payMethod == 'Maya') &&
        !payVerified &&
        (current == 'pending' || current == 'assigned');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text('Pay: $payMethod${payVerified ? ' (verified)' : ''}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink)),
        ),
        if (payRef.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Ref: $payRef',
                style:
                    const TextStyle(fontSize: 13, color: AppColors.muted)),
          ),
        if (needsVerify) ...[
          _proofView(payProof, d.id),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: () => OrderService().verifyPayment(
                  orderId: d.id,
                  customerId: uid,
                  verified: true,
                ),
                child:
                    const Text('Verify', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => OrderService().verifyPayment(
                  orderId: d.id,
                  customerId: uid,
                  verified: false,
                ),
                child:
                    const Text('Reject', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Verify payment before assigning a rider.',
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 8),
        ],
        if (phone.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Phone: $phone',
                style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          ),
        if (currentRider.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Rider: ${_riderName(currentRider)}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.inkSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () => _unassign(d.id, uid),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Unassign',
                      style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
        _assignRow(d, uid, currentRider, busy),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in [
              'preparing',
              'on_the_way',
              'delivered',
              'cancelled'
            ])
              FilledButton.tonal(
                onPressed: s == current
                    ? null
                    : () => OrderService().changeStatus(
                          orderId: d.id,
                          userId: uid,
                          status: s,
                          riderId: _riderPick[d.id] ?? (currentRider.isEmpty ? null : currentRider),
                        ),
                child: Text(_label(s),
                    style: const TextStyle(fontSize: 13)),
              ),
          ],
        ),
      ],
    );
  }

  /// Rider picker shared by every row. Shows who is free and who is
  /// already carrying orders so the admin can assign deliberately.
  Widget _assignRow(
    QueryDocumentSnapshot<Map<String, dynamic>> d,
    String uid,
    String currentRider,
    Map<String, int> busy,
  ) {
    if (_riders.isEmpty) {
      return const Text('No riders yet. Add one in the Users tab.',
          style: TextStyle(fontSize: 13, color: AppColors.muted));
    }
    final picked = _riderPick[d.id] ?? currentRider;
    final pickedBusy = busy[picked] ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _riders.any((r) => r.id == picked) ? picked : null,
                hint: const Text('Select rider',
                    style: TextStyle(fontSize: 13)),
                items: [
                  for (final r in _riders)
                    () {
                      final rid = r.id;
                      final name = '${r.data()['name'] ?? 'Rider'}';
                      final n = busy[rid] ?? 0;
                      return DropdownMenuItem(
                        value: rid,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13)),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              n == 0 ? 'Free' : 'Busy ($n)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: n == 0
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      );
                    }(),
                ],
                onChanged: (v) => setState(() => _riderPick[d.id] = v),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: (picked.isEmpty || picked == currentRider)
                  ? null
                  : () => OrderService().changeStatus(
                        orderId: d.id,
                        userId: uid,
                        status: 'assigned',
                        riderId: picked,
                      ),
              child: Text(currentRider.isEmpty ? 'Assign' : 'Reassign',
                  style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        if (picked.isNotEmpty && pickedBusy > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              pickedBusy > 1
                  ? 'This rider already has $pickedBusy active orders.'
                  : 'This rider has 1 active order.',
              style:
                  const TextStyle(fontSize: 11, color: AppColors.warning),
            ),
          ),
      ],
    );
  }

  String _riderName(String riderId) {
    for (final r in _riders) {
      if (r.id == riderId) return '${r.data()['name'] ?? 'Rider'}';
    }
    return 'Unknown';
  }

  Future<void> _unassign(String orderId, String customerId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unassign rider?'),
        content: const Text(
            'The order goes back to pending so you can pick another rider.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unassign'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await OrderService()
          .declineAssignment(orderId: orderId, customerId: customerId);
      _riderPick.remove(orderId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not unassign: ${friendlyError(e)}')),
      );
    }
  }

  Widget _proofView(String url, String orderId) {
    if (url.isEmpty) {
      return const Text('No proof attached yet.',
          style: TextStyle(fontSize: 13, color: AppColors.error));
    }
    if (url.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(url,
            height: 140, fit: BoxFit.cover, errorBuilder: (_, __, ___) =>
                const Text('Could not load proof.',
                    style: TextStyle(fontSize: 13))),
      );
    }
    return FutureBuilder<String?>(
      future: ImageService().cachedProof(orderId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 60, child: Center(child: CircularProgressIndicator()));
        }
        final b64 = snap.data;
        if (b64 == null || b64.isEmpty) {
          return const Text('Could not load proof.',
              style: TextStyle(fontSize: 13));
        }
        try {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(base64Decode(b64),
                height: 140, fit: BoxFit.cover),
          );
        } catch (_) {
          return const Text('Could not load proof.',
              style: TextStyle(fontSize: 13));
        }
      },
    );
  }
}
