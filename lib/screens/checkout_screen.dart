import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';
import '../utils/error_mapper.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../utils/validators.dart';
import '../widgets/ui_kit.dart';
import 'tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();
  String _payment = 'Cash on delivery';
  bool _placing = false;
  bool _placed = false;

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _place() async {
    if (_placed || !_form.currentState!.validate()) return;
    setState(() => _placing = true);
    try {
      final cart = context.read<CartProvider>();
      final uid = context.read<AuthProvider>().user!.uid;
      final id = await OrderService().placeOrder(
        userId: uid,
        items: cart.items,
        address: _address.text.trim(),
        paymentMethod: _payment,
        notes: _notes.text.trim(),
        discount: cart.discount,
        clientRequestId: '${uid}_${DateTime.now().millisecondsSinceEpoch}',
      );
      cart.clear();
      setState(() => _placed = true);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => TrackingScreen(orderId: id)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ContentWidth(
        maxWidth: 640,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.pagePadding),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(controller: _address, label: 'Delivery address', validator: (v) => validateRequired(v, 'delivery address')),
                const SizedBox(height: 12),
                AppTextField(controller: _phone, label: 'Contact number', validator: validatePhone, keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _payment,
                  decoration: const InputDecoration(labelText: 'Payment method'),
                  items: const [
                    DropdownMenuItem(value: 'Cash on delivery', child: Text('Cash on delivery')),
                    DropdownMenuItem(value: 'GCash', child: Text('GCash')),
                    DropdownMenuItem(value: 'E-wallet', child: Text('E-wallet')),
                  ],
                  onChanged: (v) => setState(() => _payment = v ?? _payment),
                ),
                const SizedBox(height: 12),
                AppTextField(controller: _notes, label: 'Notes (optional)', maxLines: 2),
                const SizedBox(height: 16),
                Text('Subtotal: ${formatPeso(cart.subtotal)}'),
                Text('Delivery: ${formatPeso(cart.deliveryFee)}'),
                Text('Total: ${formatPeso(cart.total)}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        label: _placing ? 'Placing...' : 'Place order',
        total: formatPeso(cart.total),
        onPressed: _placing ? null : _place,
      ),
    );
  }
}
