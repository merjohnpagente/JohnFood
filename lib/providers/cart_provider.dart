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
  bool _restored = false;

  CartProvider() {
    _restore();
  }

  List<CartItem> get items => _items.values.toList();
  int get count => _items.values.fold(0, (s, i) => s + i.qty);
  double get subtotal => calcSubtotal(items);
  double get deliveryFee => items.isEmpty ? 0 : calcDeliveryFee(subtotal);
  double get total => calcTotal(subtotal, deliveryFee, discount);
  bool get restored => _restored;

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

  Map<String, dynamic> _foodToMap(Food f) => {
        'id': f.id,
        'name': f.name,
        'description': f.description,
        'price': f.price,
        'rating': f.rating,
        'ratingCount': f.ratingCount,
        'image': f.image,
        'category': f.category,
        'deliveryTime': f.deliveryTime,
        'available': f.available,
        'options': f.options,
      };

  Food _foodFromMap(Map<String, dynamic> m) => Food(
        id: (m['id'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        description: (m['description'] ?? '') as String,
        price: ((m['price'] ?? 0) as num).toDouble(),
        rating: ((m['rating'] ?? 0) as num).toDouble(),
        ratingCount: ((m['ratingCount'] ?? 0) as num).toInt(),
        image: (m['image'] ?? '') as String,
        category: (m['category'] ?? '') as String,
        deliveryTime: (m['deliveryTime'] ?? '25 min') as String,
        available: (m['available'] ?? true) as bool,
        options:
            ((m['options'] ?? []) as List).map((e) => '$e').toList(),
      );

  /// Persist cart so it survives refresh / restart. Errors are
  /// swallowed so tests (no plugin) and offline never break.
  void _save() {
    try {
      final data = jsonEncode({
        'items': [
          for (final i in _items.values)
            {
              'food': _foodToMap(i.food),
              'qty': i.qty,
              'option': i.selectedOption,
            },
        ],
        'promoCode': promoCode,
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

  void _restore() {
    SharedPreferences.getInstance().then(
      (prefs) {
        try {
          final raw = prefs.getString(_kCartKey);
          if (raw != null && raw.isNotEmpty) {
            final data = jsonDecode(raw) as Map<String, dynamic>;
            final items = (data['items'] as List?) ?? [];
            for (final e in items) {
              final m = Map<String, dynamic>.from(e as Map);
              final food = _foodFromMap(
                  Map<String, dynamic>.from(m['food'] as Map));
              final qty = ((m['qty'] ?? 1) as num).toInt().clamp(1, 99);
              final option = (m['option'] ?? '') as String;
              _items['${food.id}::$option'] = CartItem(
                  food: food, qty: qty, selectedOption: option);
            }
            promoCode = (data['promoCode'] ?? '') as String;
            discount =
                ((data['discount'] ?? 0) as num).toDouble();
          }
        } catch (_) {}
        _restored = true;
        notifyListeners();
      },
      onError: (_) {
        _restored = true;
        notifyListeners();
      },
    );
  }
}
