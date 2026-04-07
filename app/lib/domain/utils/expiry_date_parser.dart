library;

class ExpiryDateParseResult {
  final DateTime date;
  final String format;

  const ExpiryDateParseResult({required this.date, required this.format});
}

class ExpiryDateParser {
  const ExpiryDateParser();

  ExpiryDateParseResult? parse(
    String text, {
    DateTime? now,
    String preferredDateFormat = 'MM/DD/YYYY',
  }) {
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

      final mmDd = _buildCandidate(year, first, second, 'MM/DD/YYYY');
      final ddMm = _buildCandidate(year, second, first, 'DD/MM/YYYY');
      final isAmbiguous = first <= 12 && second <= 12;

      if (isAmbiguous) {
        if (preferredDateFormat == 'DD/MM/YYYY') {
          if (ddMm != null) {
            candidates.add(ddMm);
          } else if (mmDd != null) {
            candidates.add(mmDd);
          }
        } else {
          if (mmDd != null) {
            candidates.add(mmDd);
          } else if (ddMm != null) {
            candidates.add(ddMm);
          }
        }
        continue;
      }

      if (mmDd != null) {
        candidates.add(mmDd);
      }
      if (ddMm != null) {
        candidates.add(ddMm);
      }
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
    final candidate = _buildCandidate(year, month, day, format);
    if (candidate != null) {
      candidates.add(candidate);
    }
  }

  ExpiryDateParseResult? _buildCandidate(
    int? year,
    int? month,
    int? day,
    String format,
  ) {
    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    try {
      final date = DateTime(year, month, day);
      return ExpiryDateParseResult(date: date, format: format);
    } catch (_) {}
    return null;
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
    if (name.length < 3) return null;
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
