library;

class ExpiryDateParseResult {
  final DateTime date;
  final String format;

  const ExpiryDateParseResult({required this.date, required this.format});
}

class ExpiryDateParser {
  const ExpiryDateParser();

  ExpiryDateParseResult? parse(String text, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final candidates = <ExpiryDateParseResult>[];
    final lower = text.toLowerCase();

    final isoPattern = RegExp(r'(\d{4})[/-](\d{1,2})[/-](\d{1,2})');
    for (final match in isoPattern.allMatches(lower)) {
      final year = int.tryParse(match.group(1) ?? '');
      final month = int.tryParse(match.group(2) ?? '');
      final day = int.tryParse(match.group(3) ?? '');
      _tryAddCandidate(candidates, year, month, day, 'YYYY-MM-DD');
    }

    final slashPattern = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})');
    for (final match in slashPattern.allMatches(lower)) {
      final first = int.tryParse(match.group(1) ?? '');
      final second = int.tryParse(match.group(2) ?? '');
      final yearRaw = int.tryParse(match.group(3) ?? '');
      if (first == null || second == null || yearRaw == null) continue;
      final year = _normalizeYear(yearRaw);

      // Try MM/DD
      _tryAddCandidate(candidates, year, first, second, 'MM/DD/YYYY');
      // Try DD/MM
      _tryAddCandidate(candidates, year, second, first, 'DD/MM/YYYY');
    }

    final monthNamePattern = RegExp(
      r'(jan|january|feb|february|mar|march|apr|april|may|jun|june|jul|july|aug|august|sep|sept|september|oct|october|nov|november|dec|december)\s*(\d{1,2})(?:st|nd|rd|th)?[,]?\s*(\d{2,4})',
    );
    for (final match in monthNamePattern.allMatches(lower)) {
      final month = _monthFromName(match.group(1) ?? '');
      final day = int.tryParse(match.group(2) ?? '');
      final yearRaw = int.tryParse(match.group(3) ?? '');
      if (month == null || day == null || yearRaw == null) continue;
      final year = _normalizeYear(yearRaw);
      _tryAddCandidate(candidates, year, month, day, 'MMM DD YYYY');
    }

    final dayMonthPattern = RegExp(
      r'(\d{1,2})\s*(jan|january|feb|february|mar|march|apr|april|may|jun|june|jul|july|aug|august|sep|sept|september|oct|october|nov|november|dec|december)\s*(\d{2,4})',
    );
    for (final match in dayMonthPattern.allMatches(lower)) {
      final day = int.tryParse(match.group(1) ?? '');
      final month = _monthFromName(match.group(2) ?? '');
      final yearRaw = int.tryParse(match.group(3) ?? '');
      if (month == null || day == null || yearRaw == null) continue;
      final year = _normalizeYear(yearRaw);
      _tryAddCandidate(candidates, year, month, day, 'DD MMM YYYY');
    }

    final valid = _filterValid(reference, candidates);
    if (valid.isEmpty) return null;

    valid.sort((a, b) => a.date.compareTo(b.date));
    return valid.first;
  }

  void _tryAddCandidate(
    List<ExpiryDateParseResult> candidates,
    int? year,
    int? month,
    int? day,
    String format,
  ) {
    if (year == null || month == null || day == null) return;
    if (month < 1 || month > 12 || day < 1 || day > 31) return;
    try {
      final date = DateTime(year, month, day);
      candidates.add(ExpiryDateParseResult(date: date, format: format));
    } catch (_) {}
  }

  List<ExpiryDateParseResult> _filterValid(
    DateTime now,
    List<ExpiryDateParseResult> candidates,
  ) {
    final maxDate = DateTime(now.year + 2, now.month, now.day);
    return candidates.where((candidate) {
      final date = candidate.date;
      final isTooOld = date.isBefore(now.subtract(const Duration(days: 1)));
      final isTooFar = date.isAfter(maxDate);
      return !(isTooOld || isTooFar);
    }).toList();
  }

  int _normalizeYear(int yearRaw) {
    if (yearRaw < 100) {
      return 2000 + yearRaw;
    }
    return yearRaw;
  }

  int? _monthFromName(String name) {
    switch (name.substring(0, 3)) {
      case 'jan':
        return 1;
      case 'feb':
        return 2;
      case 'mar':
        return 3;
      case 'apr':
        return 4;
      case 'may':
        return 5;
      case 'jun':
        return 6;
      case 'jul':
        return 7;
      case 'aug':
        return 8;
      case 'sep':
        return 9;
      case 'oct':
        return 10;
      case 'nov':
        return 11;
      case 'dec':
        return 12;
    }
    return null;
  }
}
