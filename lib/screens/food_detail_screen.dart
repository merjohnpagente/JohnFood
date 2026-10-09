import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../widgets/ui_kit.dart';

class FoodDetailScreen extends StatefulWidget {
  final String foodId;
  const FoodDetailScreen({super.key, required this.foodId});
  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  int _qty = 1;
  String _option = '';
  bool _fav = false;

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final food = menu.foods.where((f) => f.id == widget.foodId).isNotEmpty
        ? menu.foods.firstWhere((f) => f.id == widget.foodId)
        : null;
    if (food == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.fastfood_rounded, message: 'Food not found.'),
      );
    }
    final wide = context.isWide;
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(food.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text(formatPeso(food.price),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: -0.3)),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.tint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Text(food.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.timer_outlined, size: 16, color: AppColors.muted),
            const SizedBox(width: 4),
            Text(food.deliveryTime, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
        const SizedBox(height: 16),
        Text(food.description, style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.inkSecondary)),
        if (food.options.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in food.options)
                ChoiceChip(
                  label: Text(o),
                  selected: _option == o,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _option == o ? Colors.white : AppColors.ink,
                  ),
                  onSelected: (_) => setState(() => _option = o),
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: QuantityStepper(qty: _qty, onChanged: (q) => setState(() => _qty = q.clamp(1, 20))),
            ),
            const Spacer(),
            Material(
              color: _fav ? AppColors.error.withOpacity(0.1) : AppColors.canvas,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _fav = !_fav),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    _fav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                    color: _fav ? AppColors.error : AppColors.muted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      body: ContentWidth(
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      child: Hero(tag: 'food-${food.name}', child: FoodImage(food.image)),
                    ),
                  ),
                  Expanded(child: Padding(padding: const EdgeInsets.all(24), child: info)),
                ],
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: Hero(tag: 'food-${food.name}', child: FoodImage(food.image)),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(padding: const EdgeInsets.all(20), child: info),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: BottomActionBar(
        label: 'Add to cart',
        total: formatPeso(food.price * _qty),
        onPressed: () {
          context.read<CartProvider>().add(food, option: _option, qty: _qty);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${food.name} added to cart')),
          );
          Navigator.pop(context);
        },
      ),
    );
  }
}
