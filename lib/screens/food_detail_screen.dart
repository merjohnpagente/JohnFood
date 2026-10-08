import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
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
        Text(food.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(formatPeso(food.price),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFFF5722))),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFB300)),
            Text(' ${food.rating.toStringAsFixed(1)}  '),
            const Icon(Icons.timer_outlined, size: 16),
            Text(' ${food.deliveryTime}'),
          ],
        ),
        const SizedBox(height: 12),
        Text(food.description),
        if (food.options.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Options', style: TextStyle(fontWeight: FontWeight.w700)),
          Wrap(
            spacing: 8,
            children: [
              for (final o in food.options)
                ChoiceChip(
                  label: Text(o),
                  selected: _option == o,
                  onSelected: (_) => setState(() => _option = o),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            QuantityStepper(qty: _qty, onChanged: (q) => setState(() => _qty = q.clamp(1, 20))),
            const Spacer(),
            IconButton(
              onPressed: () => setState(() => _fav = !_fav),
              icon: Icon(_fav ? Icons.favorite_rounded : Icons.favorite_outline_rounded),
              color: const Color(0xFFFF5722),
              tooltip: 'Favorite',
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text(food.name)),
      body: ContentWidth(
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Hero(tag: 'food-${food.name}', child: FoodImage(food.image))),
                  Expanded(child: Padding(padding: const EdgeInsets.all(24), child: info)),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(tag: 'food-${food.name}', child: FoodImage(food.image)),
                    Padding(padding: const EdgeInsets.all(16), child: info),
                  ],
                ),
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
