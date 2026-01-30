// ...existing code...

enum ExpiryBucket { today, thisWeek, expired, later }

extension ExpiryBucketExtension on ExpiryBucket {
  String get displayName {
    switch (this) {
      case ExpiryBucket.today:
        return 'Today';
      case ExpiryBucket.thisWeek:
        return 'This Week';
      case ExpiryBucket.expired:
        return 'Expired';
      case ExpiryBucket.later:
        return 'Later';
    }
  }

  String get emoji {
    switch (this) {
      case ExpiryBucket.today:
        return '🟢';
      case ExpiryBucket.thisWeek:
        return '🟡';
      case ExpiryBucket.expired:
        return '🔴';
      case ExpiryBucket.later:
        return '🔵';
    }
  }
}
