import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/food.dart';
import '../services/order_service.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  String promoCode = '';
  double discount = 0;

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
  }

  void setQty(String key, int qty) {
    if (qty <= 0) {
      _items.remove(key);
    } else {
      _items[key]?.qty = qty;
    }
    notifyListeners();
  }

  CartItem? remove(String key) {
    final removed = _items.remove(key);
    notifyListeners();
    return removed;
  }

  void restore(CartItem item) {
    _items[item.key] = item;
    notifyListeners();
  }

  void setDiscount(double d, String code) {
    discount = d;
    promoCode = code;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    discount = 0;
    promoCode = '';
    notifyListeners();
  }
}
