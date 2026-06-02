# ZeroSpoils App Icon

## Design

A grocery bag (die-cut handle) guarded by a shield with a check — *"your
groceries, preserved."* Brand green (`#2F9E44` → `#51CF66` gradient), cream bag,
dark-green shield. The motif maps to the brand promise: protect food (and money)
from being wasted.

## Source of truth

The icon is authored as **SVG** and rasterized to PNG:

| File | Purpose |
|------|---------|
| `app_icon.svg` / `app_icon.png` | Full-bleed 1024² master (iOS + legacy Android) |
| `app_icon_foreground.svg` / `app_icon_foreground.png` | Transparent, centered motif for the Android adaptive foreground |

Edit the `.svg` files, then re-render the PNGs (any SVG renderer; we use macOS
`qlmanage -t -s 1024 -o . app_icon.svg`).

## Regenerate all launcher icons

```bash
cd app
flutter pub get
dart run flutter_launcher_icons
```

Config lives in `pubspec.yaml` under `flutter_launcher_icons:`
- `adaptive_icon_background: "#2F9E44"` (brand green)
- `remove_alpha_ios: true` (Apple rejects icons with an alpha channel)

## Notes

- Keep important detail inside the central ~66% (Android adaptive safe zone).
- Verify legibility down to ~48px before shipping.
