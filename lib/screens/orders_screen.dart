import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/providers.dart';
import '../services/order_service.dart';
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
        return Card(
          child: ListTile(
            title: Text('Order ${o.id.substring(0, 6)}'),
            subtitle: Text('${formatPeso(o.total)}  •  ${o.status}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusChip(o.status as String),
                if (!isHistory && (o.status as String) == 'pending')
                  TextButton(
                    onPressed: () => OrderService().cancelOrder(o.id as String),
                    child: const Text('Cancel'),
                  ),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TrackingScreen(orderId: o.id as String)),
            ),
          ),
        );
      },
    );
  }
}
