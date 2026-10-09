import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
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

    Widget heroImage({double? height}) => Hero(
          tag: 'food-${food.name}',
          child: FoodImage(food.image),
        );

    Widget overlayBtn({required IconData icon, required VoidCallback onTap}) =>
        Material(
          color: Colors.white.withOpacity(0.92),
          shape: const CircleBorder(),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.15),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Icon(icon, size: 20, color: AppColors.ink),
            ),
          ),
        );

    final imageHeader = Stack(
      children: [
        ClipRRect(
          borderRadius: wide
              ? const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                )
              : const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
          child: wide
              ? AspectRatio(aspectRatio: 1, child: heroImage())
              : AspectRatio(aspectRatio: 16 / 10, child: heroImage()),
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                overlayBtn(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.maybePop(context)),
                const Spacer(),
                overlayBtn(
                  icon: _fav
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  onTap: () => setState(() => _fav = !_fav),
                ),
                const SizedBox(width: 8),
                overlayBtn(
                  icon: Icons.share_outlined,
                  onTap: () => Share.share(
                    'Check out ${food.name} on John Foods for ${formatPeso(food.price)}!',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: ContentWidth(
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: imageHeader),
                  Expanded(
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: info)),
                ],
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: imageHeader),
                  SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.all(20), child: info),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEFE8E3))),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Row(
                children: [
                  QuantityStepper(
                      qty: _qty,
                      onChanged: (q) =>
                          setState(() => _qty = q.clamp(1, 20))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        context
                            .read<CartProvider>()
                            .add(food, option: _option, qty: _qty);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('${food.name} added to cart')),
                        );
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.shopping_cart_outlined,
                          size: 20),
                      label: Text(
                          'Add to Cart • ${formatPeso(food.price * _qty)}'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
