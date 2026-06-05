library;

/// Feedback service for haptic and audio feedback
/// Controls vibration and POS-style beep sounds for OCR events

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'audio_feedback_player.dart';

enum FeedbackType {
  barcodeSuccess,
  expirySuccess,
  receiptSuccess,
  produceSuccess,
}

enum HapticIntensity { light, medium, heavy }

class FeedbackService {
  FeedbackService({AudioFeedbackPlayer? audioPlayer})
    : _audioPlayer = audioPlayer ?? DefaultAudioFeedbackPlayer();

  static void Function(String eventName, Map<String, dynamic> properties)?
  _telemetryLogger;

  static void setTelemetryLogger(
    void Function(String eventName, Map<String, dynamic> properties)? logger,
  ) {
    _telemetryLogger = logger;
  }

  static const _hapticEnabledKey = 'feedback_haptic_enabled';
  static const _audioEnabledKey = 'feedback_audio_enabled';
  static const _beepVolumeKey = 'feedback_beep_volume';
  static const _hapticIntensityKey = 'feedback_haptic_intensity';
  static const _barcodeScannerEnabledKey = 'feedback_scanner_barcode_enabled';
  static const _expiryScannerEnabledKey = 'feedback_scanner_expiry_enabled';
  static const _receiptScannerEnabledKey = 'feedback_scanner_receipt_enabled';
  static const _produceScannerEnabledKey = 'feedback_scanner_produce_enabled';

  late SharedPreferences _prefs;
  late bool _hapticEnabledValue;
  late bool _audioEnabledValue;
  late double _beepVolumeValue;
  late HapticIntensity _hapticIntensityValue;
  late bool _barcodeScannerEnabledValue;
  late bool _expiryScannerEnabledValue;
  late bool _receiptScannerEnabledValue;
  late bool _produceScannerEnabledValue;
  final AudioFeedbackPlayer _audioPlayer;

  bool get hapticEnabled => _hapticEnabledValue;
  bool get audioEnabled => _audioEnabledValue;
  double get beepVolume => _beepVolumeValue;
  HapticIntensity get hapticIntensity => _hapticIntensityValue;
  bool scannerEnabled(FeedbackType type) {
    switch (type) {
      case FeedbackType.barcodeSuccess:
        return _barcodeScannerEnabledValue;
      case FeedbackType.expirySuccess:
        return _expiryScannerEnabledValue;
      case FeedbackType.receiptSuccess:
        return _receiptScannerEnabledValue;
      case FeedbackType.produceSuccess:
        return _produceScannerEnabledValue;
    }
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadCachedValues();
  }

  void _loadCachedValues() {
    _hapticEnabledValue = _prefs.getBool(_hapticEnabledKey) ?? true;
    _audioEnabledValue = _prefs.getBool(_audioEnabledKey) ?? true;
    _beepVolumeValue = _prefs.getDouble(_beepVolumeKey) ?? 0.6;
    final intensityStr = _prefs.getString(_hapticIntensityKey);
    _hapticIntensityValue = _parseHapticIntensity(intensityStr);
    _barcodeScannerEnabledValue =
        _prefs.getBool(_barcodeScannerEnabledKey) ?? true;
    _expiryScannerEnabledValue =
        _prefs.getBool(_expiryScannerEnabledKey) ?? true;
    _receiptScannerEnabledValue =
        _prefs.getBool(_receiptScannerEnabledKey) ?? true;
    _produceScannerEnabledValue =
        _prefs.getBool(_produceScannerEnabledKey) ?? true;
  }

  Future<void> refreshSettings() async {
    _loadCachedValues();
  }

  HapticIntensity _parseHapticIntensity(String? value) {
    if (value == null) {
      return HapticIntensity.medium;
    }

    try {
      return HapticIntensity.values.byName(value);
    } catch (_) {
      return HapticIntensity.medium;
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

  Future<void> previewBeepVolume(double volume) async {
    final previewVolume = volume.clamp(0.0, 1.0);
    _logBeepDiagnostic('feedback_beep_preview_attempted', {
      'source': 'settings_preview',
      'audio_enabled': _audioEnabledValue,
      'volume': previewVolume,
      'outcome': !_audioEnabledValue
          ? 'skipped_audio_disabled'
          : previewVolume <= 0
          ? 'skipped_zero_volume'
          : 'attempted',
    });

    if (!_audioEnabledValue || previewVolume <= 0) {
      return;
    }
    await _triggerBeep(volumeOverride: previewVolume);
  }

  Future<void> setHapticIntensity(HapticIntensity intensity) async {
    _hapticIntensityValue = intensity;
    await _prefs.setString(_hapticIntensityKey, intensity.name);
  }

  Future<void> setScannerEnabled(FeedbackType type, bool enabled) async {
    switch (type) {
      case FeedbackType.barcodeSuccess:
        _barcodeScannerEnabledValue = enabled;
        await _prefs.setBool(_barcodeScannerEnabledKey, enabled);
        return;
      case FeedbackType.expirySuccess:
        _expiryScannerEnabledValue = enabled;
        await _prefs.setBool(_expiryScannerEnabledKey, enabled);
        return;
      case FeedbackType.receiptSuccess:
        _receiptScannerEnabledValue = enabled;
        await _prefs.setBool(_receiptScannerEnabledKey, enabled);
        return;
      case FeedbackType.produceSuccess:
        _produceScannerEnabledValue = enabled;
        await _prefs.setBool(_produceScannerEnabledKey, enabled);
        return;
    }
  }

  /// Trigger feedback for an OCR success event
  Future<void> triggerOcrSuccess(FeedbackType type) async {
    if (!scannerEnabled(type)) {
      _logBeepDiagnostic('feedback_beep_scan_attempted', {
        'source': 'scan',
        'feedback_type': type.name,
        'scanner_enabled': false,
        'audio_enabled': _audioEnabledValue,
        'beep_count': 0,
        'volume': _beepVolumeValue,
        'outcome': 'skipped_scanner_disabled',
      });
      return;
    }

    final feedbackPattern = _feedbackPatternFor(type);

    _logBeepDiagnostic('feedback_beep_scan_attempted', {
      'source': 'scan',
      'feedback_type': type.name,
      'scanner_enabled': true,
      'audio_enabled': _audioEnabledValue,
      'beep_count': feedbackPattern.beepCount,
      'volume': _beepVolumeValue,
      'outcome': !_audioEnabledValue
          ? 'skipped_audio_disabled'
          : feedbackPattern.beepCount > 0
          ? 'attempted'
          : 'skipped_no_beeps',
    });

    if (_hapticEnabledValue) {
      for (var i = 0; i < feedbackPattern.hapticCount; i++) {
        await _triggerHaptic();
      }
    }
    if (_audioEnabledValue) {
      for (var i = 0; i < feedbackPattern.beepCount; i++) {
        await _triggerBeep();
      }
    }
  }

  _FeedbackPattern _feedbackPatternFor(FeedbackType type) {
    switch (type) {
      case FeedbackType.barcodeSuccess:
        return const _FeedbackPattern(hapticCount: 1, beepCount: 1);
      case FeedbackType.expirySuccess:
        return const _FeedbackPattern(hapticCount: 1, beepCount: 1);
      case FeedbackType.receiptSuccess:
        return const _FeedbackPattern(hapticCount: 1, beepCount: 2);
      case FeedbackType.produceSuccess:
        return const _FeedbackPattern(hapticCount: 2, beepCount: 1);
    }
  }

  /// Trigger haptic feedback based on configured intensity
  Future<void> _triggerHaptic() async {
    try {
      switch (_hapticIntensityValue) {
        case HapticIntensity.light:
          await HapticFeedback.lightImpact();
          return;
        case HapticIntensity.medium:
          await HapticFeedback.mediumImpact();
          return;
        case HapticIntensity.heavy:
          await HapticFeedback.heavyImpact();
          return;
      }
    } catch (_) {
      // Silently fail on devices without haptic support
    }
  }

  /// Trigger a lightweight system click sound.
  Future<void> _triggerBeep({double? volumeOverride}) async {
    try {
      final volume = (volumeOverride ?? _beepVolumeValue).clamp(0.0, 1.0);
      if (volume <= 0) {
        return;
      }
      await _audioPlayer.playBeep(volume: volume);
    } catch (_) {
      // Silently fail if system audio feedback is not available
    }
  }

  void _logBeepDiagnostic(String eventName, Map<String, dynamic> properties) {
    final logger = _telemetryLogger;
    if (logger == null) {
      return;
    }

    logger(eventName, properties);
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

class _FeedbackPattern {
  const _FeedbackPattern({required this.hapticCount, required this.beepCount});

  final int hapticCount;
  final int beepCount;
}
