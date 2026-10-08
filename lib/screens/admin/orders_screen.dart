import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/order_service.dart';
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
  static const _statuses = ['', 'pending', 'preparing', 'on_the_way', 'delivered', 'cancelled'];

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> q =
        FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).limit(20);
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  for (final s in _statuses)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(s.isEmpty ? 'All' : s),
                        selected: _filter == s,
                        onSelected: (_) => setState(() => _filter = s),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: q.snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const EmptyState(icon: Icons.receipt_long_outlined, message: 'No orders.');
                  }
                  final wide = context.isDesktop;
                  if (wide) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
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
                              DataCell(Text(d.id.substring(0, 6))),
                              DataCell(Text(formatPeso(((d.data()['total'] ?? 0) as num).toDouble()))),
                              DataCell(StatusChip((d.data()['status'] ?? '') as String)),
                              DataCell(_actions(d)),
                            ]),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i];
                      final m = d.data();
                      return Card(
                        child: ListTile(
                          title: Text('Order ${d.id.substring(0, 6)} - ${formatPeso(((m['total'] ?? 0) as num).toDouble())}'),
                          subtitle: Text((m['address'] ?? '') as String),
                          trailing: StatusChip((m['status'] ?? '') as String),
                          onTap: () => showModalBottomSheet(
                            context: context,
                            builder: (_) => Padding(
                              padding: const EdgeInsets.all(16),
                              child: _actions(d),
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
    return Wrap(
      spacing: 8,
      children: [
        for (final s in ['preparing', 'on_the_way', 'delivered', 'cancelled'])
          ElevatedButton(
            onPressed: () => OrderService().changeStatus(
              orderId: d.id,
              userId: uid,
              status: s,
            ),
            child: Text(s),
          ),
      ],
    );
  }
}
