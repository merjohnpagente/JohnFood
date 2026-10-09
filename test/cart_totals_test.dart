import 'package:flutter_test/flutter_test.dart';
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

void main() {
  test('Cart totals: subtotal, fee, total', () {
    final cart = CartProvider();
    cart.add(_food, qty: 2);
    expect(cart.subtotal, 240);
    expect(cart.deliveryFee, 49);
    expect(cart.total, 289);
  });

  test('Free delivery at 500+', () {
    expect(calcDeliveryFee(600), 0);
    expect(calcDeliveryFee(100), 49);
  });

  test('Order total formula', () {
    expect(calcTotal(240, 49, 24), 265);
  });
}
