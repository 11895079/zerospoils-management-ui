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

    _collectCandidates(
      candidates,
      lower,
      lower,
      preferredDateFormat,
      reference,
    );

    final normalized = _normalizeOcrDateSegments(lower);
    if (normalized != lower) {
      _collectCandidates(
        candidates,
        normalized,
        lower,
        preferredDateFormat,
        reference,
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

  void _collectCandidates(
    List<_ScoredExpiryCandidate> candidates,
    String scanText,
    String contextText,
    String preferredDateFormat,
    DateTime reference,
  ) {
    final lower = scanText;
    const monthNameTokenPattern =
        r'(jan|january|ene|enero|feb|february|mar|march|apr|april|abr|abril|may|mayo|jun|june|jul|july|aug|august|ago|agosto|sep|sept|september|set|oct|october|nov|november|dec|december|dic|diciembre)';

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
        _scoreContext(contextText, match.start, match.end),
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
      final score = _scoreContext(contextText, match.start, match.end);

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
      final score = _scoreContext(contextText, match.start, match.end);

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

    final compactIsoPattern = RegExp(r'\b(20\d{2})(\d{2})(\d{2})\b');
    for (final match in compactIsoPattern.allMatches(lower)) {
      final score = _scoreContext(contextText, match.start, match.end);
      if (score <= 0) {
        continue;
      }

      final year = int.tryParse(match.group(1) ?? '');
      final month = int.tryParse(match.group(2) ?? '');
      final day = int.tryParse(match.group(3) ?? '');
      _tryAddCandidate(candidates, year, month, day, 'YYYYMMDD', score + 20);
    }

    final monthNamePattern = RegExp(
      '$monthNameTokenPattern\\s*(\\d{1,2})(?:st|nd|rd|th)?[,]?\\s+(\\d{2,4})',
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
        _scoreContext(contextText, match.start, match.end),
      );
    }

    final dayMonthPattern = RegExp(
      '(\\d{1,2})\\s*$monthNameTokenPattern\\s*(\\d{2,4})',
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
        _scoreContext(contextText, match.start, match.end),
      );
    }

    final monthDayNoYearPattern = RegExp(
      '$monthNameTokenPattern\\s*(\\d{1,2})(?:st|nd|rd|th)?\\b(?!\\s*\\d{2,4})',
    );
    for (final match in monthDayNoYearPattern.allMatches(lower)) {
      final month = _monthFromName(match.group(1) ?? '');
      final day = int.tryParse(match.group(2) ?? '');
      if (month == null || day == null) continue;

      final score = _scoreContext(contextText, match.start, match.end);
      if (score <= 0) {
        continue;
      }

      final inferredYear = _inferOpenDateYear(reference, month, day);
      _tryAddCandidate(candidates, inferredYear, month, day, 'MMM DD', score);
    }

    final dayMonthNoYearPattern = RegExp(
      '(\\d{1,2})\\s*$monthNameTokenPattern\\b(?!\\s*\\d{2,4})',
    );
    for (final match in dayMonthNoYearPattern.allMatches(lower)) {
      final day = int.tryParse(match.group(1) ?? '');
      final month = _monthFromName(match.group(2) ?? '');
      if (month == null || day == null) continue;

      final score = _scoreContext(contextText, match.start, match.end);
      if (score <= 0) {
        continue;
      }

      final inferredYear = _inferOpenDateYear(reference, month, day);
      _tryAddCandidate(candidates, inferredYear, month, day, 'DD MMM', score);
    }

    final yearMonthDayTextPattern = RegExp(
      '(\\d{2,4})\\s*$monthNameTokenPattern\\s*(\\d{1,2})(?:[a-z])?',
    );
    for (final match in yearMonthDayTextPattern.allMatches(lower)) {
      final yearRaw = int.tryParse(match.group(1) ?? '');
      final month = _monthFromName(match.group(2) ?? '');
      final day = int.tryParse(match.group(3) ?? '');
      if (yearRaw == null || month == null || day == null) continue;

      final score =
          _scoreContext(contextText, match.start, match.end) +
          _scoreYearMonthDayContext(contextText, match.start, match.end);
      if (score <= 0) {
        continue;
      }

      final year = _normalizeYear(yearRaw);
      _tryAddCandidate(candidates, year, month, day, 'YY MMM DD', score);
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
        _scoreContext(contextText, match.start, match.end),
      );
    }
  }

  String _normalizeOcrDateSegments(String text) {
    final dateLikeSegmentPattern = RegExp(
      r'[0-9obsliz]{1,4}(?:[ ./-]+[0-9obsliz]{1,4}){2}',
    );

    return text.replaceAllMapped(dateLikeSegmentPattern, (match) {
      final segment = match.group(0)!;
      final buffer = StringBuffer();
      for (final rune in segment.runes) {
        final char = String.fromCharCode(rune);
        buffer.write(_normalizeOcrDateChar(char));
      }
      return buffer.toString();
    });
  }

  String _normalizeOcrDateChar(String char) {
    switch (char) {
      case 'o':
        return '0';
      case 'b':
        return '8';
      case 's':
        return '5';
      case 'l':
      case 'i':
        return '1';
      case 'z':
        return '2';
      default:
        return char;
    }
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
    final previousLineBreak = lineStart > 0
        ? text.lastIndexOf('\n', lineStart - 2)
        : -1;
    final nextLineBreak = lineEnd < text.length
        ? text.indexOf('\n', lineEnd + 1)
        : -1;
    final blockStart = previousLineBreak == -1 ? 0 : previousLineBreak + 1;
    final blockEnd = nextLineBreak == -1 ? text.length : nextLineBreak;

    final beforeStart = start - 32 < blockStart ? blockStart : start - 32;
    final afterEnd = end + 16 > blockEnd ? blockEnd : end + 16;
    final beforeContext = text.substring(beforeStart, start);
    final afterContext = text.substring(end, afterEnd);

    const expiryKeywords = [
      'exp',
      'expiry',
      'expiration',
      'expiration date',
      'best by',
      'best before',
      'best if used by',
      'best if used before',
      'bb/ma',
      'bb / ma',
      'bbma',
      'meilleur avant',
      'use by',
      'use or freeze by',
      'freeze by',
      'expires on',
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

  int _scoreYearMonthDayContext(String text, int start, int end) {
    final windowStart = start - 48 < 0 ? 0 : start - 48;
    final windowEnd = end + 48 > text.length ? text.length : end + 48;
    final context = text.substring(windowStart, windowEnd);

    const yearMonthDayKeywords = [
      'year/month/day',
      'year month day',
      'annee/mois/jour',
      'annee mois jour',
      'année/mois/jour',
      'année mois jour',
    ];

    if (yearMonthDayKeywords.any(context.contains)) {
      return 160;
    }

    return 0;
  }

  int _normalizeYear(int yearRaw) {
    if (yearRaw < 100) {
      return 2000 + yearRaw;
    }
    return yearRaw;
  }

  int _inferOpenDateYear(DateTime reference, int month, int day) {
    final candidateThisYear = DateTime(reference.year, month, day);
    if (!candidateThisYear.isBefore(
      reference.subtract(const Duration(days: 1)),
    )) {
      return reference.year;
    }
    return reference.year + 1;
  }

  int? _monthFromName(String name) {
    if (name.length < 3) return null;
    switch (name.substring(0, 3)) {
      case 'jan':
      case 'ene':
        return 1;
      case 'feb':
        return 2;
      case 'mar':
        return 3;
      case 'apr':
      case 'abr':
        return 4;
      case 'may':
        return 5;
      case 'jun':
        return 6;
      case 'jul':
        return 7;
      case 'aug':
      case 'ago':
        return 8;
      case 'sep':
      case 'set':
        return 9;
      case 'oct':
        return 10;
      case 'nov':
        return 11;
      case 'dec':
      case 'dic':
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
