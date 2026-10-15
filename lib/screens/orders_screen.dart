import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/providers.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../widgets/ui_kit.dart';
import 'all_foods_screen.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelColor: AppColors.muted,
          tabs: [
            Tab(text: 'Active${ordersP.active.isEmpty ? '' : ' (${ordersP.active.length})'}'),
            const Tab(text: 'History'),
          ],
        ),
      ),
      body: ContentWidth(
        maxWidth: 640,
        child: TabBarView(
          controller: _tab,
          children: [
            _list(ordersP.active,
                empty: 'No active orders.', isHistory: false),
            _list(ordersP.history, empty: 'No past orders yet.', isHistory: true),
          ],
        ),
      ),
    );
  }

  Widget _list(List list, {required String empty, bool isHistory = false}) {
    if (list.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        message: empty,
        actionLabel: 'Browse Menu',
        onAction: () => Navigator.push(
          context,
          slideRoute(const AllFoodsScreen()),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final o = list[i];
        final status = o.status as String;
        final id = o.id as String;
        final items = o.items as List;
        return Entrance(
          delay: Duration(milliseconds: (i * 40).clamp(0, 280)),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.card),
              onTap: () => Navigator.push(
                context,
                slideRoute(TrackingScreen(orderId: id)),
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
                    if (items.isNotEmpty)
                      Text(
                        items
                            .take(2)
                            .map((e) => '${(e as dynamic).qty}x ${e.name}')
                            .join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.inkSecondary),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${items.length} item(s)',
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
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Cancel order?'),
                                content: const Text(
                                    'This cannot be undone once the kitchen '
                                    'already started.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Keep order'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.error),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Cancel order'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) {
                              await OrderService().cancelOrder(id);
                            }
                          },
                          child: const Text('Cancel order'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}