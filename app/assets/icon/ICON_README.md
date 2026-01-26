# ZeroSpoils App Icon

## Quick Setup

1. **Create your app icon** (1024x1024 PNG with transparency):
   - Simple design: Green circular background with white "0" or leaf symbol
   - Color scheme: Primary green (#4CAF50) for food/sustainability theme
   - Save as `app_icon.png` in this folder

2. **Create adaptive foreground** (1024x1024 PNG):
   - Same icon but with padding/margins for Android adaptive icons
   - Save as `app_icon_foreground.png` in this folder

3. **Generate launcher icons**:
   ```bash
   cd app
   flutter pub get
   dart run flutter_launcher_icons
   ```

## Temporary Placeholder

Until you create custom icons, here's a simple approach:

**Option A - Use online tool:**
1. Visit https://icon.kitchen or https://www.appicon.co
2. Upload a simple design (green circle with "0" or leaf)
3. Download and extract to this folder

**Option B - Use existing Flutter icon (for testing):**
The default Flutter icon will be used until you replace it.

## Icon Design Tips

- **Keep it simple**: Recognizable at 48x48px
- **High contrast**: Clear against any background
- **No text** (except single letter/number)
- **Brand colors**: Green for food waste/sustainability theme
- **Test on device**: Check how it looks on home screen
