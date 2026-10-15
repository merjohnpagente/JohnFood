import 'package:flutter_test/flutter_test.dart';
import 'package:john_foods/models/promo.dart';

void main() {
  test('percent discount applies to the subtotal', () {
    const p = Promo(code: 'SALE10', type: 'percent', value: 10);
    expect(p.discountFor(200), 20);
  });

  test('fixed discount clamps to the subtotal', () {
    const p = Promo(code: 'OFF50', type: 'fixed', value: 50);
    expect(p.discountFor(20), 20);
  });

  test('freeship cancels the delivery fee', () {
    const p = Promo(code: 'FREEDEL', type: 'freeship');
    expect(p.discountFor(200, deliveryFee: 49), 49);
  });

  test('inactive promo gives zero', () {
    const p = Promo(code: 'OLD', type: 'percent', value: 50, active: false);
    expect(p.discountFor(200), 0);
    expect(p.isValid, isFalse);
  });

  test('expired promo gives zero', () {
    final p = Promo(
      code: 'GONE',
      type: 'percent',
      value: 50,
      expiresAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    expect(p.isExpired, isTrue);
    expect(p.discountFor(200), 0);
  });

  test('minimum spend blocks small orders', () {
    const p = Promo(code: 'BIG', type: 'percent', value: 10, minSubtotal: 500);
    expect(p.appliesTo(400), isFalse);
    expect(p.appliesTo(600), isTrue);
  });

  test('used up promo gives zero', () {
    const p = Promo(
        code: 'LIMIT', type: 'percent', value: 10, maxUses: 5, used: 5);
    expect(p.isUsedUp, isTrue);
    expect(p.discountFor(200), 0);
  });
}