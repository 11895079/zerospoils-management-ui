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
| `app_icon_foreground.svg` / `app_icon_foreground.png` | Android adaptive **foreground** — full-bleed brand-green field with the motif centred in the safe zone |
| `app_icon_monochrome.svg` / `app_icon_monochrome.png` | Android 13+ **themed-icon** layer — flat-colour motif silhouette on transparency (system re-tints it) |

Edit the `.svg` files, then re-render the PNGs (see the rasterising note below).

## Why the foreground carries its own green field

An Android adaptive foreground is composited over the `adaptive_icon_background`
layer, but launchers may mask it to a circle/squircle and several surfaces show
the **foreground alone** (so the background colour does not apply). If the
foreground is just the motif, the cream bag washes out to an invisible blob on
light/white backgrounds.

So the foreground **bakes the full-bleed green gradient into itself** and the
launcher-icons inset is set to `0` (`adaptive_icon_foreground_inset: 0`) so the
green bleeds to every edge. The motif is centred and scaled to ~0.90 so it stays
inside the 66 dp adaptive safe circle. Result: green-then-cream contrast on any
mask shape and any home-screen colour. A soft drop shadow lifts the bag + shield
off the field; the shield ring/check are bolder for small-size legibility.

## Regenerate all launcher icons

Use the wrapper script — it runs the generator and heals a tooling bug (below):

```bash
cd app
./scripts/regen-icons.sh
```

<details>
<summary>Equivalent manual steps</summary>

```bash
cd app
flutter pub get
dart run flutter_launcher_icons
# Then revert the pbxproj corruption — see the next section.
```
</details>

Config lives in `pubspec.yaml` under `flutter_launcher_icons:`
- `adaptive_icon_background: "#2F9E44"` (brand green — fallback behind the fg)
- `adaptive_icon_foreground` / `adaptive_icon_monochrome`
- `adaptive_icon_foreground_inset: 0` (foreground bleeds full; safe zone is baked into the art)
- `remove_alpha_ios: true` (Apple rejects icons with an alpha channel)

## ⚠️ flutter_launcher_icons corrupts an Xcode build setting

`dart run flutter_launcher_icons` (≤ 0.14.4, the latest, and also upstream
`master`) rewrites `ios/Runner.xcodeproj/project.pbxproj` on every run, changing

```
ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;   ->   = AppIcon;
```

The tool only means to set `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`, but its
matcher is an over-broad `line.contains('ASSETCATALOG')`, so it clobbers this
unrelated boolean too (Xcode 15 "asset symbol framework extensions"; a string
where a `YES`/`NO` belongs). Harmless for a Flutter Runner, but it is unintended,
invalid, and recurs on every regen.

`scripts/regen-icons.sh` heals it automatically. If you run the generator by
hand, restore the line yourself (or just `git checkout -- ios/Runner.xcodeproj/project.pbxproj`
when no flavour/app-icon-name change was intended). **Do not commit the
`= AppIcon;` value.**

## Rasterising the SVGs ⚠️ alpha gotcha

`qlmanage -t -s 1024 -o . <file>.svg` is convenient **but flattens transparency
to opaque white**. That is fine for the two full-bleed, fully-opaque layers
(`app_icon`, `app_icon_foreground`) but it destroys the **monochrome** layer,
which must keep real alpha.

- Opaque layers: `qlmanage -t -s 1024 -o . app_icon_foreground.svg`
- `app_icon_monochrome.png`: render with an **alpha-preserving** renderer
  (`rsvg-convert -w 1024 -h 1024 app_icon_monochrome.svg -o app_icon_monochrome.png`,
  Inkscape, or `cairosvg`). If only `qlmanage` is available, render it and then
  key the flat white background back to transparent (the glyph is a single flat
  colour, so `alpha = (255 - R) / 224` recovers the exact anti-aliased silhouette).

## Notes

- Keep important detail inside the central ~66% (Android adaptive safe zone).
- Verify legibility down to ~48px, masked to a circle, on white **and** black.
- Sanity check after regenerating: the foreground drawable corners must be
  **green** (not white); the monochrome drawable corners must be **transparent**.
