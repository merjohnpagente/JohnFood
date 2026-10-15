import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
import '../theme/motion.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../widgets/ui_kit.dart';
import 'food_detail_screen.dart';

/// Full menu list with rows like the design mockup.
class AllFoodsScreen extends StatefulWidget {
  const AllFoodsScreen({super.key});
  @override
  State<AllFoodsScreen> createState() => _AllFoodsScreenState();
}

class _AllFoodsScreenState extends State<AllFoodsScreen> {
  final _search = TextEditingController();

  /// Held directly so dispose can clear the shared filter without touching
  /// context, which is not safe once the element is being torn down.
  MenuProvider? _menu;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _menu = context.read<MenuProvider>();
  }

  @override
  void dispose() {
    _search.dispose();
    // Leaving a search term on the shared provider would keep the home tab
    // showing search results after the user navigates away.
    _menu?.onSearch('');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final pad = context.pagePadding;
    return Scaffold(
      appBar: AppBar(title: const Text('All Foods')),
      body: ContentWidth(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 12, pad, 4),
              child: SearchField(
                controller: _search,
                onChanged: (q) => menu.onSearch(q),
              ),
            ),
            Expanded(
              child: menu.loading
                  ? ListView.builder(
                      padding: EdgeInsets.all(pad),
                      itemCount: 6,
                      itemBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: ShimmerBox(height: 96, radius: 16),
                      ),
                    )
                  : menu.foods.isEmpty
                      ? const EmptyState(
                          icon: Icons.fastfood_rounded,
                          message: 'No food found.',
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(pad),
                          itemCount: menu.foods.length,
                          itemBuilder: (_, i) {
                            final f = menu.foods[i];
                            return Entrance(
                              delay: Duration(
                                  milliseconds: (i * 40).clamp(0, 320)),
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 12),
                                child: FoodRow(
                                  name: f.name,
                                  price: formatPeso(f.price),
                                  rating: f.rating,
                                  deliveryTime: f.deliveryTime,
                                  image: FoodImage(f.image),
                                  onTap: () => Navigator.push(
                                    context,
                                    slideRoute(
                                        FoodDetailScreen(foodId: f.id)),
                                  ),
                                  onAdd: () {
                                    context
                                        .read<CartProvider>()
                                        .add(f);
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              '${f.name} added to cart')),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
