import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/image_service.dart';
import '../services/location_service.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
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
  final _paymentRef = TextEditingController();
  String _payment = 'Cash on delivery';
  bool _placing = false;
  late final String _clientRequestId;
  double? _lat;
  double? _lng;
  bool _locLoading = false;
  List<int>? _proofBytes;
  String _proofName = 'receipt.jpg';

  bool get _needsProof => _payment == 'GCash' || _payment == 'Maya';

  @override
  void initState() {
    super.initState();
    _clientRequestId =
        '${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().toString()}';
    _loadPreferredPayment();
  }

  Future<void> _loadPreferredPayment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('johnfoods_payment_v1');
      const known = ["Cash on delivery", "GCash", "Maya", "Card"];
      if (saved != null && known.contains(saved) && mounted) {
        setState(() => _payment = saved);
      }
    } catch (_) {}
  }
  bool _placed = false;

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    _notes.dispose();
    _paymentRef.dispose();
    super.dispose();
  }

  Future<void> _useLocation() async {
    setState(() => _locLoading = true);
    try {
      final p = await LocationService().current();
      if (mounted) {
        setState(() {
          _lat = p.latitude;
          _lng = p.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location attached to order')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not get location. Check permission.')),
        );
      }
    } finally {
      if (mounted) setState(() => _locLoading = false);
    }
  }

  Future<void> _pickProof() async {
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 75,
      );
      if (x == null) return;
      final raw = await x.readAsBytes();
      final small = ImageService().compressReceipt(raw.toList());
      if (!mounted) return;
      setState(() {
        _proofBytes = small;
        _proofName = x.name.isEmpty ? 'receipt.jpg' : x.name;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  Future<void> _place() async {
    if (_placed || !_form.currentState!.validate()) return;
    if (_needsProof && _proofBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attach your payment screenshot')),
      );
      return;
    }
    setState(() => _placing = true);
    try {
      final cart = context.read<CartProvider>();
      final uid = context.read<AuthProvider>().user!.uid;
      final id = await OrderService().placeOrder(
        userId: uid,
        items: cart.items,
        address: _address.text.trim(),
        phone: _phone.text.trim(),
        paymentMethod: _payment,
        notes: _notes.text.trim(),
        discount: cart.discount,
        customerLat: _lat,
        customerLng: _lng,
        paymentRef: _needsProof ? _paymentRef.text.trim() : '',
        clientRequestId: '${uid}_$_clientRequestId',
      );
      // Attach proof after the order exists (works for both Cloudinary
      // URLs and the base64 fallback doc).
      if (_proofBytes != null) {
        try {
          final marker = await ImageService()
              .uploadPaymentProof(id, _proofBytes!, _proofName);
          await OrderService()
              .updatePaymentProof(orderId: id, paymentProofUrl: marker);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'Order placed but proof upload failed: ${friendlyError(e)}')));
          }
        }
      }
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
    final savedAddresses =
        context.watch<AuthProvider>().user?.addresses ?? [];
    final cartEmpty = cart.items.isEmpty;
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(controller: _address, label: 'Delivery address', validator: (v) => validateRequired(v, 'delivery address')),
                        if (savedAddresses.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final a in savedAddresses.take(3))
                                ActionChip(
                                  label: Text(
                                    a.length > 28
                                        ? '${a.substring(0, 28)}...'
                                        : a,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  onPressed: () => setState(
                                      () => _address.text = a),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed:
                                    _locLoading ? null : _useLocation,
                                icon: _locLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Icon(
                                        Icons.my_location_rounded,
                                        size: 18),
                                label: Text(_lat == null
                                    ? 'Use my location'
                                    : 'Location attached'),
                              ),
                            ),
                          ],
                        ),
                        if (_lat != null && _lng != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'GPS: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted),
                            ),
                          ),
                        const SizedBox(height: 12),
                        AppTextField(controller: _phone, label: 'Contact number', validator: validatePhone, keyboardType: TextInputType.phone),
                        const SizedBox(height: 12),
                        AppTextField(controller: _notes, label: 'Notes (optional)', maxLines: 2),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Method',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _payment,
                          decoration: const InputDecoration(labelText: 'Payment method'),
                          items: const [
                            DropdownMenuItem(value: 'Cash on delivery', child: Text('Cash on delivery')),
                            DropdownMenuItem(value: 'GCash', child: Text('GCash')),
                            DropdownMenuItem(value: 'E-wallet', child: Text('E-wallet')),
                            DropdownMenuItem(value: 'Maya', child: Text('Maya')),
                            DropdownMenuItem(value: 'Card', child: Text('Card')),
                          ],
                          onChanged: (v) => setState(() => _payment = v ?? _payment),
                        ),
                        if (_needsProof) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Pay to the merchant wallet, then enter the reference number and attach the screenshot. Admin verifies before food is prepared.',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.muted),
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _paymentRef,
                            label: 'Reference number',
                            validator: (v) => _needsProof
                                ? validateRequired(v, 'reference number')
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickProof,
                                  icon: const Icon(
                                      Icons.receipt_long_rounded,
                                      size: 18),
                                  label: Text(_proofBytes == null
                                      ? 'Attach screenshot'
                                      : 'Change screenshot'),
                                ),
                              ),
                              if (_proofBytes != null) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.check_circle_rounded,
                                    color: AppColors.success),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final item in cart.items)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: FoodImage(
                                        item.food.image),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.food.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Text('x${item.qty}',
                                    style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 13)),
                                const SizedBox(width: 10),
                                Text(
                                  formatPeso(
                                      item.food.price * item.qty),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        const Divider(height: 20),
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
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        label: _placing
            ? 'Placing...'
            : cartEmpty
                ? 'Cart is empty'
                : 'Place order',
        total: formatPeso(cart.total),
        onPressed: (_placing || cartEmpty) ? null : _place,
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
