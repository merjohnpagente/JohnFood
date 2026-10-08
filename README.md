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
   plus Vercel `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`.
5. Settings > Pages > Source: GitHub Actions (kept).
6. Commit to `main`. Actions tab:
   - Build Android APK: download `john-foods-apk` artifact, install on phone.
   - Deploy Web (GitHub Pages, kept): open `https://<user>.github.io/<repo>/`.
   - Deploy Web to Vercel (auto): builds with `--base-href /` and deploys
     `build/web` to `https://johnfoodapp.vercel.app` (`vercel.json` handles
     SPA fallback to `index.html`).
   - Deploy Firestore rules: runs on rules changes + manual.
7. Failed run: open the red job, copy error lines, ask AI to fix.

Platform folders: if `android/` or `web/` is missing (fresh clone), workflows
auto-run `flutter create . --project-name john_foods --org com.merjdev.johnfoods`.
For signed release APK, add `ANDROID_KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`,
`KEY_ALIAS`, `KEY_PASSWORD` secrets.

## End-to-end test (Spark free)

Register, browse, add to cart, apply JOHN10, place order, login as admin,
change status Preparing > On the way > Delivered, assign rider, customer sees
notification + live map (OpenStreetMap + OSRM, best effort).

## Strict rules checklist

- No emoji anywhere (CI `ci.yml` greps and fails).
- Material `Icons.*_rounded` only.
- Responsive: <600 phone bottom nav 2-col, 720+ rail 3-4 col, 1100+ extended rail 5+ col, maxWidth 1100 (forms 640), tested 320x568 to 1440x900.
- 4 states per data screen: skeleton, empty + action, error + retry, offline banner + cache.
- Theme tokens only, no hardcoded colors in screens.
- Friendly errors only (see `error_mapper.dart`).
- No secrets committed (`String.fromEnvironment` + `--dart-define`).
- Accessibility: 48px targets, Semantics on icon buttons, text scale clamp 0.9-1.2.
