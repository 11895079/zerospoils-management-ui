library;

/// Riverpod providers for feedback service
/// Exposes haptic/audio feedback configuration and triggers

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/di/service_locator.dart' show telemetryClientProvider;
import 'feedback_service.dart';

// Initialize feedback service once on app start
final feedbackServiceProvider = FutureProvider<FeedbackService>((ref) async {
  final telemetry = ref.watch(telemetryClientProvider);
  FeedbackService.setTelemetryLogger((eventName, properties) {
    telemetry.enqueue({'name': eventName, 'properties': properties});
  });
  final service = FeedbackService();
  await service.initialize();
  return service;
});

class FeedbackSettings {
  const FeedbackSettings({
    required this.hapticEnabled,
    required this.audioEnabled,
    required this.beepVolume,
    required this.hapticIntensity,
  });

  final bool hapticEnabled;
  final bool audioEnabled;
  final double beepVolume;
  final HapticIntensity hapticIntensity;

  FeedbackSettings copyWith({
    bool? hapticEnabled,
    bool? audioEnabled,
    double? beepVolume,
    HapticIntensity? hapticIntensity,
  }) {
    return FeedbackSettings(
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      beepVolume: beepVolume ?? this.beepVolume,
      hapticIntensity: hapticIntensity ?? this.hapticIntensity,
    );
  }
}

class FeedbackSettingsNotifier extends AsyncNotifier<FeedbackSettings> {
  late final FeedbackService _service;

  @override
  Future<FeedbackSettings> build() async {
    _service = await ref.watch(feedbackServiceProvider.future);
    return FeedbackSettings(
      hapticEnabled: _service.hapticEnabled,
      audioEnabled: _service.audioEnabled,
      beepVolume: _service.beepVolume,
      hapticIntensity: _service.hapticIntensity,
    );
  }

  Future<void> setHapticEnabled(bool value) async {
    await _service.setHapticEnabled(value);
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(hapticEnabled: value));
  }

  Future<void> setAudioEnabled(bool value) async {
    await _service.setAudioEnabled(value);
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(audioEnabled: value));
  }

  Future<void> setBeepVolume(double value) async {
    await _service.setBeepVolume(value);
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(beepVolume: value.clamp(0.0, 1.0)));
  }

  Future<void> setHapticIntensity(HapticIntensity value) async {
    await _service.setHapticIntensity(value);
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(hapticIntensity: value));
  }
}

final feedbackSettingsProvider =
    AsyncNotifierProvider<FeedbackSettingsNotifier, FeedbackSettings>(
      FeedbackSettingsNotifier.new,
    );

final hapticEnabledProvider = Provider<bool>((ref) {
  return ref
      .watch(feedbackSettingsProvider)
      .maybeWhen(
        data: (settings) => settings.hapticEnabled,
        orElse: () => true,
      );
});

final audioEnabledProvider = Provider<bool>((ref) {
  return ref
      .watch(feedbackSettingsProvider)
      .maybeWhen(data: (settings) => settings.audioEnabled, orElse: () => true);
});

final beepVolumeProvider = Provider<double>((ref) {
  return ref
      .watch(feedbackSettingsProvider)
      .maybeWhen(data: (settings) => settings.beepVolume, orElse: () => 0.8);
});

final hapticIntensityProvider = Provider<HapticIntensity>((ref) {
  return ref
      .watch(feedbackSettingsProvider)
      .maybeWhen(
        data: (settings) => settings.hapticIntensity,
        orElse: () => HapticIntensity.medium,
      );
});
