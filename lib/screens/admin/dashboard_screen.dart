import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../utils/formatters.dart';
import '../../utils/responsive.dart';
import '../../widgets/ui_kit.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ContentWidth(
        child: RefreshIndicator(
          onRefresh: () => admin.loadStats(),
          child: ListView(
            padding: EdgeInsets.all(context.pagePadding),
            children: [
              if (admin.loading) const LinearProgressIndicator(),
              Row(
                children: [
                  Expanded(child: _card('Today orders', '${admin.todayOrders}', Icons.receipt_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _card('Revenue', formatPeso(admin.todayRevenue), Icons.payments_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _card('Active', '${admin.activeOrders}', Icons.delivery_dining_rounded)),
                ],
              ),
              const SizedBox(height: 16),
              const SectionHeader(title: 'Top foods'),
              const SizedBox(height: 8),
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('foods')
                    .orderBy('rating', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox(height: 80);
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return const EmptyState(icon: Icons.fastfood_outlined, message: 'No foods yet.');
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < docs.length; i++)
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(milliseconds: 300 + i * 80),
                          builder: (context, v, child) => Opacity(
                            opacity: v,
                            child: Card(
                              child: ListTile(
                                leading: const Icon(Icons.fastfood_rounded),
                                title: Text('${docs[i].data()['name']}'),
                                trailing: Text('${((docs[i].data()['rating'] ?? 0) as num).toStringAsFixed(1)}'),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(String label, String value, IconData icon) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFFFF5722)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      );
}
