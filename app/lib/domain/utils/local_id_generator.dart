library;

class LocalIdGenerator {
  static int _sequence = 0;
  static const int _fnvOffsetBasis = 0x811C9DC5;
  static const int _fnvPrime = 0x01000193;

  static String next({String? prefix}) {
    _sequence = (_sequence + 1) % 1000000;
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    if (prefix == null || prefix.isEmpty) {
      return '$timestamp-$_sequence';
    }
    return '$prefix-$timestamp-$_sequence';
  }

  static int notificationIdFor(String id) {
    final numericId = int.tryParse(id);
    if (numericId != null) {
      return numericId;
    }

    var hash = _fnvOffsetBasis;
    for (final codeUnit in id.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * _fnvPrime) & 0x7fffffff;
    }

    return hash == 0 ? 1 : hash;
  }
}
