import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../widgets/ui_kit.dart';
import 'all_foods_screen.dart';
import 'food_detail_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selected = 0;
  bool _hydrated = false;

  void _openDetail(BuildContext context, String foodId) {
    Navigator.push(
      context,
      slideRoute(FoodDetailScreen(foodId: foodId)),
    );
  }

  void _add(BuildContext context, dynamic f) {
    context.read<CartProvider>().add(f);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${f.name} added to cart')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final auth = context.watch<AuthProvider>();
    final pad = context.pagePadding;
    final uid = auth.user?.uid ?? '';
    final labels = ['All', ...menu.categories.map((c) => c.name)];
    final filtered = menu.selectedCategory.isEmpty
        ? menu.foods
        : menu.foods.where((f) => f.category == menu.selectedCategory).toList();
    final popular = [...menu.foods]
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final popularPicks = popular.take(6).toList();
    if (!_hydrated && menu.foods.isNotEmpty) {
      // Restore the saved cart once the menu is available.
      // Post-frame so notifyListeners never fires during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final done =
            context.read<CartProvider>().hydrate(menu.foods);
        if (done && mounted) setState(() => _hydrated = true);
      });
    }

    return Scaffold(
      body: ContentWidth(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, 16, pad, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'John Foods',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            'Good Food, Good Mood',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StreamBuilder(
                      stream: uid.isEmpty
                          ? const Stream.empty()
                          : NotificationService().watch(uid),
                      builder: (context, snap) {
                        final items = snap.data ?? [];
                        final unread =
                            items.where((n) => !n.read).isNotEmpty;
                        return Stack(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.push(
                                context,
                                slideRoute(
                                    const NotificationsScreen()),
                              ),
                              icon: const Icon(
                                  Icons.notifications_outlined,
                                  color: AppColors.ink),
                              tooltip: 'Notifications',
                            ),
                            if (unread)
                              Positioned(
                                right: 12,
                                top: 12,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
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
            if (menu.offline)
              const SliverToBoxAdapter(child: OfflineBanner()),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, 12, pad, 4),
                child: SearchField(onChanged: (q) => menu.onSearch(q)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: CategoryBar(
                  labels: labels,
                  selected: _selected,
                  onSelected: (i) {
                    setState(() => _selected = i);
                    menu.selectCategory(
                        i == 0 ? '' : menu.categories[i - 1].id);
                  },
                ),
              ),
            ),
            if (!menu.loading && popularPicks.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(pad, 8, pad, 0),
                  child: PromoCarousel(
                    slides: [
                      for (final f in popularPicks.take(3))
                        PromoSlide(
                          title: f.name,
                          subtitle:
                              '${formatPeso(f.price)}  •  ${f.rating.toStringAsFixed(1)} rating',
                          image: f.image,
                        ),
                    ],
                    onOrder: (i) =>
                        _openDetail(context, popularPicks[i].id),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, 16, pad, 4),
                child: SectionHeader(
                  title: 'Popular Picks',
                  action: 'See All →',
                  onAction: () => Navigator.push(
                    context,
                    slideRoute(const AllFoodsScreen()),
                  ),
                ),
              ),
            ),
            if (!menu.loading && popularPicks.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 252,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    itemCount: popularPicks.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final f = popularPicks[i];
                      return Entrance(
                        delay: Duration(
                            milliseconds: (i * 60).clamp(0, 300)),
                        child: SizedBox(
                          width: 168,
                          child: FoodCard(
                            name: f.name,
                            price: formatPeso(f.price),
                            rating: f.rating,
                            deliveryTime: f.deliveryTime,
                            image: SizedBox.expand(
                                child: FoodImage(f.image)),
                            onTap: () => _openDetail(context, f.id),
                            onAdd: () => _add(context, f),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, 16, pad, 4),
                child: const SectionHeader(title: 'Menu'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
            if (menu.loading)
              SliverPadding(
                padding: EdgeInsets.all(pad),
                sliver: SliverGrid(
                  gridDelegate: foodGridDelegate,
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    childCount: 6,
                  ),
                ),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.fastfood_rounded,
                  message: 'No food found.',
                  actionLabel: 'Browse menu',
                  onAction: () {
                    setState(() => _selected = 0);
                    menu.selectCategory('');
                  },
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 0, pad, pad),
                sliver: SliverGrid(
                  gridDelegate: foodGridDelegate,
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final f = filtered[i];
                      return Entrance(
                        delay: Duration(
                            milliseconds: (i * 40).clamp(0, 280)),
                        child: FoodCard(
                          name: f.name,
                          price: formatPeso(f.price),
                          rating: f.rating,
                          deliveryTime: f.deliveryTime,
                          image: SizedBox.expand(
                              child: FoodImage(f.image)),
                          onTap: () => _openDetail(context, f.id),
                          onAdd: () => _add(context, f),
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
