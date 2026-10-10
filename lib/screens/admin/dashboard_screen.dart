import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/motion.dart';
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
              if (admin.loading)
                const LinearProgressIndicator(),
              Row(
                children: [
                  Expanded(
                      child: Entrance(
                          child: _card('Today orders',
                              '${admin.todayOrders}', Icons.receipt_rounded))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Entrance(
                          delay: const Duration(milliseconds: 60),
                          child: _card(
                              'Revenue',
                              formatPeso(admin.todayRevenue),
                              Icons.payments_rounded))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Entrance(
                          delay: const Duration(milliseconds: 120),
                          child: _card(
                              'Active',
                              '${admin.activeOrders}',
                              Icons.delivery_dining_rounded))),
                ],
              ),
              const SizedBox(height: 20),
              const SectionHeader(title: 'Top foods'),
              const SizedBox(height: 8),
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('foods')
                    .orderBy('rating', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Column(
                      children: [
                        ShimmerBox(height: 64, radius: 16),
                        SizedBox(height: 8),
                        ShimmerBox(height: 64, radius: 16),
                        SizedBox(height: 8),
                        ShimmerBox(height: 64, radius: 16),
                      ],
                    );
                  }
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return const EmptyState(
                        icon: Icons.fastfood_outlined,
                        message: 'No foods yet.');
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < docs.length; i++)
                        Entrance(
                          delay: Duration(
                              milliseconds: (i * 60).clamp(0, 240)),
                          child: Card(
                            margin:
                                const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 4),
                              leading: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: const BoxDecoration(
                                      color: AppColors.tint,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                        Icons.fastfood_rounded,
                                        color: AppColors.primary,
                                        size: 22),
                                  ),
                                  if (i == 0)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding:
                                            const EdgeInsets.all(3),
                                        decoration:
                                            const BoxDecoration(
                                          color: AppColors.accent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                            Icons.star_rounded,
                                            size: 10,
                                            color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(
                                  '${docs[i].data()['name']}',
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight:
                                          FontWeight.w700)),
                              subtitle: Text(
                                  '#${i + 1} most loved',
                                  style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12)),
                              trailing: Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.tint,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                        Icons.star_rounded,
                                        size: 15,
                                        color: AppColors.accent),
                                    const SizedBox(width: 3),
                                    Text(
                                        '${((docs[i].data()['rating'] ?? 0) as num).toStringAsFixed(1)}',
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.w700)),
                                  ],
                                ),
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
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.all(
                    Radius.circular(12),
                  ),
                ),
                child: Icon(icon,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(height: 10),
              Text(value,
                  style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.muted, fontSize: 12)),
            ],
          ),
        ),
      );
}
