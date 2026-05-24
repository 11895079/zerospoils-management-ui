library;

/// Zesto Service - Handles mascot triggers, messaging, and state
/// Phase 1: Core triggers with anti-spam, message history, and educational tips

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/domain/models/zesto_model.dart';

import '../../core/utils/app_logger.dart';

typedef ZestoTelemetryLogger =
    void Function(String eventName, Map<String, Object?> properties);

/// Path to the bundled storage-tip pool. Loaded once during hydration; the
/// JSON is the single source of truth — there is no compiled-in fallback,
/// so divergence between asset and code is impossible.
const _storageTipsAssetPath = 'assets/data/storage_tips.json';

class ZestoService {
  static const String _lastMessageTimeKey = 'zesto_last_message_time_ms';
  static const String _messageHistoryKey = 'zesto_message_history';
  static const String _lastDailyWelcomeDateKey =
      'zesto_last_daily_welcome_date';
  static const String _unlockProgressKey = 'zesto_unlock_progress';

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

    // Add actions
    MascotMessageType.itemAdded: [
      'Nice add! Pantry power-up. 🥑',
      'Locked in. Future-you says thanks! ✅',
      'Tracked and ready. Let\'s keep rolling! 📦',
      'Great catch. That one won\'t be forgotten. 👀',
      'Inventory leveled up! 🌟',
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
  static const Duration _minimumDisplayDuration = Duration(seconds: 4);
  static const Duration _tipDisplayDuration = Duration(seconds: 6);
  static const Set<int> streakMilestones = {5, 10, 30, 100};
  static const List<double> savingsMilestones = [50, 100, 500];

  // State
  DateTime? _lastMessageTime;
  DateTime? _visibleSince;
  DateTime? _lastDailyWelcomeDate;
  final List<String> _messageHistory = [];
  MascotUnlockProgress _unlockProgress = const MascotUnlockProgress();
  final _stateController = StreamController<ZestoState>.broadcast();
  ZestoState _currentState = const ZestoState();
  Future<void>? _hydrateFuture;
  SharedPreferences? _prefs;
  // Pending auto-dismiss timer for the currently-visible mascot. Cancelled
  // when (a) the user manually dismisses, (b) showMascot starts a new
  // mascot before this one's auto-dismiss elapses, or (c) the service is
  // disposed. Keeping a single field is safe because the mascot is a
  // singleton overlay — only one can be visible at a time.
  Timer? _autoDismissTimer;

  // Dependencies (injected)
  final MascotSettings Function() getSettings;
  final DateTime Function() _now;
  final Random _random;
  final ZestoTelemetryLogger? _telemetryLogger;
  final Duration _displayDuration;
  final AssetBundle _assetBundle;
  /// When true, skip reading from and writing to [SharedPreferences]. Set this
  /// in widget tests to prevent cross-test anti-spam state pollution.
  final bool _skipPersistence;

  /// Storage tips loaded from `assets/data/storage_tips.json` during
  /// hydration. Empty until the load completes; if the load fails the
  /// service falls back to the generic message pool for wasted items.
  Map<String, List<String>> _storageTips = const {};

  ZestoService({
    required this.getSettings,
    DateTime Function()? now,
    Random? random,
    ZestoTelemetryLogger? telemetryLogger,
    Duration displayDuration = const Duration(seconds: 3),
    AssetBundle? assetBundle,
    bool skipPersistence = false,
  }) : _now = now ?? DateTime.now,
       _random = random ?? Random(),
       _telemetryLogger = telemetryLogger,
       _displayDuration = displayDuration,
       _assetBundle = assetBundle ?? rootBundle,
       _skipPersistence = skipPersistence;

  /// Get state stream for UI
  Stream<ZestoState> get stateStream => _stateController.stream;

  /// Get current state
  ZestoState get currentState => _currentState;

  /// Get persisted unlock progress.
  MascotUnlockProgress get unlockProgress => _unlockProgress;

  /// Dispose resources
  void dispose() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    _stateController.close();
  }

  Future<void> initialize() async {
    await _ensureHydrated();
  }

  /// Main trigger method - checks settings, anti-spam, and shows mascot if conditions met
  Future<void> showMascot(
    MascotMessageType messageType, {
    Map<String, dynamic>? context,
    bool bypassAntiSpam = false,
  }) async {
    await _ensureHydrated();

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
    final now = _now();
    if (!bypassAntiSpam && !_canShowMascot(now)) {
      appLogger.d(
        'Zesto spam prevented (${now.difference(_lastMessageTime ?? now).inMilliseconds}ms since last)',
      );
      return;
    }

    // Select message
    String? message = _selectMessage(messageType, context);
    if (message == null) return;

    // A new mascot supersedes any in-flight auto-dismiss; cancel before
    // updating state so a stale timer can't dismiss the new mascot.
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;

    // Update state
    _updateState(
      isVisible: true,
      currentMessage: message,
      currentMessageType: messageType,
      isAnimating: true,
    );

    // Update timestamp
    _lastMessageTime = now;
    _visibleSince = now;
    await _persistBehaviorState();

    // Log telemetry
    _logTelemetry('mascot_shown', {
      'messageType': messageType.name,
      'message': message,
      'timestamp': now.toIso8601String(),
    });

    // If no UI is listening yet, avoid scheduling delayed dismissal timers.
    if (!_stateController.hasListener) {
      _dismissMascot('auto');
      return;
    }

    // Auto-dismiss after a readable duration. Tips/messages with more text
    // stay longer so users can actually consume the content. Stored as a
    // cancellable Timer so a manual dismiss (or a new showMascot) doesn't
    // race the auto-dismiss into emitting a duplicate telemetry event.
    _autoDismissTimer = Timer(_displayDurationFor(messageType, message), () {
      _autoDismissTimer = null;
      _dismissMascot('auto');
    });
  }

  /// Manual dismiss from UI interactions.
  void dismissMascot() {
    _dismissMascot('manual');
  }

  /// Trigger 1: First item added.
  Future<void> onItemAdded({required int inventoryCountBeforeAdd}) async {
    if (!shouldTriggerFirstItem(inventoryCountBeforeAdd)) {
      return;
    }
    await showMascot(MascotMessageType.firstItem);
  }

  /// Trigger 2/4: Item consumed, with quick-save detection.
  Future<void> onItemConsumed({required DateTime? expiryDate}) async {
    await showMascot(_messageTypeForConsume(expiryDate: expiryDate));
  }

  /// Trigger 3: Item wasted with category-specific storage tip.
  Future<void> onItemWasted({required String itemCategory}) async {
    await showMascot(
      MascotMessageType.wasted,
      context: {'itemCategory': itemCategory},
    );
  }

  /// Trigger 5: Badge unlocked.
  Future<void> onBadgeUnlocked() async {
    await showMascot(MascotMessageType.badgeUnlocked);
  }

  /// Trigger 6: Streak milestone.
  Future<void> onStreakUpdated({required int streakDays}) async {
    if (!isStreakMilestone(streakDays)) {
      return;
    }
    await showMascot(MascotMessageType.streakMilestone);
  }

  /// Trigger 7: Savings milestone crossed.
  Future<void> onSavingsUpdated({
    required double previousSavings,
    required double currentSavings,
  }) async {
    if (!hasCrossedSavingsMilestone(previousSavings, currentSavings)) {
      return;
    }
    await showMascot(MascotMessageType.savingsMilestone);
  }

  /// Trigger 8: Zero waste period.
  Future<void> onZeroWasteCalculated({
    required int consumedCount,
    required int wastedCount,
  }) async {
    if (!isZeroWaste(consumedCount: consumedCount, wastedCount: wastedCount)) {
      return;
    }
    await showMascot(MascotMessageType.zeroWaste);
  }

  /// Trigger 9: Daily welcome (once per day).
  Future<void> onAppOpened() async {
    await _ensureHydrated();
    final now = _now();
    if (!shouldShowDailyWelcome(now)) {
      return;
    }
    _lastDailyWelcomeDate = DateTime(now.year, now.month, now.day);
    await _persistBehaviorState();
    await showMascot(MascotMessageType.dailyWelcome);
  }

  /// Trigger 10: Expiry alert for 3+ items expiring in <24h.
  Future<void> onInventoryScannedForExpiry({
    required int expiringWithin24hCount,
  }) async {
    if (!shouldTriggerExpiryAlert(expiringWithin24hCount)) {
      return;
    }
    await showMascot(MascotMessageType.expiryAlert);
  }

  bool shouldTriggerFirstItem(int inventoryCountBeforeAdd) {
    return inventoryCountBeforeAdd == 0;
  }

  bool isStreakMilestone(int streakDays) {
    return streakMilestones.contains(streakDays);
  }

  bool hasCrossedSavingsMilestone(
    double previousSavings,
    double currentSavings,
  ) {
    for (final milestone in savingsMilestones) {
      if (previousSavings < milestone && currentSavings >= milestone) {
        return true;
      }
    }
    return false;
  }

  bool isZeroWaste({required int consumedCount, required int wastedCount}) {
    final total = consumedCount + wastedCount;
    return total > 0 && wastedCount == 0;
  }

  bool shouldShowDailyWelcome(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return _lastDailyWelcomeDate != today;
  }

  bool shouldTriggerExpiryAlert(int expiringWithin24hCount) {
    return expiringWithin24hCount >= 3;
  }

  /// Record consumption toward mascot unlock progress.
  Future<MascotCharacter?> recordConsumptionForUnlock(String category) async {
    await _ensureHydrated();

    final previousProgress = _unlockProgress;
    final updated = _unlockProgress.addConsumption(category, 1);
    final newCount = updated.categoryConsumption[category] ?? 0;
    final unlocked = updated.checkForUnlock(category, newCount);
    _unlockProgress = unlocked ?? updated;
    await _persistBehaviorState();

    if (unlocked != null) {
      final newlyUnlocked = unlocked.unlockedCharacters
          .where((c) => !previousProgress.unlockedCharacters.contains(c))
          .firstOrNull;
      return newlyUnlocked;
    }

    return null;
  }

  /// Set the active mascot character.
  Future<void> setActiveCharacter(MascotCharacter character) async {
    await _ensureHydrated();
    _unlockProgress = _unlockProgress.setActiveCharacter(character);
    await _persistBehaviorState();
  }

  /// Select message with deduplication
  String? _selectMessage(
    MascotMessageType messageType,
    Map<String, dynamic>? context,
  ) {
    List<String> messages = messagePool[messageType] ?? [];

    // Handle wasted items with storage tips. Tips are loaded from the
    // bundled JSON during hydration; if hydration hasn't completed yet (or
    // the asset failed to load), _storageTips is empty and we fall through
    // to the generic `wasted` message pool below.
    if (messageType == MascotMessageType.wasted &&
        context?['itemCategory'] != null) {
      final category = (context!['itemCategory'] as String).toLowerCase();
      final categoryTips =
          _storageTips[category] ?? _storageTips['general'] ?? const [];
      if (categoryTips.isNotEmpty) {
        return categoryTips[_random.nextInt(categoryTips.length)];
      }
    }

    if (messages.isEmpty) return null;

    // Select random message
    String selected = messages[_random.nextInt(messages.length)];

    // Re-roll once to avoid immediate repeats from recent history.
    if (_messageHistory.contains(selected) && messages.length > 1) {
      final candidates = messages.where((m) => !_messageHistory.contains(m));
      final nonRecent = candidates.toList();
      if (nonRecent.isNotEmpty) {
        selected = nonRecent[_random.nextInt(nonRecent.length)];
      } else {
        selected = messages[_random.nextInt(messages.length)];
      }
    }

    // Update history
    _messageHistory.add(selected);
    if (_messageHistory.length > messageHistorySize) {
      _messageHistory.removeAt(0);
    }

    return selected;
  }

  /// Check if anti-spam allows mascot
  bool _canShowMascot(DateTime now) {
    if (_lastMessageTime == null) return true;
    final gap = now.difference(_lastMessageTime!);
    return gap.compareTo(antiSpamGap) >= 0;
  }

  MascotMessageType _messageTypeForConsume({required DateTime? expiryDate}) {
    if (expiryDate == null) {
      return MascotMessageType.consumed;
    }
    final hoursToExpiry = expiryDate.difference(_now()).inHours;
    if (hoursToExpiry >= 0 && hoursToExpiry < 24) {
      return MascotMessageType.quickSave;
    }
    return MascotMessageType.consumed;
  }

  Duration _displayDurationFor(MascotMessageType type, String message) {
    var duration = _displayDuration;

    // Allow Duration.zero for tests; otherwise enforce minimum display duration
    // so users have time to read the message.
    if (duration > Duration.zero && duration < _minimumDisplayDuration) {
      duration = _minimumDisplayDuration;
    }

    if (type == MascotMessageType.wasted ||
        type == MascotMessageType.expiryAlert) {
      if (duration > Duration.zero && duration < _tipDisplayDuration) {
        duration = _tipDisplayDuration;
      }
    }

    if (message.length > 60 && duration > Duration.zero) {
      duration += const Duration(seconds: 1);
    }

    return duration;
  }

  /// Check if message type should be shown based on settings
  bool _shouldShowMessageType(MascotMessageType type, MascotSettings settings) {
    switch (type) {
      // Celebrations
      case MascotMessageType.consumed:
      case MascotMessageType.quickSave:
      case MascotMessageType.itemAdded:
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
  void _logTelemetry(String eventName, Map<String, Object?> properties) {
    appLogger.i('Zesto telemetry: $eventName → $properties');
    _telemetryLogger?.call(eventName, properties);
  }

  void _dismissMascot(String dismissType) {
    // Idempotent: if no mascot is currently visible, do nothing. Prevents
    // a duplicate mascot_dismissed event when both manual and auto paths
    // race, and protects against repeat dismissMascot() taps from the UI.
    if (_visibleSince == null) {
      return;
    }
    // Cancel any pending auto-dismiss so it doesn't fire after this call
    // (covers the manual-dismiss-before-timeout race).
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;

    final durationMs = _now().difference(_visibleSince!).inMilliseconds;
    _updateState(isVisible: false, isAnimating: false);
    _logTelemetry('mascot_dismissed', {
      'dismissType': dismissType,
      'durationMs': durationMs,
      'timestamp': _now().toIso8601String(),
    });
    _visibleSince = null;
  }

  Future<void> _ensureHydrated() {
    if (_hydrateFuture != null) {
      return _hydrateFuture!;
    }

    // Hydrate persisted behavior state and bundled storage tips in
    // parallel — neither depends on the other and both are read-only.
    _hydrateFuture = Future.wait([
      _loadState(),
      _loadStorageTips(),
    ]).then((_) {});
    return _hydrateFuture!;
  }

  Future<void> _loadStorageTips() async {
    if (_skipPersistence) return;
    try {
      final raw = await _assetBundle.loadString(_storageTipsAssetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      final result = <String, List<String>>{};
      decoded.forEach((key, value) {
        if (value is List) {
          result[key] = value.whereType<String>().toList(growable: false);
        }
      });
      _storageTips = result;
    } catch (e) {
      appLogger.w('Failed to load Zesto storage tips asset', error: e);
      // Leave _storageTips at its default empty value; the service will
      // fall back to generic wasted-item messages.
    }
  }

  Future<void> _loadState() async {
    if (_skipPersistence) return;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final prefs = _prefs!;

      final lastMessageTimeMillis = prefs.getInt(_lastMessageTimeKey);
      _lastMessageTime = lastMessageTimeMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastMessageTimeMillis);

      _messageHistory
        ..clear()
        ..addAll(prefs.getStringList(_messageHistoryKey) ?? const []);

      final lastDailyWelcomeDate = prefs.getString(_lastDailyWelcomeDateKey);
      _lastDailyWelcomeDate = lastDailyWelcomeDate == null
          ? null
          : DateTime.tryParse(lastDailyWelcomeDate);

      final unlockProgressJson = prefs.getString(_unlockProgressKey);
      if (unlockProgressJson != null && unlockProgressJson.isNotEmpty) {
        final decoded = jsonDecode(unlockProgressJson) as Map<String, dynamic>;
        _unlockProgress = MascotUnlockProgress.fromJson(decoded);
      }
    } catch (e) {
      appLogger.w('Failed to load Zesto persisted state', error: e);
    }
  }

  Future<void> _persistBehaviorState() async {
    if (_skipPersistence) return;
    try {
      await _ensureHydrated();
      final prefs = _prefs;
      if (prefs == null) return;

      if (_lastMessageTime == null) {
        await prefs.remove(_lastMessageTimeKey);
      } else {
        await prefs.setInt(
          _lastMessageTimeKey,
          _lastMessageTime!.millisecondsSinceEpoch,
        );
      }

      await prefs.setStringList(_messageHistoryKey, _messageHistory);

      if (_lastDailyWelcomeDate == null) {
        await prefs.remove(_lastDailyWelcomeDateKey);
      } else {
        await prefs.setString(
          _lastDailyWelcomeDateKey,
          _lastDailyWelcomeDate!.toIso8601String(),
        );
      }

      await prefs.setString(
        _unlockProgressKey,
        jsonEncode(_unlockProgress.toJson()),
      );
    } catch (e) {
      appLogger.w('Failed to persist Zesto state', error: e);
    }
  }
}
