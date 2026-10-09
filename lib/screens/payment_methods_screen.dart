import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../utils/responsive.dart';

/// Preferred payment method, persisted on-device and used as the
/// default choice at checkout.
class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});
  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  static const _kKey = 'johnfoods_payment_v1';
  static const _methods = [
    ('Cash on delivery', Icons.payments_outlined, 'Pay in cash on arrival'),
    ('GCash', Icons.account_balance_wallet_outlined, 'Pay with GCash'),
    ('Maya', Icons.wallet_outlined, 'Pay with Maya'),
    ('Card', Icons.credit_card_outlined, 'Coming soon to checkout'),
  ];

  String _selected = _methods.first.$1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kKey);
      if (saved != null &&
          mounted &&
          _methods.any((m) => m.$1 == saved)) {
        setState(() => _selected = saved);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _select(String value) async {
    setState(() => _selected = value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kKey, value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$value set as default')),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: ContentWidth(
        maxWidth: 640,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: EdgeInsets.all(context.pagePadding),
                itemCount: _methods.length,
                itemBuilder: (_, i) {
                  final m = _methods[i];
                  final selected = m.$1 == _selected;
                  return Entrance(
                    delay:
                        Duration(milliseconds: (i * 50).clamp(0, 200)),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: selected ? AppColors.tint : null,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : AppColors.tint,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(m.$2,
                              color: selected
                                  ? Colors.white
                                  : AppColors.primary),
                        ),
                        title: Text(m.$1,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        subtitle: Text(m.$3,
                            style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 13)),
                        trailing: selected
                            ? const Icon(Icons.check_circle_rounded,
                                color: AppColors.primary)
                            : const Icon(
                                Icons.circle_outlined,
                                color: AppColors.muted),
                        onTap: () => _select(m.$1),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
