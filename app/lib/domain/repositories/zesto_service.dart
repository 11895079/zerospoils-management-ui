library;

/// Zesto Service - Handles mascot triggers, messaging, and state
/// Phase 1: Core triggers with anti-spam, message history, and educational tips

import 'dart:async';
import 'dart:math';
import 'package:zerospoils/domain/models/zesto_model.dart';
import '../../core/utils/app_logger.dart';

class ZestoService {
  // Message pools for Phase 1 triggers
  static const Map<MascotMessageType, List<String>> messagePool = {
    // Celebrations
    MascotMessageType.consumed: [
      'Saved it! 🎉',
      'Zero waste! 💚',
      'Yum! 😋',
      'Perfect! 🌟',
      'Well done! 💪',
    ],
    MascotMessageType.quickSave: [
      'Just in time! ⏰',
      'Beat the clock! 🏃',
      'Close call! 💚',
      'Saved at the buzzer! 🔔',
      'Nick of time! ⌛',
    ],
    MascotMessageType.badgeUnlocked: [
      'New badge! 🏆',
      'Achievement unlocked! 🎉',
      'You earned it! 💪',
      'Badge get! 🌟',
      'Congrats! 🎊',
    ],
    MascotMessageType.streakMilestone: [
      '5 days strong! 🔥',
      '10 days! Legendary! ⚡',
      '30 days! Amazing! 🤯',
      '100 days! Incredible! 🏆',
      'On fire! 🔥',
    ],
    MascotMessageType.savingsMilestone: [
      '\$50 saved! 💰',
      'You\'re rich! 💵',
      'Money in the bank! 🏦',
      'Cha-ching! 💸',
      'Savings hero! 💳',
    ],
    MascotMessageType.zeroWaste: [
      'Perfect week! 🌟',
      'No waste! 🎉',
      'Flawless! 💚',
      '100% saved! 💯',
      'Waste-free! 🌱',
    ],

    // Tips & Educational
    MascotMessageType.wasted: [
      '💡 Tip: Better luck next time!',
      'Learn & improve! 📈',
      'Storage tips help! 🧊',
      'No judgment here! 💚',
      'Every save counts! 🌱',
    ],
    MascotMessageType.expiryAlert: [
      '3 items expiring! ⏰',
      'Check fridge! 🥛',
      'Use these soon! 🍎',
      'Expiry alert! 🔔',
      'Time to cook! 🍳',
    ],

    // Welcome
    MascotMessageType.dailyWelcome: [
      'Good morning! ☀️',
      'Welcome back! 👋',
      'Let\'s check in! 📱',
      'Ready to save? 🌟',
      'New day! 🌅',
    ],

    // First-time
    MascotMessageType.firstItem: [
      'Welcome! 🎉',
      'Great start! 💚',
      'Your first item! 🌟',
      'Nice work! 💪',
      'Let\'s save food! 🌱',
    ],

    // Existing celebrations
    MascotMessageType.celebration: [
      'Amazing! 🎉',
      'You\'re crushing it! 💚',
      'Keep going! 🌟',
      'Nice work! 🌟',
      'Awesome! 💪',
    ],
  };

  // Anti-spam configuration
  static const Duration antiSpamGap = Duration(seconds: 5);
  static const int messageHistorySize = 3;

  // State
  DateTime? _lastMessageTime;
  final List<String> _messageHistory = [];
  final _stateController = StreamController<ZestoState>.broadcast();
  ZestoState _currentState = const ZestoState();

  // Dependencies (injected)
  final MascotSettings Function() getSettings;
  final Map<String, List<String>> Function() getStorageTips;

  ZestoService({required this.getSettings, required this.getStorageTips});

  /// Get state stream for UI
  Stream<ZestoState> get stateStream => _stateController.stream;

  /// Get current state
  ZestoState get currentState => _currentState;

  /// Dispose resources
  void dispose() {
    _stateController.close();
  }

  /// Main trigger method - checks settings, anti-spam, and shows mascot if conditions met
  Future<void> showMascot(
    MascotMessageType messageType, {
    Map<String, dynamic>? context,
  }) async {
    // Check if enabled
    final settings = getSettings();
    if (!settings.enabled) return;

    // Check frequency filter
    if (settings.frequency == MascotFrequency.never) return;

    // Check message type filter (for "always" mode)
    if (settings.frequency == MascotFrequency.always) {
      if (!_shouldShowMessageType(messageType, settings)) {
        return;
      }
    }

    // Check frequency filter (for "milestones" mode)
    if (settings.frequency == MascotFrequency.milestones) {
      if (!_isMilestoneEvent(messageType)) {
        return;
      }
    }

    // Check anti-spam (5 second gap)
    if (!_canShowMascot()) {
      appLogger.d(
        'Zesto spam prevented (${DateTime.now().difference(_lastMessageTime ?? DateTime.now()).inMilliseconds}ms since last)',
      );
      return;
    }

    // Select message
    String? message = _selectMessage(messageType, context);
    if (message == null) return;

    // Update state
    _updateState(
      isVisible: true,
      currentMessage: message,
      currentMessageType: messageType,
      isAnimating: true,
    );

    // Update timestamp
    _lastMessageTime = DateTime.now();

    // Log telemetry
    _logTelemetry(messageType, message);

    // Auto-dismiss after 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    _updateState(isVisible: false, isAnimating: false);
  }

  /// Select message with deduplication
  String? _selectMessage(
    MascotMessageType messageType,
    Map<String, dynamic>? context,
  ) {
    List<String> messages = messagePool[messageType] ?? [];

    // Handle wasted items with storage tips
    if (messageType == MascotMessageType.wasted &&
        context?['itemCategory'] != null) {
      final tips = getStorageTips();
      final category = (context!['itemCategory'] as String).toLowerCase();
      final categoryTips = tips[category] ?? tips['general'] ?? [];
      if (categoryTips.isNotEmpty) {
        return categoryTips[Random().nextInt(categoryTips.length)];
      }
    }

    if (messages.isEmpty) return null;

    // Select random message
    String selected = messages[Random().nextInt(messages.length)];

    // Re-roll if in last 3 messages
    if (_messageHistory.contains(selected) && messages.length > 1) {
      selected = messages[Random().nextInt(messages.length)];
    }

    // Update history
    _messageHistory.add(selected);
    if (_messageHistory.length > messageHistorySize) {
      _messageHistory.removeAt(0);
    }

    return selected;
  }

  /// Check if anti-spam allows mascot
  bool _canShowMascot() {
    if (_lastMessageTime == null) return true;
    final gap = DateTime.now().difference(_lastMessageTime!);
    return gap.compareTo(antiSpamGap) >= 0;
  }

  /// Check if message type should be shown based on settings
  bool _shouldShowMessageType(MascotMessageType type, MascotSettings settings) {
    switch (type) {
      // Celebrations
      case MascotMessageType.consumed:
      case MascotMessageType.quickSave:
      case MascotMessageType.badgeUnlocked:
      case MascotMessageType.streakMilestone:
      case MascotMessageType.savingsMilestone:
      case MascotMessageType.zeroWaste:
      case MascotMessageType.celebration:
        return settings.showCelebrations;

      // Tips
      case MascotMessageType.wasted:
      case MascotMessageType.expiryAlert:
        return settings.showTips;

      // Welcome
      case MascotMessageType.dailyWelcome:
        return settings.showDailyWelcome;

      // First item (always show)
      case MascotMessageType.firstItem:
        return true;
    }
  }

  /// Check if event is a milestone (for "milestones only" frequency)
  bool _isMilestoneEvent(MascotMessageType type) {
    return {
      MascotMessageType.badgeUnlocked,
      MascotMessageType.streakMilestone,
      MascotMessageType.savingsMilestone,
      MascotMessageType.zeroWaste,
      // Note: Streak < 10 days and Savings < $100 are NOT milestones
    }.contains(type);
  }

  /// Update internal state and notify listeners
  void _updateState({
    bool? isVisible,
    String? currentMessage,
    MascotMessageType? currentMessageType,
    bool? isAnimating,
  }) {
    _currentState = _currentState.copyWith(
      isVisible: isVisible ?? _currentState.isVisible,
      currentMessage: currentMessage ?? _currentState.currentMessage,
      currentMessageType:
          currentMessageType ?? _currentState.currentMessageType,
      isAnimating: isAnimating ?? _currentState.isAnimating,
    );
    _stateController.add(_currentState);
  }

  /// Log telemetry (placeholder - integrate with actual telemetry service)
  void _logTelemetry(MascotMessageType type, String message) {
    appLogger.i('Zesto shown: ${type.name} → "$message"');
    // TODO: Integrate with telemetry service
    // telemetryService.logEvent('mascot_shown', {
    //   'messageType': type.name,
    //   'message': message,
    // });
  }
}
