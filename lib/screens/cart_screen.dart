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
      appBar: AppBar(title: const Text('Cart')),
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
                  color: const Color(0xFFC62828),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
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
                  child: ListTile(
                    leading: SizedBox(width: 56, height: 56, child: FoodImage(item.food.image)),
                    title: Text(item.food.name),
                    subtitle: Text(formatPeso(item.food.price)),
                    trailing: QuantityStepper(
                      qty: item.qty,
                      onChanged: (q) => cart.setQty(item.key, q),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promo,
                    decoration: const InputDecoration(hintText: 'Promo code (try JOHN10)'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
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
            const SizedBox(height: 12),
            Text('Subtotal: ${formatPeso(cart.subtotal)}'),
            Text('Delivery: ${formatPeso(cart.deliveryFee)}'),
            if (cart.discount > 0) Text('Discount: -${formatPeso(cart.discount)}'),
            Text('Total: ${formatPeso(cart.total)}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
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
}
