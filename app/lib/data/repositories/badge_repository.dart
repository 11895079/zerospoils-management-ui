library;

/// Badge repository for local persistence
/// Stores earned badges and badge progress
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/models/badge_model.dart';

/// Repository for badge storage and retrieval
class BadgeRepository {
  static const String _earnedBadgesKey = 'earned_badges';
  static const String _badgeProgressKey = 'badge_progress';
  static const String _streakDataKey = 'streak_data';

  final SharedPreferences _prefs;

  BadgeRepository(this._prefs);

  /// Get all earned badges
  Future<List<Badge>> getEarnedBadges() async {
    final json = _prefs.getString(_earnedBadgesKey);
    if (json == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.map((item) => _badgeFromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get a specific earned badge by type
  Future<Badge?> getEarnedBadge(BadgeType type) async {
    final badges = await getEarnedBadges();
    try {
      return badges.firstWhere((b) => b.type == type);
    } catch (e) {
      return null;
    }
  }

  /// Save an earned badge
  Future<void> saveEarnedBadge(Badge badge) async {
    final badges = await getEarnedBadges();
    // Remove if already exists (update)
    badges.removeWhere((b) => b.id == badge.id);
    badges.add(badge);

    await _prefs.setString(
      _earnedBadgesKey,
      jsonEncode(badges.map((b) => _badgeToJson(b)).toList()),
    );
  }

  /// Save multiple earned badges
  Future<void> saveEarnedBadges(List<Badge> badges) async {
    for (final badge in badges) {
      await saveEarnedBadge(badge);
    }
  }

  /// Check if badge has been earned
  Future<bool> isBadgeEarned(BadgeType type) async {
    final badge = await getEarnedBadge(type);
    return badge != null && badge.isEarned;
  }

  /// Get badge progress for a specific type
  Future<BadgeProgress?> getBadgeProgress(BadgeType type) async {
    final json = _prefs.getString('${_badgeProgressKey}_${type.id}');
    if (json == null) return null;

    try {
      return _badgeProgressFromJson(jsonDecode(json));
    } catch (e) {
      return null;
    }
  }

  /// Save badge progress
  Future<void> saveBadgeProgress(BadgeProgress progress) async {
    await _prefs.setString(
      '${_badgeProgressKey}_${progress.badgeType.id}',
      jsonEncode(_badgeProgressToJson(progress)),
    );
  }

  /// Get streak data for a badge
  Future<StreakData?> getStreakData(BadgeType type) async {
    final json = _prefs.getString('${_streakDataKey}_${type.id}');
    if (json == null) return null;

    try {
      return _streakDataFromJson(jsonDecode(json));
    } catch (e) {
      return null;
    }
  }

  /// Save streak data
  Future<void> saveStreakData(StreakData streak) async {
    await _prefs.setString(
      '${_streakDataKey}_${streak.badgeType.id}',
      jsonEncode(_streakDataToJson(streak)),
    );
  }

  /// Increment share count for a badge
  Future<void> incrementShareCount(BadgeType type) async {
    final badge = await getEarnedBadge(type);
    if (badge != null) {
      final updated = badge.copyWith(
        shareCount: badge.shareCount + 1,
        updatedAt: DateTime.now(),
      );
      await saveEarnedBadge(updated);
    }
  }

  /// Clear all badge data
  Future<void> clearAll() async {
    await _prefs.remove(_earnedBadgesKey);
    await _prefs.remove(_badgeProgressKey);
    await _prefs.remove(_streakDataKey);

    // Remove all individual badge progress/streak keys
    for (final type in BadgeType.values) {
      await _prefs.remove('${_badgeProgressKey}_${type.id}');
      await _prefs.remove('${_streakDataKey}_${type.id}');
    }
  }

  // JSON serialization helpers

  Map<String, dynamic> _badgeToJson(Badge badge) {
    return {
      'id': badge.id,
      'type': badge.type.id,
      'emoji': badge.emoji,
      'name': badge.name,
      'description': badge.description,
      'earnedAt': badge.earnedAt?.toIso8601String(),
      'shareCount': badge.shareCount,
      'createdAt': badge.createdAt.toIso8601String(),
      'updatedAt': badge.updatedAt.toIso8601String(),
    };
  }

  Badge _badgeFromJson(dynamic json) {
    return Badge(
      id: json['id'],
      type: BadgeType.fromId(json['type']),
      emoji: json['emoji'],
      name: json['name'],
      description: json['description'],
      earnedAt: json['earnedAt'] != null
          ? DateTime.parse(json['earnedAt'])
          : null,
      shareCount: json['shareCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> _badgeProgressToJson(BadgeProgress progress) {
    return {
      'badgeType': progress.badgeType.id,
      'currentProgress': progress.currentProgress,
      'requiredProgress': progress.requiredProgress,
      'progressPercentage': progress.progressPercentage,
      'isEarned': progress.isEarned,
    };
  }

  BadgeProgress _badgeProgressFromJson(dynamic json) {
    return BadgeProgress(
      badgeType: BadgeType.fromId(json['badgeType']),
      currentProgress: json['currentProgress'],
      requiredProgress: json['requiredProgress'],
      progressPercentage: (json['progressPercentage'] as num).toDouble(),
      isEarned: json['isEarned'],
    );
  }

  Map<String, dynamic> _streakDataToJson(StreakData streak) {
    return {
      'badgeType': streak.badgeType.id,
      'streakDays': streak.streakDays,
      'streakStartDate': streak.streakStartDate.toIso8601String(),
      'lastActivityDate': streak.lastActivityDate.toIso8601String(),
      'isActive': streak.isActive,
    };
  }

  StreakData _streakDataFromJson(dynamic json) {
    return StreakData(
      badgeType: BadgeType.fromId(json['badgeType']),
      streakDays: json['streakDays'],
      streakStartDate: DateTime.parse(json['streakStartDate']),
      lastActivityDate: DateTime.parse(json['lastActivityDate']),
      isActive: json['isActive'],
    );
  }
}
