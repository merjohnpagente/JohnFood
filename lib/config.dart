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

  // Set to true to talk to local Firestore/Auth emulators during development.
  static const bool useEmulators = bool.fromEnvironment('USE_EMULATORS', defaultValue: false);
  static const String emulatorHost = String.fromEnvironment('EMULATOR_HOST', defaultValue: '10.0.2.2');
}
