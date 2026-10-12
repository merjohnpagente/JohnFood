# After `flutter create .` generates android/ and web/, apply these:

## 0. Google sign-in prerequisites (APK + web)
- Firebase console > Project settings > Android app: add the SHA-1
  fingerprint. Debug keystore in this repo:
  `keytool -list -v -keystore keystores/johnfoods-debug.p12 -storepass android -alias androiddebugkey`
  Also add your release key SHA-1. Without this, the Google account
  picker fails with ApiException 10.
- Download the updated `google-services.json` and save it as the
  `GOOGLE_SERVICES_JSON` GitHub secret (CI writes it to
  `android/app/google-services.json` during the build).
- Firebase console > Project settings > General > Web SDK configuration:
  copy the OAuth client ID into the `GOOGLE_SERVER_CLIENT_ID` GitHub
  secret (passed as `--dart-define`, also used for local builds).
- Firebase console > Authentication > Settings > Authorized domains:
  add `<user>.github.io` and `johnfoodapp.vercel.app`, otherwise web
  Google sign-in fails with `auth/unauthorized-domain`.

## 1. android/app/src/main/AndroidManifest.xml
- Set `android:label="John Foods"` on the <application> tag.
- Remove any com.google.android.geo.API_KEY meta-data (no Google Maps key,
  OpenStreetMap is used instead).
- Internet permission is required for Firestore + OSM tiles:
  <uses-permission android:name="android.permission.INTERNET"/>
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

## 2. web/index.html
- <title>John Foods</title>
- apple-mobile-web-app-title = John Foods

## 3. web/manifest.json
- "name": "John Foods", "short_name": "John Foods"
- theme_color #FF5722, icons point to icons/Icon-192.png etc.

All three web files are already correct in this repo under web/.
