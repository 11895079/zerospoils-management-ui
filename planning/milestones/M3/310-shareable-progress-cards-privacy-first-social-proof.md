# M3-310: Shareable Progress Cards — Privacy-First Social Proof

**Status:** Planning  
**Milestone:** M3 (MVP Features)  
**Priority:** P2 (Enhancement)  
**Effort:** M (Medium)  
**Labels:** `social`, `sharing`, `privacy-first`

## Context

Users want to celebrate progress but shouldn't have to expose personal data (item names, expiry dates). Shareable progress cards provide:
- **Social proof:** Show friends you're reducing waste without revealing household inventory
- **Motivation:** External accountability drives behavior change
- **Privacy:** Only summary stats (%, $, CO₂) are shared — never raw data

Already designed in prototype (`progress.html`): "Share Your Impact" card with 3 options.

## Goal

Implement shareable progress cards that allow users to:
- Share weekly/monthly waste reduction % as text or image
- Share financial savings and environmental impact
- Do this without exposing any personal inventory data
- Work entirely offline (no backend required for basic sharing)

## Expected Behavior

### Share Card Content

Card shows:
- **Waste %:** "12% waste this month" (downward trend from last month)
- **$ Saved:** "$124 saved lifetime"
- **CO₂ Avoided:** "8.2 kg CO₂ avoided"
- **Period:** "This Month" or "This Week"
- **Emoji/visual:** Simple, motivational design

### Share Methods

1. **Copy Text**
   - Generate: "I'm reducing food waste with ZeroSpoils! This month: 12% waste, $124 saved, 8.2 kg CO₂ avoided. Join me!"
   - User taps: copies to clipboard
   - Share to: Messages, Email, WhatsApp, Twitter, etc.

2. **Share as Image**
   - Render card as image (emoji, stats, date, "ZeroSpoils" branding)
   - Save to gallery or direct share (iOS/Android native share)
   - Allows posting to Instagram, Facebook, Snapchat

3. **Copy Link** (M4+)
   - Public profile page (requires backend + auth)
   - Link shows public progress (no household data)
   - Deferred to M4

### Time Period Options

- This Week
- This Month
- Lifetime
- Custom range (future enhancement)

## Acceptance Criteria

- [ ] **Share Card UI:** Displays waste %, savings, CO₂ on Progress tab
- [ ] **Copy Text:** Generates correct text, copies to clipboard (toast confirms)
- [ ] **Share Image:** Renders card as image using canvas/screenshot, triggers device share
- [ ] **Privacy Verified:** Card contains ONLY stats (%, $, CO₂, period) — no item names, dates, or quantities
- [ ] **Offline:** All sharing works without internet (no backend calls)
- [ ] **Analytics:** Track share events (share_initiated, share_method, period)
- [ ] **Tests:** Unit tests for text generation; widget tests for image rendering; integration test for full share flow
- [ ] **Accessibility:** Share card content readable with screen reader

## Out of Scope

- Public profiles (requires backend, M4+)
- Leaderboards (social competition, M5+)
- Friend sharing with notifications (requires friends system, M6)
- Custom branding/themes (future enhancement)

## Implementation Notes

### Share Card Service

```dart
class ShareCardService {
  // Generate shareable text
  String generateShareText({
    required double wastePercent,
    required double moneySaved,
    required double co2Avoided,
    required String period, // 'This Week', 'This Month', 'Lifetime'
  }) {
    return '🌍 I\'m reducing food waste with ZeroSpoils! '
        '$period: ${wastePercent.toStringAsFixed(0)}% waste, '
        '\$${moneySaved.toStringAsFixed(0)} saved, '
        '${co2Avoided.toStringAsFixed(1)} kg CO₂ avoided. Join me!';
  }

  // Generate image card
  Future<Image> generateShareImage({
    required double wastePercent,
    required double moneySaved,
    required double co2Avoided,
    required String period,
  }) async {
    // Use screenshot or custom painter to render card
    // Card layout: emoji + stats + "ZeroSpoils" watermark
    // Return Image widget or raw bytes
  }

  // Share to device clipboard
  Future<void> shareToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showToast('✓ Copied to clipboard!');
  }

  // Share image via device share sheet
  Future<void> shareImage(Uint8List imageBytes) async {
    await Share.file(
      'zerospoils-progress.png',
      imageBytes,
      mimeType: 'image/png',
    );
  }
}
```

### UI: Share Card Modal

Already designed in prototype; implement in Flutter:

```dart
class ShareCardSheet extends StatefulWidget {
  final double wastePercent;
  final double moneySaved;
  final double co2Avoided;
  final String period;

  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      child: Column(
        children: [
          Text('Share Your Progress'),
          // Card display (stats)
          ListTile(
            leading: Icon(Icons.text_fields),
            title: Text('Copy Text'),
            onTap: () => _copyText(),
          ),
          ListTile(
            leading: Icon(Icons.image),
            title: Text('Share as Image'),
            onTap: () => _shareImage(),
          ),
          // Copy Link (disabled in M3)
        ],
      ),
    );
  }
}
```

### Privacy Checks

Before allowing share:
```dart
void validateShareContent(ShareCard card) {
  assert(!card.shareText.contains('milk'),); // No item names
  assert(!card.shareText.contains('Jan')); // No dates
  assert(!card.shareText.contains('Fridge')); // No locations
  // Only: %, $, CO₂ allowed
}
```

### Data Model

```dart
class ShareCard {
  final double wastePercent;
  final double moneySaved;
  final double co2Avoided;
  final String period; // 'This Week', 'This Month', 'Lifetime'
  final DateTime generatedAt;

  String get shareText => ShareCardService().generateShareText(...);
  Future<Image> get image => ShareCardService().generateShareImage(...);
}
```

## Test Plan

**Automated:**
- Unit test: Share text generation (no personal data, correct format)
- Unit test: Image rendering (card displays correctly)
- Widget test: Share sheet UI appears on button tap
- Widget test: Copy to clipboard works
- Integration test: User taps Share → sees options → copies text → toast shown

**Manual:**
1. Navigate to Progress tab
2. Tap "Share Your Impact" button
3. See modal with 3 options (Copy Text, Share Image, Copy Link)
4. Tap "Copy Text" → verify toast "Copied to clipboard!"
5. Open Notes app → paste → verify text contains only: waste %, $, CO₂
6. Go back, tap "Share as Image" → device share sheet appears
7. Share to Messages → image appears (card with emoji, stats)
8. Verify no item names, dates, or locations in image
9. Test on iOS (Clipboard, Share extension) and Android (clipboard, native share)

## Dependencies

- **Progress Tab** (Issue 060): UI in place to display share button
- **Analytics Setup** (Issue 040): Track share events
- **Screenshot/Canvas Package:** `screenshot: ^1.2.3` or `image: ^3.0.0` for image rendering

## Related Issues

- **Issue 300:** Achievement badges (users will want to share badges + stats together)
- **Issue 320:** Social framework (M4, builds on this for public profiles)

---

**Success:** Users share progress with friends without exposing personal data; all sharing works offline; shares are motivational and accurate.
