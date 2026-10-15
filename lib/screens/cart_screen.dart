import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/promo.dart';
import '../providers/cart_provider.dart';
import '../services/promo_service.dart';
import '../theme/app_theme.dart';
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
  String? _promoError;
  String? _promoApplied;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _promoApplied = context.read<CartProvider>().promoCode;
  }

  @override
  void dispose() {
    _promo.dispose();
    super.dispose();
  }

  Future<void> _applyPromo(CartProvider cart) async {
    final code = _promo.text.trim();
    if (code.isEmpty) {
      cart.setDiscount(0, '');
      setState(() {
        _promoError = null;
        _promoApplied = null;
      });
      return;
    }
    setState(() => _checking = true);
    final service = PromoService();
    final discount = await service.preview(
      code,
      cart.subtotal,
      deliveryFee: cart.deliveryFee,
    );
    final problem =
        await service.previewMessage(code, cart.subtotal, deliveryFee: cart.deliveryFee);
    if (!mounted) return;
    setState(() => _checking = false);
    if (discount > 0) {
      cart.setDiscount(discount, code.toUpperCase());
      setState(() {
        _promoError = null;
        _promoApplied = code.toUpperCase();
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Promo applied')));
    } else {
      cart.setDiscount(0, '');
      setState(() {
        _promoError = problem ?? 'That code is not valid.';
        _promoApplied = null;
      });
    }
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
                        setState(() {
                          _promo.clear();
                          _promoApplied = null;
                          _promoError = null;
                        });
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
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.delivery_dining_rounded,
                      color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Free delivery for orders',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        Text(
                          'above ${formatPeso(500)}!',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  if (cart.subtotal >= 500)
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.success)
                  else
                    Text(
                      '${formatPeso(500 - cart.subtotal)} to go',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted),
                    ),
                ],
              ),
            ),
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
                  child: const Icon(Icons.delete_rounded,
                      color: AppColors.onPrimary),
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
                              if (item.selectedOption.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.selectedOption,
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
                              onChanged: (q) {
                                cart.setQty(item.key, q);
                                // Re-validate the promo against the new total.
                                if (_promoApplied != null) {
                                  _applyPromo(cart);
                                }
                              },
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
                    StreamBuilder<List<Promo>>(
                      stream: PromoService().watchActive(),
                      builder: (context, snap) {
                        final promos = snap.data ?? const [];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _promo,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    decoration: InputDecoration(
                                      hintText: _promoApplied != null
                                          ? '$_promoApplied applied'
                                          : 'Promo code',
                                      isDense: true,
                                      prefixIcon: Icon(
                                        Icons.local_offer_outlined,
                                        size: 18,
                                        color: _promoError != null
                                            ? AppColors.error
                                            : AppColors.muted,
                                      ),
                                    ),
                                    onSubmitted: (_) => _applyPromo(cart),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed:
                                      _checking ? null : () => _applyPromo(cart),
                                  child: _checking
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.onPrimary),
                                        )
                                      : Text(
                                          _promoApplied != null ? 'Change' : 'Apply'),
                                ),
                              ],
                            ),
                            if (_promoError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded,
                                        size: 14, color: AppColors.error),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _promoError!,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.error),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (promos.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const Text(
                                'Available codes',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.muted),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  for (final p in promos.take(6))
                                    ActionChip(
                                      label: Text(
                                        '${p.code} ${_promoTag(p)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      onPressed: () {
                                        _promo.text = p.code;
                                        _applyPromo(cart);
                                      },
                                    ),
                                ],
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    const Divider(height: 24),
                    _row('Subtotal', formatPeso(cart.subtotal)),
                    const SizedBox(height: 8),
                    _row(
                      'Delivery',
                      cart.deliveryFee == 0
                          ? 'Free'
                          : formatPeso(cart.deliveryFee),
                    ),
                    if (cart.discount > 0) ...[
                      const SizedBox(height: 8),
                      _row('Discount ($_promoApplied)',
                          '-${formatPeso(cart.discount)}',
                          color: AppColors.success),
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

  static String _promoTag(Promo p) {
    switch (p.type) {
      case 'percent':
        return '${p.value.toStringAsFixed(0)}% off';
      case 'fixed':
        return '${formatPeso(p.value)} off';
      case 'freeship':
        return 'free delivery';
      default:
        return '';
    }
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