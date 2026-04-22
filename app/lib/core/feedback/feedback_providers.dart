library;

/// Riverpod providers for feedback service
/// Exposes haptic/audio feedback configuration and triggers

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'feedback_service.dart';

// Initialize feedback service once on app start
final feedbackServiceProvider = FutureProvider<FeedbackService>((ref) async {
  final service = FeedbackService();
  await service.initialize();
  return service;
});

// Expose individual settings as StateNotifiers for reactive UI updates
final hapticEnabledProvider = StateProvider<bool>((ref) {
  return ref
      .watch(feedbackServiceProvider)
      .maybeWhen(data: (service) => service.hapticEnabled, orElse: () => true);
});

final audioEnabledProvider = StateProvider<bool>((ref) {
  return ref
      .watch(feedbackServiceProvider)
      .maybeWhen(data: (service) => service.audioEnabled, orElse: () => true);
});

final beepVolumeProvider = StateProvider<double>((ref) {
  return ref
      .watch(feedbackServiceProvider)
      .maybeWhen(data: (service) => service.beepVolume, orElse: () => 0.8);
});

final hapticIntensityProvider = StateProvider<HapticIntensity>((ref) {
  return ref
      .watch(feedbackServiceProvider)
      .maybeWhen(
        data: (service) => service.hapticIntensity,
        orElse: () => HapticIntensity.medium,
      );
});
