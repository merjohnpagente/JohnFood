import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import 'admin/admin_shell.dart';
import 'auth/login_screen.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'main_shell.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'rider/rider_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.error != null && !auth.loggedIn) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 48),
                const SizedBox(height: 12),
                Text(auth.error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => auth.retry(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (!auth.loggedIn) return const LoginScreen();
    if (auth.user!.isAdmin) return const AdminShell();
    if (auth.user!.isRider) return const RiderScreen();
    return MainShell(
      pages: const [HomeScreen(), OrdersScreen(), CartScreen(), ProfileScreen()],
      cartCount: (ctx) => ctx.watch<CartProvider>().count,
    );
  }
}
