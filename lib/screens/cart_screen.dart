import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/promo_service.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../widgets/ui_kit.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _promo = TextEditingController();

  @override
  void dispose() {
    _promo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    if (cart.items.isEmpty) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.shopping_cart_outlined,
          message: 'Your cart is empty.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Clear cart?'),
                    content: const Text('Remove all items from your cart?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          cart.clear();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Clear'),
            ),
        ],
      ),
      body: ContentWidth(
        maxWidth: 640,
        child: ListView(
          padding: EdgeInsets.all(context.pagePadding),
          children: [
            for (final item in cart.items)
              Dismissible(
                key: ValueKey(item.key),
                direction: DismissDirection.endToStart,
                background: Container(
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete_rounded, color: Colors.white),
                ),
                onDismissed: (_) {
                  final removed = cart.remove(item.key);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item.food.name} removed'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          if (removed != null) cart.restore(removed);
                        },
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 72,
                            height: 72,
                            child: FoodImage(item.food.image),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.food.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatPeso(item.food.price),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (item.option.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.option,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            QuantityStepper(
                              qty: item.qty,
                              onChanged: (q) => cart.setQty(item.key, q),
                            ),
                            Text(
                              formatPeso(item.food.price * item.qty),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _promo,
                            decoration: const InputDecoration(
                              hintText: 'Promo code (try JOHN10)',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () async {
                            final d = await PromoService().preview(_promo.text, cart.subtotal);
                            cart.setDiscount(d, _promo.text.trim().toUpperCase());
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(d > 0 ? 'Promo applied' : 'Invalid code')),
                              );
                            }
                          },
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _row('Subtotal', formatPeso(cart.subtotal)),
                    const SizedBox(height: 8),
                    _row('Delivery', formatPeso(cart.deliveryFee)),
                    if (cart.discount > 0) ...[
                      const SizedBox(height: 8),
                      _row('Discount', '-${formatPeso(cart.discount)}', color: AppColors.success),
                    ],
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          formatPeso(cart.total),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        label: 'Checkout',
        total: formatPeso(cart.total),
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
      ),
    );
  }

  Widget _row(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
