import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/motion.dart';
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
  static const _statuses = [
    '',
    'pending',
    'preparing',
    'on_the_way',
    'delivered',
    'cancelled'
  ];
  static const _labels = [
    'All',
    'Pending',
    'Preparing',
    'On the way',
    'Delivered',
    'Cancelled'
  ];

  String _label(String s) {
    final i = _statuses.indexOf(s);
    return i < 0 ? s : _labels[i];
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
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color:
                          on ? Colors.white : AppColors.ink,
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
                              DataCell(_actions(d)),
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
                                    _actions(d),
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

  Widget _actions(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    final uid = (m['userId'] ?? '') as String;
    final current = (m['status'] ?? '') as String;
    return Wrap(
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
                    ),
            child: Text(_label(s),
                style: const TextStyle(fontSize: 13)),
          ),
      ],
    );
  }
}
