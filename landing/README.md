# John Foods landing page

Static marketing site for the John Foods app. Pure HTML + CSS + vanilla JS,
no build step, no frameworks. Deployed as its own Vercel project
(suggested name `johnfoodsite`).

## Preview locally

Serve this folder statically, e.g. `python3 -m http.server` inside
`landing/`, then open the printed URL.

## Deploy (Vercel, separate project)

1. Vercel → Add New → Project → Import `merjohnpagente/JohnFood`.
2. **Root Directory:** `landing/`. Framework: **Other**. No build command.
3. Deploy. The Flutter web app keeps deploying to `johnfoodapp.vercel.app`
   via `.github/workflows/deploy-vercel.yml` — untouched.

## Download Now button

Points to `https://github.com/merjohnpagente/JohnFood/releases/latest`.
Push a tag (`v1.0.0`) and `build-android.yml` attaches `app-release.apk`
to the Release, so the button downloads the APK. Before the first tag,
visitors land on the Releases page.

## Content rules (same as the app)

- Prices: Philippine peso only (`PHP x.xx` via `peso()` in `menu.js`).
- Icons: Material Symbols Rounded only. No emoji anywhere.
- Menu data mirrors `lib/data/sample_data.dart` — update both together.

## Responsive checklist

320 · 390 · 768 · 1024 · 1440 + one landscape check. No horizontal scroll,
no clipped buttons, drawer works under 720px, menu grid intact at every
width, contact form usable.
