import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/merchant_settings.dart';
import '../services/payment_service.dart';
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
  static const _keys = [
    'Cash on delivery',
    'GCash',
    'Maya',
  ];

  static const _meta = {
    'Cash on delivery': (Icons.payments_outlined, 'Pay in cash on arrival'),
    'GCash': (Icons.account_balance_wallet_outlined, 'Transfer, then attach the receipt'),
    'Maya': (Icons.wallet_outlined, 'Transfer, then attach the receipt'),
  };

  String _selected = 'Cash on delivery';
  bool _loading = true;
  MerchantSettings? _merchant;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _watchMerchant() async {
    try {
      final sub = PaymentService().watchSettings().listen((s) {
        if (mounted) setState(() => _merchant = s);
      });
      _sub = sub;
    } catch (_) {}
  }

  StreamSubscription<MerchantSettings>? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kKey);
      if (saved != null && _keys.contains(saved)) {
        _selected = saved;
      }
    } catch (_) {
      // Keep the default method.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    _watchMerchant();
  }

  Future<void> _select(String value) async {
    final m = _merchant;
    if (m != null && !m.isReady(value)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$value is not available right now')),
      );
      return;
    }
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
                itemCount: _keys.length + 1,
                itemBuilder: (_, i) {
                  if (i == _keys.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Card and online wallets are not available yet. '
                        'Cash on delivery and GCash/Maya transfers work today.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.muted),
                      ),
                    );
                  }
                  final key = _keys[i];
                  final meta = _meta[key]!;
                  final selected = key == _selected;
                  final ready =
                      _merchant?.isReady(key) ?? key == 'Cash on delivery';
                  final wallet = _merchant?.walletFor(key) ?? '';
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
                          child: Icon(meta.$1,
                              color: selected
                                  ? AppColors.onPrimary
                                  : AppColors.primary),
                        ),
                        title: Text(key,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ready
                                  ? (wallet.isEmpty
                                      ? meta.$2
                                      : '${meta.$2}  ($wallet)')
                                  : 'Unavailable right now',
                              style: TextStyle(
                                  color: ready
                                      ? AppColors.muted
                                      : AppColors.error,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                        trailing: !ready
                            ? const Icon(Icons.block_rounded,
                                color: AppColors.muted)
                            : selected
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primary)
                                : const Icon(Icons.circle_outlined,
                                    color: AppColors.muted),
                        onTap: ready ? () => _select(key) : null,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
