# John Foods

Zero-cost food delivery app: Flutter 3.22+ frontend + Firebase Spark backend
(Auth + Firestore only). By MerjDev.

Note on security: client-side price calculation is used instead of a server
(Cloud Functions need a paid plan). Fine for a school project, not for
production where prices must be computed server-side.

## Quick start (phone only, no PC install)

1. Push this folder to `github.com/merjohnpagente/JohnFood` (public repo).
2. Firebase console: create Spark project, enable Email/Password + Google auth,
   create Firestore database, paste web/android keys into `lib/firebase_options.dart`.
3. Set first admin manually: `users/{uid}.role = 'admin'` in Firestore console.
4. GitHub repo Settings > Secrets and variables > Actions: add
   `FIREBASE_SERVICE_ACCOUNT`, `FIREBASE_PROJECT_ID`,
   optional `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_UPLOAD_PRESET`,
   `GOOGLE_SERVICES_JSON` (whole google-services.json file content,
   required for Google sign-in on Android),
   `GOOGLE_SERVER_CLIENT_ID` (Web OAuth client ID from Firebase console >
   Project settings > General, required for Google sign-in on Android),
   plus Vercel `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`.
   Firebase console > Project settings > Android app: register the SHA-1
   of the debug keystore (`keystores/johnfoods-debug.p12`, alias
   `androiddebugkey`) and of your release key, otherwise Google sign-in
   fails with ApiException 10. Authentication > Settings > Authorized
   domains: add your GitHub Pages and Vercel domains or web Google
   sign-in will fail.
5. iOS: add an Apple app with bundle id `com.merjdev.johnfoods` in the
   Firebase console, then set `IOS_API_KEY`, `IOS_APP_ID`,
   `IOS_MESSAGING_SENDER_ID`, `IOS_STORAGE_BUCKET` and
   `IOS_GOOGLE_SERVICES_JSON` secrets. See `PLATFORM_SETUP.md`. Without
   them the iOS build still compiles and only Google sign-in is disabled.
6. Settings > Pages > Source: GitHub Actions (kept).
7. Commit to `main`. Actions tab:
   - Build Android APK: download `john-foods-apk` artifact, install on phone.
   - Build iOS: downloads `john-foods-ios` (unsigned `Runner.app`).
   - Deploy Web (GitHub Pages, kept): open `https://<user>.github.io/<repo>/`.
   - Deploy Web to Vercel (auto): builds with `--base-href /` and deploys
     `build/web` to `https://johnfoodapp.vercel.app` (`vercel.json` handles
     SPA fallback to `index.html`).
   - Deploy Firestore rules: runs on rules changes + manual.
8. Failed run: open the red job, copy error lines, ask AI to fix.

Platform folders: if `android/`, `ios/` or `web/` is missing (fresh clone),
workflows auto-run `flutter create . --project-name john_foods --org
com.merjdev.johnfoods`.
For signed release APK, add `ANDROID_KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`,
`KEY_ALIAS`, `KEY_PASSWORD` secrets.

## End-to-end test (Spark free)

Register, browse, add to cart, apply a promo from Admin > Promos, place
order, login as admin, verify the payment proof if GCash/Maya, assign a
rider, rider accepts, customer sees the notification and live map
(OpenStreetMap + OSRM, best effort).

## Strict rules checklist

- No emoji anywhere (CI `ci.yml` greps and fails).
- Material `Icons.*_rounded` only.
- Responsive: <600 phone bottom nav 2-col, 720+ rail 3-4 col, 1100+ extended rail 5+ col, maxWidth 1100 (forms 640), tested 320x568 to 1440x900.
- 4 states per data screen: skeleton, empty + action, error + retry, offline banner + cache.
- Theme tokens only, no hardcoded colors in screens.
- Friendly errors only (see `error_mapper.dart`).
- No secrets committed (`String.fromEnvironment` + `--dart-define`).
- Accessibility: 48px targets, Semantics on icon buttons, text scale clamp 0.9-1.2.

## Known limits

These are real and not fixable on the free Spark plan:

- **Prices are computed on the device.** Firestore rules now reject an order
  whose subtotal does not match its own items and cap quantity, price and
  item counts, but a tampered APK could still send a lower per-item price.
  Only Cloud Functions (Blaze plan) can verify prices against the menu.
- **No server push.** Rider alerts are local notifications driven by the
  rider's own order stream, so the rider app must be open.
- **Location is foreground only** for the customer map; the rider's auto
  tracking needs the app open and the screen allowed to sleep normally.
- **GCash and Maya are manual.** The customer attaches a screenshot and an
  admin verifies it by hand. No payment gateway is integrated.
- **iOS builds unsigned.** `flutter build ios --no-codesign` verifies the
  build; App Store distribution needs an Apple Developer account.
- **No crash reporting.** Failures are only visible in the CI logs.
- **Daily read and write quotas bound the user count.** See
  `LOAD_TESTING.md` for the real per-screen numbers; roughly 150 to 200 daily
  active users fit in the free plan once the menu is cached per session.
