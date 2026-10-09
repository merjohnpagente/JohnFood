import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../widgets/ui_kit.dart';
import 'food_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final auth = context.watch<AuthProvider>();
    final pad = context.pagePadding;
    final labels = ['All', ...menu.categories.map((c) => c.name)];
    final filtered = menu.selectedCategory.isEmpty
        ? menu.foods
        : menu.foods.where((f) => f.category == menu.selectedCategory).toList();

    return Scaffold(
      body: ContentWidth(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              expandedHeight: 120,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.only(left: pad, bottom: 16),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${auth.user?.name.isNotEmpty == true ? auth.user!.name : 'foodie'}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const Text(
                      'What would you like to eat?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (menu.offline)
              const SliverToBoxAdapter(child: OfflineBanner()),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, 8, pad, 12),
                child: SearchField(onChanged: (q) => menu.onSearch(q)),
              ),
            ),
            SliverToBoxAdapter(
              child: CategoryBar(
                labels: labels,
                selected: _selected,
                onSelected: (i) {
                  setState(() => _selected = i);
                  menu.selectCategory(i == 0 ? '' : menu.categories[i - 1].id);
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
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
                  onAction: () => menu.selectCategory(''),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.all(pad),
                sliver: SliverGrid(
                  gridDelegate: foodGridDelegate,
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final f = filtered[i];
                      return FoodCard(
                        name: f.name,
                        price: formatPeso(f.price),
                        rating: f.rating,
                        deliveryTime: f.deliveryTime,
                        image: SizedBox.expand(child: FoodImage(f.image)),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => FoodDetailScreen(foodId: f.id)),
                        ),
                        onAdd: () {
                          context.read<CartProvider>().add(f);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${f.name} added to cart')),
                          );
                        },
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
