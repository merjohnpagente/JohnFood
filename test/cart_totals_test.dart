import 'package:flutter_test/flutter_test.dart';
import 'package:john_foods/models/cart_item.dart';
import 'package:john_foods/models/food.dart';
import 'package:john_foods/providers/cart_provider.dart';
import 'package:john_foods/services/order_service.dart';

const _food = Food(
  id: 'b1',
  name: 'Burger',
  description: 'Tasty',
  price: 120,
  rating: 4.5,
  ratingCount: 10,
  image: 'assets/images/b1.jpg',
  category: 'burgers',
  deliveryTime: '20 min',
  available: true,
);

const _fries = Food(
  id: 'f1',
  name: 'Fries',
  description: 'Crispy',
  price: 60,
  rating: 4.2,
  ratingCount: 8,
  image: 'assets/images/f1.jpg',
  category: 'sides',
  deliveryTime: '20 min',
  available: true,
);

void main() {
  test('Cart totals: subtotal, fee, total', () {
    final cart = CartProvider();
    cart.add(_food, qty: 2);
    expect(cart.subtotal, 240);
    expect(cart.deliveryFee, kBaseDeliveryFee);
    expect(cart.total, 240 + kBaseDeliveryFee);
  });

  test('Free delivery at the threshold', () {
    expect(calcDeliveryFee(kFreeDeliveryThreshold), 0);
    expect(calcDeliveryFee(kFreeDeliveryThreshold + 1), 0);
    expect(calcDeliveryFee(kFreeDeliveryThreshold - 1), kBaseDeliveryFee);
    expect(calcDeliveryFee(0), kBaseDeliveryFee);
  });

  test('Order total formula', () {
    expect(calcTotal(240, 49, 24), 265);
  });

  test('Total never goes below zero on a huge discount', () {
    expect(calcTotal(100, 49, 5000), 0);
  });

  test('Adding the same food twice merges quantities', () {
    final cart = CartProvider();
    cart.add(_food, qty: 1);
    cart.add(_food, qty: 2);
    expect(cart.items.length, 1);
    expect(cart.count, 3);
    expect(cart.subtotal, 360);
  });

  test('Different options are separate lines', () {
    final cart = CartProvider();
    cart.add(_food, option: 'Regular');
    cart.add(_food, option: 'Large');
    expect(cart.items.length, 2);
    expect(cart.count, 2);
  });

  test('Setting quantity to zero removes the line', () {
    final cart = CartProvider();
    cart.add(_food, qty: 2);
    cart.setQty(cart.items.first.key, 0);
    expect(cart.items, isEmpty);
    expect(cart.subtotal, 0);
    expect(cart.deliveryFee, 0, reason: 'empty cart has no fee');
  });

  test('Remove then restore brings the line back', () {
    final cart = CartProvider();
    cart.add(_food, qty: 2);
    final removed = cart.remove(cart.items.first.key);
    expect(cart.items, isEmpty);
    cart.restore(removed!);
    expect(cart.items.length, 1);
    expect(cart.count, 2);
  });

  test('Clear empties the cart and the discount', () {
    final cart = CartProvider();
    cart.add(_food);
    cart.add(_fries);
    cart.setDiscount(20, 'TEST');
    cart.clear();
    expect(cart.items, isEmpty);
    expect(cart.discount, 0);
    expect(cart.promoCode, isEmpty);
    expect(cart.total, 0);
  });

  test('Line total is price times quantity', () {
    final item = CartItem(food: _food, qty: 3, selectedOption: 'Large');
    expect(item.lineTotal, 360);
  });

  test('Cart item key distinguishes options', () {
    expect(
      CartItem(food: _food, option: 'Regular').key,
      isNot(CartItem(food: _food, option: 'Large').key),
    );
  });
}