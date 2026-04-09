library;

class _ScoredExpiryCandidate {
  const _ScoredExpiryCandidate({required this.result, required this.score});

  final ExpiryDateParseResult result;
  final int score;
}

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
    final candidates = <_ScoredExpiryCandidate>[];
    final lower = text.toLowerCase();

    final isoPattern = RegExp(r'(\d{4})[./-](\d{1,2})[./-](\d{1,2})');
    for (final match in isoPattern.allMatches(lower)) {
      final year = int.tryParse(match.group(1) ?? '');
      final month = int.tryParse(match.group(2) ?? '');
      final day = int.tryParse(match.group(3) ?? '');
      _tryAddCandidate(
        candidates,
        year,
        month,
        day,
        'YYYY-MM-DD',
        _scoreContext(lower, match.start, match.end),
      );
    }

    final slashPattern = RegExp(r'(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})');
    for (final match in slashPattern.allMatches(lower)) {
      final first = int.tryParse(match.group(1) ?? '');
      final second = int.tryParse(match.group(2) ?? '');
      final yearRaw = int.tryParse(match.group(3) ?? '');
      if (first == null || second == null || yearRaw == null) continue;
      final year = _normalizeYear(yearRaw);

      final mmDd = _buildCandidate(year, first, second, 'MM/DD/YYYY');
      final ddMm = _buildCandidate(year, second, first, 'DD/MM/YYYY');
      final isAmbiguous = first <= 12 && second <= 12;
      final score = _scoreContext(lower, match.start, match.end);

      if (isAmbiguous) {
        if (preferredDateFormat == 'DD/MM/YYYY') {
          if (ddMm != null) {
            candidates.add(_ScoredExpiryCandidate(result: ddMm, score: score));
          } else if (mmDd != null) {
            candidates.add(_ScoredExpiryCandidate(result: mmDd, score: score));
          }
        } else {
          if (mmDd != null) {
            candidates.add(_ScoredExpiryCandidate(result: mmDd, score: score));
          } else if (ddMm != null) {
            candidates.add(_ScoredExpiryCandidate(result: ddMm, score: score));
          }
        }
        continue;
      }

      if (mmDd != null) {
        candidates.add(_ScoredExpiryCandidate(result: mmDd, score: score));
      }
      if (ddMm != null) {
        candidates.add(_ScoredExpiryCandidate(result: ddMm, score: score));
      }
    }

    final spacedNumericPattern = RegExp(r'(\d{1,2})\s+(\d{1,2})\s+(\d{2,4})');
    for (final match in spacedNumericPattern.allMatches(lower)) {
      final first = int.tryParse(match.group(1) ?? '');
      final second = int.tryParse(match.group(2) ?? '');
      final yearRaw = int.tryParse(match.group(3) ?? '');
      if (first == null || second == null || yearRaw == null) continue;
      final year = _normalizeYear(yearRaw);

      final mmDd = _buildCandidate(year, first, second, 'MM DD YYYY');
      final ddMm = _buildCandidate(year, second, first, 'DD MM YYYY');
      final isAmbiguous = first <= 12 && second <= 12;
      final score = _scoreContext(lower, match.start, match.end);

      if (isAmbiguous) {
        if (preferredDateFormat == 'DD/MM/YYYY') {
          if (ddMm != null) {
            candidates.add(_ScoredExpiryCandidate(result: ddMm, score: score));
          } else if (mmDd != null) {
            candidates.add(_ScoredExpiryCandidate(result: mmDd, score: score));
          }
        } else {
          if (mmDd != null) {
            candidates.add(_ScoredExpiryCandidate(result: mmDd, score: score));
          } else if (ddMm != null) {
            candidates.add(_ScoredExpiryCandidate(result: ddMm, score: score));
          }
        }
        continue;
      }

      if (mmDd != null) {
        candidates.add(_ScoredExpiryCandidate(result: mmDd, score: score));
      }
      if (ddMm != null) {
        candidates.add(_ScoredExpiryCandidate(result: ddMm, score: score));
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
      _tryAddCandidate(
        candidates,
        year,
        month,
        day,
        'MMM DD YYYY',
        _scoreContext(lower, match.start, match.end),
      );
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
      _tryAddCandidate(
        candidates,
        year,
        month,
        day,
        'DD MMM YYYY',
        _scoreContext(lower, match.start, match.end),
      );
    }

    final bilingualMonthCodePattern = RegExp(
      r'(\d{4})\s*([a-z]{2})\s*(\d{1,2})',
    );
    for (final match in bilingualMonthCodePattern.allMatches(lower)) {
      final year = int.tryParse(match.group(1) ?? '');
      final month = _monthFromBilingualCode(match.group(2) ?? '');
      final day = int.tryParse(match.group(3) ?? '');
      if (year == null || month == null || day == null) continue;
      _tryAddCandidate(
        candidates,
        year,
        month,
        day,
        'YYYY MON DD',
        _scoreContext(lower, match.start, match.end),
      );
    }

    final valid = _filterValid(reference, candidates);
    if (valid.isEmpty) return null;

    valid.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return a.result.date.compareTo(b.result.date);
    });
    return valid.first.result;
  }

  void _tryAddCandidate(
    List<_ScoredExpiryCandidate> candidates,
    int? year,
    int? month,
    int? day,
    String format,
    int score,
  ) {
    final candidate = _buildCandidate(year, month, day, format);
    if (candidate != null) {
      candidates.add(_ScoredExpiryCandidate(result: candidate, score: score));
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

  List<_ScoredExpiryCandidate> _filterValid(
    DateTime now,
    List<_ScoredExpiryCandidate> candidates,
  ) {
    final maxDate = DateTime(now.year + 3, now.month, now.day);
    return candidates.where((candidate) {
      final date = candidate.result.date;
      final isTooOld = date.isBefore(now.subtract(const Duration(days: 1)));
      final isTooFar = date.isAfter(maxDate);
      return !(isTooOld || isTooFar);
    }).toList();
  }

  int _scoreContext(String text, int start, int end) {
    final lineStart = text.lastIndexOf('\n', start - 1) + 1;
    final lineEndIndex = text.indexOf('\n', end);
    final lineEnd = lineEndIndex == -1 ? text.length : lineEndIndex;

    final beforeStart = start - 24 < lineStart ? lineStart : start - 24;
    final afterEnd = end + 10 > lineEnd ? lineEnd : end + 10;
    final beforeContext = text.substring(beforeStart, start);
    final afterContext = text.substring(end, afterEnd);

    const expiryKeywords = [
      'exp',
      'expiry',
      'best by',
      'best before',
      'bb/ma',
      'bb / ma',
      'bbma',
      'meilleur avant',
      'use by',
      'sell by',
    ];
    const manufactureKeywords = [
      'mfg',
      'manufactured',
      'manufacture',
      'packed on',
      'packed',
      'pkd',
      'pkg',
      'prod',
      'production',
    ];

    var score = 0;
    if (expiryKeywords.any(beforeContext.contains)) {
      score += 100;
    } else if (expiryKeywords.any(afterContext.contains)) {
      score += 40;
    }
    if (manufactureKeywords.any(beforeContext.contains)) {
      score -= 100;
    } else if (manufactureKeywords.any(afterContext.contains)) {
      score -= 40;
    }
    return score;
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

  int? _monthFromBilingualCode(String code) {
    switch (code.toLowerCase()) {
      case 'ja':
        return 1;
      case 'fe':
        return 2;
      case 'mr':
        return 3;
      case 'al':
        return 4;
      case 'ma':
        return 5;
      case 'jn':
        return 6;
      case 'jl':
        return 7;
      case 'au':
        return 8;
      case 'se':
        return 9;
      case 'oc':
        return 10;
      case 'no':
        return 11;
      case 'de':
        return 12;
    }
    return null;
  }
}
