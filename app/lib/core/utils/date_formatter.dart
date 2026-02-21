library;

/// Utility for formatting dates according to user preference
/// Supports: MM/DD/YYYY, DD/MM/YYYY, YYYY-MM-DD

import 'package:intl/intl.dart';

class AppDateFormatter {
  /// Converts a preference format string to an intl DateFormat pattern
  static String _getPattern(String formatPreference) {
    switch (formatPreference) {
      case 'DD/MM/YYYY':
        return 'dd/MM/yyyy';
      case 'YYYY-MM-DD':
        return 'yyyy-MM-dd';
      case 'MM/DD/YYYY':
      default:
        return 'MM/dd/yyyy';
    }
  }

  /// Formats a date using the user's preferred format
  /// Example: formatDate(DateTime.now(), 'DD/MM/YYYY') => "20/02/2026"
  static String formatDate(DateTime date, String formatPreference) {
    final pattern = _getPattern(formatPreference);
    return DateFormat(pattern).format(date);
  }

  /// Formats a date with month and day (short form)
  /// Used for badge dates, recent activity, etc.
  /// Example: formatMonthDay(DateTime.now(), 'MM/DD/YYYY') => "Feb 20"
  static String formatMonthDay(DateTime date, String formatPreference) {
    return DateFormat('MMM d').format(date);
  }

  /// Formats a date with full year (for item details, timestamps)
  /// Example: formatDateWithYear(DateTime.now(), 'DD/MM/YYYY') => "20 Feb 2026"
  static String formatDateWithYear(DateTime date, String formatPreference) {
    return DateFormat('d MMM yyyy').format(date);
  }

  /// Formats a time (hour:minute)
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Formats relative time (e.g., "2 days ago")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'just now';
    }
  }
}
