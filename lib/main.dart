import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kIsWeb, TargetPlatform;
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
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e, st) {
    // A misconfigured build (for example iOS keys that were never supplied)
    // must explain itself instead of showing a black screen.
    debugPrint('Firebase init failed: $e\n$st');
    runApp(const _FirebaseErrorApp());
    return;
  }
  await NotificationService().init();
  runApp(const JohnFoodsApp());
}

/// Shown when Firebase could not start, e.g. an iOS build without keys.
class _FirebaseErrorApp extends StatelessWidget {
  const _FirebaseErrorApp();

  @override
  Widget build(BuildContext context) {
    final missingIos =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS &&
            !DefaultFirebaseOptions.iosConfigured;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    size: 56, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  missingIos
                      ? 'This build is missing its iOS keys'
                      : 'Could not start the app',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  missingIos
                      ? 'The iOS Firebase keys were not supplied at build '
                          'time. Re-run flutterfire configure, or build with '
                          'the IOS_API_KEY, IOS_APP_ID and '
                          'IOS_MESSAGING_SENDER_ID defines.'
                      : 'Check your internet connection and try again.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
