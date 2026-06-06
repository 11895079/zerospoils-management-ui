# 203: Haptic and Sound Feedback Settings

**Epic:** UX Polish  
**Milestone:** M3 (MVP Quality & Shopping)  
**Priority:** P1  
**Size:** M  
**Dependencies:** 197 (packaged item fast add), 196 (live expiry OCR), 201 (receipt line-item extraction), 202 (fresh produce recognition)

---

## Context

The app already contains localisation strings for a full "Feedback & Sounds" settings section — including per-scanner haptic and beep toggles (barcode, expiry, receipt, produce), an adjustable beep volume, and a haptic intensity selector. These strings are committed but the backing settings UI and user-preference storage do not exist.

The scan screens are inconsistent:
- **Barcode capture** (`barcode_capture_screen.dart`): calls `HapticFeedback.selectionClick()` unconditionally on recognition — not gated behind any user preference.
- **Expiry OCR** (`expiry_ocr_capture_screen.dart`): calls `HapticFeedback.selectionClick()` unconditionally on date capture.
- **Packaged item fast add** (`packaged_item_fast_add_screen.dart`): calls `HapticFeedback.selectionClick()` and `HapticFeedback.mediumImpact()` unconditionally.
- **Receipt live scan** (`receipt_live_scan_screen.dart`): **no haptic or sound calls at all** — capture press is silent.
- **Fresh produce** (`packaged_item_fast_add_screen.dart` produce mode): no dedicated haptic on produce-label recognition.

No beep (POS-style scan confirmation tone) is implemented on any scanner. The settings screen has a `_soundEnabled` toggle but this controls notification sounds, not scan sounds.

---

## Goal

Wire up the "Feedback & Sounds" section in Settings with persistent user preferences, add a POS-style confirmation beep to all scan events, and ensure haptic feedback is applied consistently and respects the user's preference across all four scanner entry points.

---

## Expected behavior

- Settings screen shows a "Feedback & Sounds" section (using existing l10n keys) with:
  - **Haptic Feedback** master toggle (on by default); disabling it suppresses all scan haptics
  - **Sound Effects** master toggle (on by default); disabling it suppresses all scan beeps
  - **Beep Volume** slider 0–100% (default 60%), only enabled when Sound Effects is on
  - Individual per-scanner toggles (on by default): Barcode, Expiry, Receipt, Produce — lets users silence one scanner without affecting others
- On successful barcode recognition, the app plays a short POS-style beep and/or triggers a haptic pattern (medium impact), subject to user preferences
- On successful expiry-date capture, the app plays a short confirmation beep and/or medium haptic, subject to preferences
- On receipt auto-capture or manual capture confirming ≥1 item line detected, the app plays a short beep and/or heavy haptic, subject to preferences
- On fresh-produce sticker recognition, the app plays a short beep and/or medium haptic, subject to preferences
- Preferences are stored via `SharedPreferences` and survive app restart; reads are synchronous after the settings screen loads them once into a Riverpod state
- When the device is in silent mode (iOS) or Do Not Disturb, audio is suppressed by the OS; haptics are unaffected
- Beep audio is a short single-tone asset (≤200 ms, included in `assets/sounds/`); no external audio package required — use `SystemSound.click` as a lightweight fallback if a custom asset is not available at MVP

---

## Acceptance criteria (Definition of Done)

- [x] "Feedback & Sounds" section appears in Settings screen using existing l10n strings
- [x] Haptic Feedback master toggle persists to `SharedPreferences` and suppresses all scan haptics when off
- [x] Sound Effects master toggle persists and suppresses all scan beeps when off
- [x] Beep Volume slider persists and scales beep amplitude 0–100%
- [x] Per-scanner toggles persist independently (barcode, expiry, receipt, produce)
- [x] Barcode capture fires medium haptic + beep on recognition, gated by preference
- [x] Expiry OCR fires medium haptic + beep on date capture, gated by preference
- [x] Receipt live scan fires heavy haptic + beep on manual or auto capture, gated by preference
- [x] Fresh produce label recognition fires medium haptic + beep on sticker read, gated by preference
- [x] Toggling preferences from Settings takes effect on the next scan without restarting the app (Riverpod `StateProvider` / `AsyncNotifier` approach recommended)
- [x] Unit/widget tests added or updated (see test plan)
- [x] Offline-first behavior verified (no network dependency — all preferences are local)
- [x] Accessibility: sound and haptic toggles have semantic labels; beep is never the sole feedback channel (haptic and/or visual confirmation always present)

---

## Out of scope

- Custom ringtone upload or beep selection
- Haptic patterns beyond Flutter's built-in `HapticFeedback` API (no platform-channel custom vibration engine)
- Background audio or notification sounds (separate from scan feedback)
- Android-specific audio focus handling beyond default Flutter behaviour

---

## Implementation notes

- **Preference keys** (add to a `ScanFeedbackPreferencesStore` or extend the existing preferences store):
  - `scan_haptic_enabled` (bool, default `true`)
  - `scan_sound_enabled` (bool, default `true`)
  - `scan_beep_volume` (double 0.0–1.0, default `0.6`)
  - `scan_haptic_barcode_enabled` (bool, default `true`)
  - `scan_haptic_expiry_enabled` (bool, default `true`)
  - `scan_haptic_receipt_enabled` (bool, default `true`)
  - `scan_haptic_produce_enabled` (bool, default `true`)
- **Beep asset**: add `assets/sounds/scan_beep.wav` (a short 200 ms 1 kHz tone). Use `SystemSound.click` as a temporary stand-in until the asset is available. Register the asset in `pubspec.yaml`.
- **Audio playback**: avoid adding a heavy audio plugin just for a beep. `SystemSound.click` (Flutter core) is sufficient for MVP. If more control is needed, `audioplayers` is already common in Flutter projects and is lightweight.
- **Riverpod integration**: expose a `scanFeedbackPreferencesProvider` that reads from `SharedPreferences` so any screen can call `ref.read(scanFeedbackPreferencesProvider)` to check current preferences before firing haptic/sound.
- **Receipt scan**: `receipt_live_scan_screen.dart` `_capturePhoto()` method is the right place to add the haptic + beep call after a successful photo capture.
- Existing unconditional `HapticFeedback` calls in barcode/expiry/packaged-item screens should be wrapped to check the preference before firing.

## Implementation status update (2026-06-05)

- Added `FeedbackService` persistence for master haptic/audio toggles, beep volume, haptic intensity, and per-scanner toggles.
- Wired the Settings screen with the full "Feedback & Sounds" section and persisted controls.
- Routed barcode, expiry, receipt, and produce scan success events through `FeedbackRuntime`.
- Added widget coverage for the settings controls, persistence, and slider gating.

---

## Test plan

**Automated:**
- Unit test: `ScanFeedbackPreferencesStore` reads and writes all preference keys correctly; defaults match spec
- Widget test: Settings "Feedback & Sounds" section renders all toggles and slider; toggling haptic master switch disables per-scanner rows
- Widget test: `ReceiptLiveScanScreen` triggers haptic + sound on `_capturePhoto` when preferences are enabled; no haptic/sound when master toggle is off (mock the preferences provider)
- Widget test: `BarcodeCaptureScreen` haptic is gated behind preference (not fired when haptic master is off)

**Manual:**
1. Open Settings → verify "Feedback & Sounds" section appears with all toggles and the volume slider
2. Leave all toggles on; scan a barcode — verify vibration and beep play
3. Scan a receipt — verify vibration and beep play on capture button press (currently silent)
4. Scan an expiry date — verify vibration and beep on recognition
5. Scan a produce sticker — verify vibration and beep on recognition
6. Toggle "Haptic Feedback" off in Settings; scan a barcode — verify no vibration (beep still plays)
7. Toggle "Sound Effects" off; scan a barcode — verify no beep (haptic still plays)
8. Set Beep Volume to 0% — verify scan is silent
9. Turn off "Barcode" per-scanner toggle; scan a barcode — verify no haptic or beep; expiry scan still fires
10. Verify preferences survive app kill + relaunch

---

## Dependencies

- M3/197 packaged item fast add (barcode + expiry scan entry point)
- M3/196 live expiry OCR multi-angle capture
- M3/201 receipt line-item extraction with AR overlay (receipt scan entry point)
- M3/202 fresh produce / packaged item recognition (produce scan entry point)
