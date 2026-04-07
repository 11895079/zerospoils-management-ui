library;

class LocalIdGenerator {
  static int _sequence = 0;

  static String next({String? prefix}) {
    _sequence = (_sequence + 1) % 1000000;
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    if (prefix == null || prefix.isEmpty) {
      return '$timestamp-$_sequence';
    }
    return '$prefix-$timestamp-$_sequence';
  }
}
