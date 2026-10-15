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
          onRefresh: () => admin.loadStats(force: true),
          child: ListView(
            padding: EdgeInsets.all(context.pagePadding),
            children: [
              if (admin.loading)
                const LinearProgressIndicator(),
              Row(
                children: [
                  Expanded(
                      child: Entrance(
                          child: _statCard(
                              'Today orders',
                              admin.todayOrders.toDouble(),
                              Icons.receipt_rounded))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Entrance(
                          delay: const Duration(milliseconds: 60),
                          child: _statCard(
                              'Today revenue',
                              admin.todayRevenue,
                              Icons.payments_rounded,
                              isMoney: true))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Entrance(
                          delay: const Duration(milliseconds: 120),
                          child: _statCard(
                              'Active',
                              admin.activeOrders.toDouble(),
                              Icons.delivery_dining_rounded))),
                ],
              ),
              const SizedBox(height: 20),
              const SectionHeader(title: 'Revenue'),
              const SizedBox(height: 8),
              Entrance(
                delay: const Duration(milliseconds: 180),
                child: _revenueCard(
                  'This Month',
                  admin.monthRevenue,
                  Icons.calendar_month_rounded,
                  share: admin.shareOf(admin.monthRevenue),
                ),
              ),
              const SizedBox(height: 10),
              Entrance(
                delay: const Duration(milliseconds: 240),
                child: _revenueCard(
                  'This Year',
                  admin.yearRevenue,
                  Icons.date_range_rounded,
                  share: admin.shareOf(admin.yearRevenue),
                ),
              ),
              const SizedBox(height: 10),
              Entrance(
                delay: const Duration(milliseconds: 300),
                child: _revenueCard(
                  'Overall',
                  admin.overallRevenue,
                  Icons.account_balance_wallet_rounded,
                ),
              ),
              const SizedBox(height: 20),
              const SectionHeader(title: 'Top sellers'),
              const SizedBox(height: 8),
              _topSellers(admin),
              const SizedBox(height: 20),
              const SectionHeader(title: 'Best rated'),
              const SizedBox(height: 8),
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('foods')
                    .where('ratingCount', isGreaterThan: 0)
                    .orderBy('rating', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
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
                  final docs = snap.data?.docs ?? const [];
                  if (docs.isEmpty) {
                    return const EmptyState(
                        icon: Icons.star_outline_rounded,
                        message: 'No ratings yet. Reviews will show up here.');
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < docs.length; i++)
                        _rankRow(
                          rank: i + 1,
                          name: '${docs[i].data()['name']}',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 15, color: AppColors.accent),
                              const SizedBox(width: 3),
                              Text(
                                '${((docs[i].data()['rating'] ?? 0) as num).toStringAsFixed(1)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          subtitle:
                              '${((docs[i].data()['ratingCount'] ?? 0) as num).toInt()} review(s)',
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

  /// Real sales ranking, computed from the orders that were placed.
  Widget _topSellers(AdminProvider admin) {
    final entries = admin.topSales.entries.toList()
      ..sort((a, b) =>
          ((b.value['revenue'] ?? 0.0) as double)
              .compareTo((a.value['revenue'] ?? 0.0) as double));
    if (entries.isEmpty) {
      return const EmptyState(
          icon: Icons.insights_outlined,
          message: 'No sales yet.');
    }
    final top = entries.take(5).toList();
    final maxRev =
        ((top.first.value['revenue'] ?? 0.0) as double).clamp(0.0001, double.infinity);
    return Column(
      children: [
        for (var i = 0; i < top.length; i++)
          _rankRow(
            rank: i + 1,
            name: '${top[i].value['name']}',
            subtitle:
                '${top[i].value['qty']} sold  •  ${formatPeso(top[i].value['revenue'] ?? 0.0)}',
            bar: ((top[i].value['revenue'] ?? 0.0) as double) / maxRev,
            trailing: Text(
              '#${i + 1}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: i == 0 ? AppColors.accent : AppColors.muted,
              ),
            ),
          ),
      ],
    );
  }

  Widget _rankRow({
    required int rank,
    required String name,
    required Widget trailing,
    String? subtitle,
    double? bar,
  }) =>
      Entrance(
        delay: Duration(milliseconds: (rank * 50).clamp(0, 240)),
        child: Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: rank == 1 ? AppColors.accent : AppColors.tint,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: rank == 1
                          ? AppColors.onPrimary
                          : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12),
                        ),
                      if (bar != null) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: bar.clamp(0, 1)),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, __) => LinearProgressIndicator(
                              value: v,
                              minHeight: 5,
                              backgroundColor: AppColors.shimmer,
                              valueColor: const AlwaysStoppedAnimation(
                                  AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing,
              ],
            ),
          ),
        ),
      );

/// Small stat tile. Both money and counts animate from zero on load.
  Widget _statCard(
    String label,
    double value,
    IconData icon, {
    bool isMoney = false,
  }) =>
      Card(
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
                child: Icon(icon, color: AppColors.onPrimary, size: 20),
              ),
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Text(
                  isMoney ? formatPeso(v) : v.round().toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3),
                ),
              ),
              const SizedBox(height: 2),
              Text(label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.muted, fontSize: 12)),
            ],
          ),
        ),
      );

  /// Full-width revenue row: animated count-up plus a share bar
  /// showing how much of the overall total this bucket represents.
  Widget _revenueCard(
    String label,
    double value,
    IconData icon, {
    double share = 0,
  }) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
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
                    Radius.circular(14),
                  ),
                ),
                child: Icon(icon, color: AppColors.onPrimary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                    const SizedBox(height: 2),
                    _CountUp(
                      value: value,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3),
                    ),
                    if (share > 0) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: share.clamp(0, 1)),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => LinearProgressIndicator(
                            value: v,
                            minHeight: 6,
                            backgroundColor: AppColors.shimmer,
                            valueColor:
                                const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (share > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    '${(share * 100).toStringAsFixed(share < 0.1 ? 1 : 0)}%',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted),
                  ),
                ),
            ],
          ),
        ),
      );
}

/// Animated count-up number for revenue figures.
class _CountUp extends StatelessWidget {
  final double value;
  final TextStyle style;
  const _CountUp({required this.value, required this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(formatPeso(v), style: style),
    );
  }
}
