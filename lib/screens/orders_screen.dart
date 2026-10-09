import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/providers.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../widgets/ui_kit.dart';
import 'tracking_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  String _watchingUid = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().user?.uid ?? '';
    final ordersP = context.watch<OrdersProvider>();
    if (uid.isNotEmpty && uid != _watchingUid) {
      _watchingUid = uid;
      ordersP.watch(uid);
    }
    final active = ordersP.active;
    final history = ordersP.history;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: TabBar(controller: _tab, tabs: const [
          Tab(text: 'Active'),
          Tab(text: 'History'),
        ]),
      ),
      body: ContentWidth(
        maxWidth: 640,
        child: TabBarView(
          controller: _tab,
          children: [
            _list(active, empty: 'No active orders.'),
            _list(history, empty: 'No past orders yet.', isHistory: true),
          ],
        ),
      ),
    );
  }

  Widget _list(List list, {required String empty, bool isHistory = false}) {
    if (list.isEmpty) {
      return EmptyState(icon: Icons.receipt_long_outlined, message: empty);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final o = list[i] as dynamic;
        final status = o.status as String;
        final id = o.id as String;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TrackingScreen(orderId: id)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Order #${id.length > 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase()}',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                      StatusChip(status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${(o.items as List).length} item(s)',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.muted),
                      ),
                      const Spacer(),
                      Text(
                        formatPeso((o.total as num).toDouble()),
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary),
                      ),
                    ],
                  ),
                  if (!isHistory && status == 'pending') ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => OrderService().cancelOrder(id),
                        child: const Text('Cancel order'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
