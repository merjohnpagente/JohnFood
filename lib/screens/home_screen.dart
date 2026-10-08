import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
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
      appBar: AppBar(
        title: Text('Hello, ${auth.user?.name.isNotEmpty == true ? auth.user!.name : 'foodie'}'),
      ),
      body: ContentWidth(
        child: Column(
          children: [
            if (menu.offline) const OfflineBanner(),
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 8, pad, 12),
              child: SearchField(onChanged: (q) => menu.onSearch(q)),
            ),
            CategoryBar(
              labels: labels,
              selected: _selected,
              onSelected: (i) {
                setState(() => _selected = i);
                menu.selectCategory(i == 0 ? '' : menu.categories[i - 1].id);
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => menu.selectCategory(menu.selectedCategory),
                child: menu.loading
                    ? const SkeletonLoader()
                    : filtered.isEmpty
                        ? EmptyState(
                            icon: Icons.fastfood_rounded,
                            message: 'No food found.',
                            actionLabel: 'Browse menu',
                            onAction: () => menu.selectCategory(''),
                          )
                        : GridView.builder(
                            padding: EdgeInsets.all(pad),
                            gridDelegate: foodGridDelegate,
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
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
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
