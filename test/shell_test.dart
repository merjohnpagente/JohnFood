import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:john_foods/screens/main_shell.dart';

void main() {
  testWidgets('MainShell shows bottom nav on phone', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: MainShell(
          pages: const [
            Text('Home'),
            Text('Orders'),
            Text('Cart'),
            Text('Profile'),
          ],
          cartCount: (_) => 2,
        ),
      ),
    );
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('MainShell shows rail on wide', (t) async {
    t.view.physicalSize = const Size(1200, 800);
    t.view.devicePixelRatio = 1.0;
    await t.pumpWidget(
      MaterialApp(
        home: MainShell(
          pages: const [
            Text('Home'),
            Text('Orders'),
            Text('Cart'),
            Text('Profile'),
          ],
          cartCount: (_) => 0,
        ),
      ),
    );
    expect(find.byType(NavigationRail), findsOneWidget);
    t.view.resetPhysicalSize();
  });
}
