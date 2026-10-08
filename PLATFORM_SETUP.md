# After `flutter create .` generates android/ and web/, apply these:

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
