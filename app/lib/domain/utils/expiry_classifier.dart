import '../models/item_model.dart';
import '../models/expiry_bucket.dart';

/// Utility for classifying items into expiry buckets
class ExpiryClassifier {
  /// Classifies an item into an expiry bucket based on expiryDate and [now].
  ///
  /// - TODAY: expires today (date only)
  /// - THIS_WEEK: expires in 1-7 days
  /// - EXPIRED: already expired
  /// - LATER: expires in 8+ days or no expiry
  static ExpiryBucket classify(Item item, {DateTime? now}) {
    final expiry = item.expiryDate;
    if (expiry == null) return ExpiryBucket.later;
    final today = (now ?? DateTime.now()).toLocal();
    final expiryDate = DateTime(expiry.year, expiry.month, expiry.day);
    final todayDate = DateTime(today.year, today.month, today.day);
    final diff = expiryDate.difference(todayDate).inDays;
    if (diff < 0) return ExpiryBucket.expired;
    if (diff == 0) return ExpiryBucket.today;
    if (diff >= 1 && diff <= 7) return ExpiryBucket.thisWeek;
    return ExpiryBucket.later;
  }
}
