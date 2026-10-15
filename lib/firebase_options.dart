import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase options. Web and Android are committed because those keys are
/// public client configuration. iOS is injected at build time from
/// `--dart-define` values (see AppConfig) so no secret ever lands in git
/// and the build works the moment the keys exist.
///
/// Values come from Firebase console > Project settings.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD09MUFhaHlQBnkFmxELzqAZij0EYw1jX4',
    appId: '1:738831913873:web:7082bed270b4e786bbc030',
    messagingSenderId: '738831913873',
    projectId: 'johnfood-b281a',
    authDomain: 'johnfood-b281a.firebaseapp.com',
    storageBucket: 'johnfood-b281a.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCpgnRP0WI80HxiwM31YonaNk1wcWvXhNI',
    appId: '1:738831913873:android:54716c856810e32abbc030',
    messagingSenderId: '738831913873',
    projectId: 'johnfood-b281a',
    storageBucket: 'johnfood-b281a.firebasestorage.app',
  );

  /// iOS credentials are supplied by the build, not by this file.
  ///
  /// Required defines:
  ///   IOS_API_KEY, IOS_APP_ID, IOS_MESSAGING_SENDER_ID
  /// Optional:
  ///   IOS_STORAGE_BUCKET (defaults to the project bucket)
  static FirebaseOptions get ios {
    const senderId = String.fromEnvironment('IOS_MESSAGING_SENDER_ID');
    final bucket = const String.fromEnvironment(
      'IOS_STORAGE_BUCKET',
      defaultValue: 'johnfood-b281a.firebasestorage.app',
    );
    if (senderId.isEmpty) {
      return const FirebaseOptions(
        apiKey: 'missing-ios-api-key',
        appId: '1:738831913873:ios:missing',
        messagingSenderId: '738831913873',
        projectId: 'johnfood-b281a',
        storageBucket: 'johnfood-b281a.firebasestorage.app',
        iosBundleId: 'com.merjdev.johnfoods',
      );
    }
    return FirebaseOptions(
      apiKey: const String.fromEnvironment('IOS_API_KEY'),
      appId: const String.fromEnvironment('IOS_APP_ID'),
      messagingSenderId: senderId,
      projectId: 'johnfood-b281a',
      storageBucket: bucket,
      iosBundleId: 'com.merjdev.johnfoods',
    );
  }

  /// True when iOS build-time keys were supplied.
  static bool get iosConfigured =>
      const String.fromEnvironment('IOS_MESSAGING_SENDER_ID').isNotEmpty;
}