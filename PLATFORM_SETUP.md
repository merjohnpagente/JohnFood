# Platform setup

## Where the keys come from

| Platform | Where the keys live | How they reach the build |
|---|---|---|
| Web | committed in `lib/firebase_options.dart` | public client config, safe in git |
| Android | committed in `lib/firebase_options.dart` + `GOOGLE_SERVICES_JSON` secret | see Build Android |
| iOS | **not in git** | `--dart-define` from GitHub secrets |

iOS keys are build-time defines because the bundle id differs per target and
the values should never be committed by accident.

## 1. Firebase console > Project settings > Apple iOS

1. Click the iOS app, or add one.
2. Bundle id must be `com.merjdev.johnfoods` (matches `flutter create --org
   com.merjdev.johnfoods`).
3. Copy **API Key**, **App ID**, **Messaging Sender ID** and the storage
   bucket name.

## 2. GitHub secrets for iOS

Add under Settings > Secrets and variables > Actions:

| Secret | Value |
|---|---|
| `IOS_API_KEY` | API key from the iOS app |
| `IOS_APP_ID` | App ID from the iOS app |
| `IOS_MESSAGING_SENDER_ID` | Messaging sender ID |
| `IOS_STORAGE_BUCKET` | e.g. `johnfood-b281a.firebasestorage.app` |
| `IOS_GOOGLE_SERVICES_JSON` | full contents of `GoogleService-Info.plist` |

Without these the iOS build still compiles and every other feature works;
the app shows a clear "this build is missing its iOS keys" screen instead of
crashing. Google sign-in on iOS additionally needs
`GoogleService-Info.plist` inside the Runner target.

## 3. iOS permissions

`build-ios.yml` writes these into `ios/Runner/Info.plist` on every build, so
there is nothing to edit by hand:

* `NSLocationWhenInUseUsageDescription` - checkout GPS pin and rider tracking
* `NSLocationAlwaysAndWhenInUseUsageDescription` - background rider tracking
* `NSPhotoLibraryUsageDescription` / `NSCameraUsageDescription` - payment
  receipt and food photos

## 4. Running the iOS build

The workflow builds `Runner.app` with `--no-codesign`, which is enough to
verify it compiles and to install on a device with Xcode or
`flutter install`. For distribution you need an Apple Developer account and a
signed archive, which this workflow does not do.

Locally:

```bash
flutter pub get
flutter run -d ios \
  --dart-define=IOS_API_KEY=... \
  --dart-define=IOS_APP_ID=... \
  --dart-define=IOS_MESSAGING_SENDER_ID=...
```

## Android

`build-android.yml` adds the location permissions to the manifest, restores
`android/app/google-services.json` from `GOOGLE_SERVICES_JSON` and generates
the launcher icon. Register the debug keystore SHA-1 in the Firebase console
or Google sign-in fails on device:

```bash
keytool -list -v -keystore keystores/johnfoods-debug.p12 \
  -storepass android -alias androiddebugkey
```

## Web

`web/index.html` and `web/manifest.json` are already branded. Add your
GitHub Pages and Vercel domains to Firebase console > Authentication >
Settings > Authorized domains, otherwise web Google sign-in fails with
`auth/unauthorized-domain`.