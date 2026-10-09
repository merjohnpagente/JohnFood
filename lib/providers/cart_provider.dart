import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/food.dart';
import '../services/order_service.dart';

class CartProvider extends ChangeNotifier {
  static const _kCartKey = 'johnfoods_cart_v1';

  final Map<String, CartItem> _items = {};
  String promoCode = '';
  double discount = 0;

  /// Saved cart decoded from disk, waiting for the menu to load
  /// so ids can be resolved back into [Food] objects.
  List<Map<String, dynamic>>? _pending;
  bool _loadDone = false;
  bool _hydrated = false;

  CartProvider() {
    _restore();
  }

  List<CartItem> get items => _items.values.toList();
  int get count => _items.values.fold(0, (s, i) => s + i.qty);
  double get subtotal => calcSubtotal(items);
  double get deliveryFee => items.isEmpty ? 0 : calcDeliveryFee(subtotal);
  double get total => calcTotal(subtotal, deliveryFee, discount);

  void add(Food food, {String option = '', int qty = 1}) {
    final key = '${food.id}::$option';
    if (_items.containsKey(key)) {
      _items[key]!.qty += qty;
    } else {
      _items[key] = CartItem(food: food, qty: qty, selectedOption: option);
    }
    notifyListeners();
    _save();
  }

  void setQty(String key, int qty) {
    if (qty <= 0) {
      _items.remove(key);
    } else {
      _items[key]?.qty = qty;
    }
    notifyListeners();
    _save();
  }

  CartItem? remove(String key) {
    final removed = _items.remove(key);
    notifyListeners();
    _save();
    return removed;
  }

  void restore(CartItem item) {
    _items[item.key] = item;
    notifyListeners();
    _save();
  }

  void setDiscount(double d, String code) {
    discount = d;
    promoCode = code;
    notifyListeners();
    _save();
  }

  void clear() {
    _items.clear();
    discount = 0;
    promoCode = '';
    notifyListeners();
    _save();
  }

  /// Rebuild cart items from the loaded menu. Returns true once
  /// hydration is complete (or there was nothing to restore).
  /// Safe to call on every build — it runs only once.
  bool hydrate(List<Food> foods) {
    if (_hydrated || !_loadDone) return _hydrated;
    _hydrated = true;
    final pending = _pending;
    _pending = null;
    if (pending != null && pending.isNotEmpty) {
      final byId = {for (final f in foods) f.id: f};
      for (final m in pending) {
        final f = byId[m['id'] as String? ?? ''];
        if (f == null) continue;
        final qty = ((m['qty'] as num?)?.toInt() ?? 1).clamp(1, 99);
        final opt = (m['opt'] as String?) ?? '';
        _items['${f.id}::$opt'] =
            CartItem(food: f, qty: qty, selectedOption: opt);
      }
      notifyListeners();
    }
    return true;
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCartKey);
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final items = data['items'];
        if (items is List) {
          _pending = items
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        promoCode = (data['promo'] as String?) ?? '';
        discount = ((data['discount'] as num?)?.toDouble() ?? 0)
            .clamp(0, 1e9)
            .toDouble();
      }
    } catch (_) {
      // Corrupt or unavailable storage: start with an empty cart.
      _pending = null;
    } finally {
      _loadDone = true;
      notifyListeners();
    }
  }

  void _save() {
    try {
      final data = jsonEncode({
        'items': [
          for (final i in _items.values)
            {'id': i.food.id, 'qty': i.qty, 'opt': i.selectedOption},
        ],
        'promo': promoCode,
        'discount': discount,
      });
      SharedPreferences.getInstance().then(
        (prefs) {
          try {
            prefs.setString(_kCartKey, data);
          } catch (_) {}
        },
        onError: (_) {},
      );
    } catch (_) {}
  }
}
