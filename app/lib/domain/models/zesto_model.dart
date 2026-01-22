library;

/// Zesto Mascot Configuration Model
/// Defines settings and unlock state for Zesto the Avocado mascot

import 'package:equatable/equatable.dart';

enum MascotFrequency {
  always, // Show all 10 triggers
  milestones, // Show only major milestones (default)
  never, // Completely disabled
}

enum MascotCharacter {
  avocado, // 🥑 Zesto (default)
  carrot, // 🥕 Carrie
  broccoli, // 🥦 Broc
  bread, // 🍞 Betty
}

/// Mascot Settings (user preferences)
class MascotSettings extends Equatable {
  final bool enabled;
  final MascotFrequency frequency;
  final bool showCelebrations;
  final bool showTips;
  final bool showDailyWelcome;

  const MascotSettings({
    this.enabled = true,
    this.frequency = MascotFrequency.milestones,
    this.showCelebrations = true,
    this.showTips = true,
    this.showDailyWelcome = true,
  });

  /// Create a copy with modified fields
  MascotSettings copyWith({
    bool? enabled,
    MascotFrequency? frequency,
    bool? showCelebrations,
    bool? showTips,
    bool? showDailyWelcome,
  }) {
    return MascotSettings(
      enabled: enabled ?? this.enabled,
      frequency: frequency ?? this.frequency,
      showCelebrations: showCelebrations ?? this.showCelebrations,
      showTips: showTips ?? this.showTips,
      showDailyWelcome: showDailyWelcome ?? this.showDailyWelcome,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'frequency': frequency.name,
      'showCelebrations': showCelebrations,
      'showTips': showTips,
      'showDailyWelcome': showDailyWelcome,
    };
  }

  /// Create from JSON
  factory MascotSettings.fromJson(Map<String, dynamic> json) {
    return MascotSettings(
      enabled: json['enabled'] as bool? ?? true,
      frequency: MascotFrequency.values.byName(
        json['frequency'] as String? ?? 'milestones',
      ),
      showCelebrations: json['showCelebrations'] as bool? ?? true,
      showTips: json['showTips'] as bool? ?? true,
      showDailyWelcome: json['showDailyWelcome'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
    enabled,
    frequency,
    showCelebrations,
    showTips,
    showDailyWelcome,
  ];
}

/// Mascot Unlock Progress (achievements)
class MascotUnlockProgress extends Equatable {
  final Map<String, int>
  categoryConsumption; // e.g., {"produce": 23, "grain": 0}
  final List<MascotCharacter> unlockedCharacters;
  final MascotCharacter activeCharacter;

  const MascotUnlockProgress({
    Map<String, int>? categoryConsumption,
    List<MascotCharacter>? unlockedCharacters,
    this.activeCharacter = MascotCharacter.avocado,
  }) : categoryConsumption = categoryConsumption ?? const {},
       unlockedCharacters =
           unlockedCharacters ?? const [MascotCharacter.avocado];

  /// Get progress for specific character
  int getProgressForCharacter(MascotCharacter character) {
    final categoryKey = _characterToCategory(character);
    return categoryConsumption[categoryKey] ?? 0;
  }

  /// Get completion percentage (0-100)
  int getCompletionPercentage(MascotCharacter character) {
    const threshold = 50;
    final progress = getProgressForCharacter(character);
    return ((progress / threshold) * 100).toInt().clamp(0, 100);
  }

  /// Check if character is unlocked
  bool isUnlocked(MascotCharacter character) {
    return unlockedCharacters.contains(character);
  }

  /// Try to unlock character if threshold reached
  MascotUnlockProgress? checkForUnlock(String category, int newCount) {
    final character = _categoryToCharacter(category);
    if (character == null) return null;
    if (isUnlocked(character)) return null;

    const threshold = 50;
    if (newCount < threshold) return null;

    // Unlock!
    return MascotUnlockProgress(
      categoryConsumption: categoryConsumption,
      unlockedCharacters: [...unlockedCharacters, character],
      activeCharacter: activeCharacter,
    );
  }

  /// Increment consumption for category
  MascotUnlockProgress addConsumption(String category, int amount) {
    final updated = Map<String, int>.from(categoryConsumption);
    updated[category] = (updated[category] ?? 0) + amount;
    return MascotUnlockProgress(
      categoryConsumption: updated,
      unlockedCharacters: unlockedCharacters,
      activeCharacter: activeCharacter,
    );
  }

  /// Change active mascot
  MascotUnlockProgress setActiveCharacter(MascotCharacter character) {
    if (!isUnlocked(character)) {
      throw ArgumentError('Character $character is not unlocked');
    }
    return MascotUnlockProgress(
      categoryConsumption: categoryConsumption,
      unlockedCharacters: unlockedCharacters,
      activeCharacter: character,
    );
  }

  /// Get emoji for character
  static String getCharacterEmoji(MascotCharacter character) {
    switch (character) {
      case MascotCharacter.avocado:
        return '🥑';
      case MascotCharacter.carrot:
        return '🥕';
      case MascotCharacter.broccoli:
        return '🥦';
      case MascotCharacter.bread:
        return '🍞';
    }
  }

  /// Get name for character
  static String getCharacterName(MascotCharacter character) {
    switch (character) {
      case MascotCharacter.avocado:
        return 'Zesto the Avocado';
      case MascotCharacter.carrot:
        return 'Carrie the Carrot';
      case MascotCharacter.broccoli:
        return 'Broc the Broccoli';
      case MascotCharacter.bread:
        return 'Betty the Bread';
    }
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'categoryConsumption': categoryConsumption,
      'unlockedCharacters': unlockedCharacters.map((c) => c.name).toList(),
      'activeCharacter': activeCharacter.name,
    };
  }

  /// Create from JSON
  factory MascotUnlockProgress.fromJson(Map<String, dynamic> json) {
    return MascotUnlockProgress(
      categoryConsumption: Map<String, int>.from(
        json['categoryConsumption'] as Map? ?? {},
      ),
      unlockedCharacters: (json['unlockedCharacters'] as List?)
          ?.map((c) => MascotCharacter.values.byName(c as String))
          .toList(),
      activeCharacter: MascotCharacter.values.byName(
        json['activeCharacter'] as String? ?? 'avocado',
      ),
    );
  }

  @override
  List<Object?> get props => [
    categoryConsumption,
    unlockedCharacters,
    activeCharacter,
  ];

  /// Private helper: Category → Character mapping
  static MascotCharacter? _categoryToCharacter(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('carrot') || lower == 'orange') {
      return MascotCharacter.carrot;
    }
    if (lower.contains('broccoli') ||
        lower == 'vegetable' ||
        lower == 'produce') {
      return MascotCharacter.broccoli;
    }
    if (lower.contains('bread') || lower.contains('grain')) {
      return MascotCharacter.bread;
    }
    return null;
  }

  /// Private helper: Character → Category mapping
  static String _characterToCategory(MascotCharacter character) {
    switch (character) {
      case MascotCharacter.avocado:
        return 'produce';
      case MascotCharacter.carrot:
        return 'carrot';
      case MascotCharacter.broccoli:
        return 'vegetable';
      case MascotCharacter.bread:
        return 'grain';
    }
  }
}

/// Mascot Message Type (for telemetry & filtering)
enum MascotMessageType {
  // Celebrations
  consumed,
  quickSave,
  badgeUnlocked,
  streakMilestone,
  savingsMilestone,
  zeroWaste,

  // Tips & Reminders
  wasted,
  expiryAlert,

  // Welcome
  dailyWelcome,

  // Special
  firstItem,
  celebration,
}

/// Zesto State (what's currently visible)
class ZestoState extends Equatable {
  final bool isVisible;
  final String? currentMessage;
  final MascotMessageType? currentMessageType;
  final bool isAnimating;

  const ZestoState({
    this.isVisible = false,
    this.currentMessage,
    this.currentMessageType,
    this.isAnimating = false,
  });

  ZestoState copyWith({
    bool? isVisible,
    String? currentMessage,
    MascotMessageType? currentMessageType,
    bool? isAnimating,
  }) {
    return ZestoState(
      isVisible: isVisible ?? this.isVisible,
      currentMessage: currentMessage ?? this.currentMessage,
      currentMessageType: currentMessageType ?? this.currentMessageType,
      isAnimating: isAnimating ?? this.isAnimating,
    );
  }

  @override
  List<Object?> get props => [
    isVisible,
    currentMessage,
    currentMessageType,
    isAnimating,
  ];
}
