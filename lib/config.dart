// Central runtime config. Secrets are never committed.
// Pass values with --dart-define in CI:
//   flutter build apk --dart-define=CLOUDINARY_CLOUD_NAME=xxx
//                     --dart-define=CLOUDINARY_UPLOAD_PRESET=yyy
class AppConfig {
  static const String cloudinaryCloudName =
      String.fromEnvironment('CLOUDINARY_CLOUD_NAME', defaultValue: '');
  static const String cloudinaryUploadPreset =
      String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET', defaultValue: '');

  static bool get cloudinaryConfigured =>
      cloudinaryCloudName.isNotEmpty && cloudinaryUploadPreset.isNotEmpty;

  // Web OAuth client ID for Google Sign-In on Android (google_sign_in v6
  // needs serverClientId to return an idToken for Firebase).
  // Firebase console > Project settings > General > Web SDK configuration.
  // Safe to ship (public client ID, like the Firebase apiKey).
  // Pass with --dart-define=GOOGLE_SERVER_CLIENT_ID=xxx in CI.
  static const String googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: '');

  // Set to true to talk to local Firestore/Auth emulators during development.
  static const bool useEmulators = bool.fromEnvironment('USE_EMULATORS', defaultValue: false);
  static const String emulatorHost = String.fromEnvironment('EMULATOR_HOST', defaultValue: '10.0.2.2');
}
