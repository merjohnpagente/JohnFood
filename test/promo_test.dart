import 'package:flutter_test/flutter_test.dart';
import 'package:john_foods/models/promo.dart';

void main() {
  test('Promo percent discount', () {
    const p = Promo(code: 'JOHN10', type: 'percent', value: 10, active: true);
    expect(p.discountFor(200), 20);
  });

  test('Promo fixed clamps to subtotal', () {
    const p = Promo(code: 'FIX', type: 'fixed', value: 500, active: true);
    expect(p.discountFor(200), 200);
  });

  test('Inactive promo gives zero', () {
    const p = Promo(code: 'X', type: 'percent', value: 50, active: false);
    expect(p.discountFor(200), 0);
  });
}
