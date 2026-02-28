/// Represents attribution context for a reminder-driven action.
class ReminderAttribution {
  final String itemId;
  final int leadTimeDays;
  final DateTime openedAt;

  ReminderAttribution({
    required this.itemId,
    required this.leadTimeDays,
    required this.openedAt,
  });
}

/// Singleton store for tracking reminder attribution context.
/// Used to determine if a user action originated from a reminder notification.
class ReminderAttributionStore {
  static final ReminderAttributionStore _instance =
      ReminderAttributionStore._internal();

  factory ReminderAttributionStore() => _instance;

  ReminderAttributionStore._internal();

  ReminderAttribution? _context;

  /// Set the current reminder attribution context.
  void setContext(ReminderAttribution attribution) {
    _context = attribution;
  }

  /// Get the current reminder attribution context.
  ReminderAttribution? getContext() {
    return _context;
  }

  /// Clear the reminder attribution context.
  void clearContext() {
    _context = null;
  }

  /// Alias for clearContext() for convenience.
  void clear() => clearContext();
}
