library;

/// Badge domain models for achievement system
/// Based on planning/milestones/M3/300-accountability-achievement-badges
import 'package:equatable/equatable.dart';

/// Badge type enumeration
enum BadgeType {
  noWasteWeek('no-waste-week', '🏆', 'No Waste Week'),
  usedBeforeExpiry('used-before-expiry', '✓', 'Used Before Expiry'),
  cookedFromPantry('cooked-from-pantry', '🍳', 'Cooked from Pantry'),
  savingsMilestone('savings-milestone', '💰', 'Savings Milestone'),
  environmentalImpact('environmental-impact', '🌍', 'Environmental Impact');

  final String id;
  final String emoji;
  final String displayName;

  const BadgeType(this.id, this.emoji, this.displayName);

  static BadgeType fromId(String id) {
    return BadgeType.values.firstWhere(
      (type) => type.id == id,
      orElse: () => BadgeType.noWasteWeek,
    );
  }
}

/// Badge model representing an achievement
class Badge extends Equatable {
  final String id;
  final BadgeType type;
  final String emoji;
  final String name;
  final String description;
  final DateTime? earnedAt;
  final int shareCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Badge({
    required this.id,
    required this.type,
    required this.emoji,
    required this.name,
    required this.description,
    this.earnedAt,
    this.shareCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Whether this badge has been earned
  bool get isEarned => earnedAt != null;

  /// Get the earned date formatted for display
  String? get earnedDateDisplay {
    if (earnedAt == null) return null;
    return '${earnedAt!.month}/${earnedAt!.day}/${earnedAt!.year}';
  }

  /// Get shareable text for this badge
  String getShareText() {
    return switch (type) {
      BadgeType.noWasteWeek =>
        '$emoji I achieved No Waste Week! 7 days without wasting food.',
      BadgeType.usedBeforeExpiry =>
        '$emoji I used 5+ items before they expired!',
      BadgeType.cookedFromPantry =>
        '$emoji I cooked 3 meals from pantry staples!',
      BadgeType.savingsMilestone =>
        '$emoji I\'ve saved money by reducing waste!',
      BadgeType.environmentalImpact =>
        '$emoji I\'ve avoided CO₂ emissions by reducing waste!',
    };
  }

  /// Create a copy with optional field overrides
  Badge copyWith({
    String? id,
    BadgeType? type,
    String? emoji,
    String? name,
    String? description,
    DateTime? earnedAt,
    int? shareCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Badge(
      id: id ?? this.id,
      type: type ?? this.type,
      emoji: emoji ?? this.emoji,
      name: name ?? this.name,
      description: description ?? this.description,
      earnedAt: earnedAt ?? this.earnedAt,
      shareCount: shareCount ?? this.shareCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    emoji,
    name,
    description,
    earnedAt,
    shareCount,
    createdAt,
    updatedAt,
  ];
}

/// Badge progress tracking
class BadgeProgress extends Equatable {
  final BadgeType badgeType;
  final int currentProgress;
  final int requiredProgress;
  final double progressPercentage;
  final bool isEarned;

  const BadgeProgress({
    required this.badgeType,
    required this.currentProgress,
    required this.requiredProgress,
    this.progressPercentage = 0.0,
    this.isEarned = false,
  });

  /// Calculate progress percentage
  double calculateProgressPercentage() {
    if (requiredProgress == 0) return 0.0;
    return (currentProgress / requiredProgress).clamp(0.0, 1.0);
  }

  /// Copy with optional field overrides
  BadgeProgress copyWith({
    BadgeType? badgeType,
    int? currentProgress,
    int? requiredProgress,
    double? progressPercentage,
    bool? isEarned,
  }) {
    return BadgeProgress(
      badgeType: badgeType ?? this.badgeType,
      currentProgress: currentProgress ?? this.currentProgress,
      requiredProgress: requiredProgress ?? this.requiredProgress,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      isEarned: isEarned ?? this.isEarned,
    );
  }

  @override
  List<Object?> get props => [
    badgeType,
    currentProgress,
    requiredProgress,
    progressPercentage,
    isEarned,
  ];
}

/// Streak tracking for badges like "No Waste Week"
class StreakData extends Equatable {
  final BadgeType badgeType;
  final int streakDays;
  final DateTime streakStartDate;
  final DateTime lastActivityDate;
  final bool isActive;

  const StreakData({
    required this.badgeType,
    required this.streakDays,
    required this.streakStartDate,
    required this.lastActivityDate,
    this.isActive = true,
  });

  /// Days remaining until badge earned (for no-waste-week)
  int get daysRemaining {
    return (7 - streakDays).clamp(0, 7);
  }

  /// Copy with optional field overrides
  StreakData copyWith({
    BadgeType? badgeType,
    int? streakDays,
    DateTime? streakStartDate,
    DateTime? lastActivityDate,
    bool? isActive,
  }) {
    return StreakData(
      badgeType: badgeType ?? this.badgeType,
      streakDays: streakDays ?? this.streakDays,
      streakStartDate: streakStartDate ?? this.streakStartDate,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
    badgeType,
    streakDays,
    streakStartDate,
    lastActivityDate,
    isActive,
  ];
}
