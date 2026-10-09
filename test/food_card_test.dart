import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:john_foods/widgets/ui_kit.dart';

void main() {
  testWidgets('FoodCard shows name, price and rating', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FoodCard(
            name: 'Burger',
            price: 'PHP 120.00',
            rating: 4.5,
            deliveryTime: '20 min',
            image: const SizedBox(),
            onTap: () {},
            onAdd: () {},
          ),
        ),
      ),
    );
    expect(find.text('Burger'), findsOneWidget);
    expect(find.text('PHP 120.00'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget);
  });
}
