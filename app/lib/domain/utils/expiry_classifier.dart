library;

/// Expiry bucket enum for classifying items by urgency
enum ExpiryBucket {
  today('Today', '⚠️'),
  thisWeek('This Week', '⏰'),
  expired('Expired', '🔴'),
  later('Later', '✨');

  final String displayName;
  final String emoji;

  const ExpiryBucket(this.displayName, this.emoji);
}

/// Utility class for classifying items into expiry buckets
/// Uses date-only comparisons to avoid timezone issues
class ExpiryClassifier {
  ExpiryClassifier._(); // Private constructor to prevent instantiation

  /// Classifies an item into an expiry bucket based on its expiry date
  /// Returns [ExpiryBucket.later] if the item has no expiry date
  static ExpiryBucket classify(
    dynamic item, // Accept any object with expiryDate property
  ) {
    // Access expiryDate via dynamic to avoid circular dependencies
    final expiryDate = (item as dynamic).expiryDate as DateTime?;

    if (expiryDate == null) {
      return ExpiryBucket.later;
    }

    // Get today's date at midnight (date-only, no time component)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDateOnly = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    );

    // Calculate days difference
    final daysDifference = expiryDateOnly.difference(today).inDays;

    if (daysDifference < 0) {
      // Past date = expired
      return ExpiryBucket.expired;
    } else if (daysDifference == 0) {
      // Same day = today
      return ExpiryBucket.today;
    } else if (daysDifference <= 7) {
      // 1-7 days = this week
      return ExpiryBucket.thisWeek;
    } else {
      // 8+ days = later
      return ExpiryBucket.later;
    }
  }
}
