library;

/// Feedback service for haptic and audio feedback
/// Controls vibration and POS-style beep sounds for OCR events

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

enum FeedbackType {
  barcodeSuccess,
  expirySuccess,
  receiptSuccess,
  produceSuccess,
}

enum HapticIntensity { light, medium, heavy }

class FeedbackService {
  static const _hapticEnabledKey = 'feedback_haptic_enabled';
  static const _audioEnabledKey = 'feedback_audio_enabled';
  static const _beepVolumeKey = 'feedback_beep_volume';
  static const _hapticIntensityKey = 'feedback_haptic_intensity';

  late SharedPreferences _prefs;
  late bool _hapticEnabledValue;
  late bool _audioEnabledValue;
  late double _beepVolumeValue;
  late HapticIntensity _hapticIntensityValue;

  bool get hapticEnabled => _hapticEnabledValue;
  bool get audioEnabled => _audioEnabledValue;
  double get beepVolume => _beepVolumeValue;
  HapticIntensity get hapticIntensity => _hapticIntensityValue;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _hapticEnabledValue = _prefs.getBool(_hapticEnabledKey) ?? true;
    _audioEnabledValue = _prefs.getBool(_audioEnabledKey) ?? true;
    _beepVolumeValue = _prefs.getDouble(_beepVolumeKey) ?? 0.8;
    final intensityStr = _prefs.getString(_hapticIntensityKey);
    if (intensityStr != null) {
      _hapticIntensityValue = HapticIntensity.values.byName(intensityStr);
    } else {
      _hapticIntensityValue = HapticIntensity.medium;
    }
  }

  Future<void> setHapticEnabled(bool enabled) async {
    _hapticEnabledValue = enabled;
    await _prefs.setBool(_hapticEnabledKey, enabled);
  }

  Future<void> setAudioEnabled(bool enabled) async {
    _audioEnabledValue = enabled;
    await _prefs.setBool(_audioEnabledKey, enabled);
  }

  Future<void> setBeepVolume(double volume) async {
    _beepVolumeValue = volume.clamp(0.0, 1.0);
    await _prefs.setDouble(_beepVolumeKey, _beepVolumeValue);
  }

  Future<void> setHapticIntensity(HapticIntensity intensity) async {
    _hapticIntensityValue = intensity;
    await _prefs.setString(_hapticIntensityKey, intensity.name);
  }

  /// Trigger feedback for an OCR success event
  Future<void> triggerOcrSuccess(FeedbackType type) async {
    if (_hapticEnabledValue) {
      await _triggerHaptic();
    }
    if (_audioEnabledValue) {
      await _triggerBeep();
    }
  }

  /// Trigger haptic feedback based on configured intensity
  Future<void> _triggerHaptic() async {
    try {
      switch (_hapticIntensityValue) {
        case HapticIntensity.light:
          await HapticFeedback.lightImpact();
        case HapticIntensity.medium:
          await HapticFeedback.mediumImpact();
        case HapticIntensity.heavy:
          await HapticFeedback.heavyImpact();
      }
    } catch (_) {
      // Silently fail on devices without haptic support
    }
  }

  /// Trigger POS-style beep sound
  /// Note: Actual audio playback would require audio_players package
  /// For now, we use SystemSounds as a placeholder
  Future<void> _triggerBeep() async {
    try {
      // Use system sounds (platform-specific implementation)
      // On iOS: UISystemSoundType (kSystemSoundID_Vibrate)
      // On Android: ToneGenerator (TONE_CDMA_PIP)
      await SystemChannels.platform
          .invokeMethod('playBeepSound', {'volume': _beepVolumeValue});
    } catch (_) {
      // Silently fail if audio not available
    }
  }

  /// Selection haptic feedback (selection wheel on iOS)
  Future<void> triggerSelection() async {
    if (!_hapticEnabledValue) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Error feedback (3 short vibrations)
  Future<void> triggerError() async {
    if (!_hapticEnabledValue) return;
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}
