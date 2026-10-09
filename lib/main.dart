import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_info.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/providers.dart';
import 'screens/auth_gate.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'utils/responsive.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().init();
  runApp(const JohnFoodsApp());
}

final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

class JohnFoodsApp extends StatelessWidget {
  const JohnFoodsApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp(
          title: kAppName,
          navigatorKey: _navKey,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: theme.dark ? ThemeMode.dark : ThemeMode.light,
          builder: responsiveTextScale,
          home: SplashScreen(
            onFinished: () => _navKey.currentState?.pushReplacement(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 350),
                pageBuilder: (_, __, ___) => const AuthGate(),
                transitionsBuilder: (_, a, __, child) =>
                    FadeTransition(opacity: a, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
