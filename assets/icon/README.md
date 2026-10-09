# John Foods app icon

Glyph: "fastfood" (burger and drink) from Material Design Icons (google/material-design-icons,
npm @material-design-icons/svg), Apache License 2.0. See LICENSE-material-design-icons.txt.
Same glyph as Icons.fastfood_rounded used on the splash screen, so the icon and splash match.
Color: orange #FF5722 background, white glyph.

Files
- icon.svg                    editable source (1024 x 1024)
- icon_1024.png               main icon, full bleed, no transparency (iOS and legacy Android)
- icon_foreground_1024.png    Android adaptive icon foreground (glyph inside the safe zone)
- icon_monochrome_1024.png    Android 13+ themed icon
- icon_rounded_preview.png    preview only, do not use in the build
- ../web/icons/Icon-192.png, Icon-512.png, Icon-maskable-192.png, Icon-maskable-512.png, ../web/favicon.png

Install
1. Copy assets/ and web/ into your project (merge with the existing folders).
2. Add flutter_launcher_icons to dev_dependencies and merge flutter_launcher_icons.yaml into pubspec.yaml
   (or keep it as its own file).
3. Run:  flutter pub get  then  dart run flutter_launcher_icons
4. web/manifest.json: set name and short_name to "John Foods", theme_color "#FF5722",
   and point icons to icons/Icon-192.png, Icon-512.png and the maskable ones.
