import '../models/receipt_line_item.dart';

class ReceiptParser {
  static const _ignoredKeywords = [
    'total',
    'subtotal',
    'tax',
    'hst',
    'gst',
    'vat',
    'change',
    'saving',
    'savings',
    'points',
    'reward',
    'rewards',
    'discount',
    'discounts',
    'credit',
    'debit',
    'cash',
  ];

  static const _ignoredPhrases = [
    'store #',
    'card number',
    'rewards program',
    'number of items sold',
    'your savings today',
    'promotional discounts',
    'total of your savings',
    'hst#',
  ];

  static const _departmentHeadings = {
    'grocery',
    'produce',
    'dairy',
    'bakery',
    'comm bakery',
    'comm. bakery',
    'meat',
    'deli',
    'frozen',
    'seafood',
    'household',
    'beverages',
    'snacks',
    'pantry',
  };

  static final RegExp _moneyPattern = RegExp(r'\d+[\.,]\d{2}');

  List<ReceiptLineItem> parse(String rawText) {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map(_normalizeWhitespace)
        .where((line) => line.isNotEmpty)
        .map((line) => ReceiptOcrLine(text: line))
        .toList();

    return parseOcrLines(lines);
  }

  List<ReceiptLineItem> parseOcrLines(List<ReceiptOcrLine> rawLines) {
    final indexedLines = rawLines.asMap().entries.toList()
      ..sort((left, right) {
        final leftLine = left.value;
        final rightLine = right.value;
        final photoOrder = leftLine.photoIndex.compareTo(rightLine.photoIndex);
        if (photoOrder != 0) {
          return photoOrder;
        }

        final leftBox = leftLine.box;
        final rightBox = rightLine.box;
        if (leftBox != null && rightBox != null) {
          final topOrder = leftBox.top.compareTo(rightBox.top);
          if (topOrder != 0) {
            return topOrder;
          }

          final leftOrder = leftBox.left.compareTo(rightBox.left);
          if (leftOrder != 0) {
            return leftOrder;
          }
        }

        return left.key.compareTo(right.key);
      });

    final items = <ReceiptLineItem>[];
    ReceiptOcrLine? pendingDescription;

    for (final entry in indexedLines) {
      final line = entry.value;
      final normalizedText = _normalizeWhitespace(line.text);
      if (normalizedText.isEmpty) {
        continue;
      }

      if (_shouldIgnoreLine(normalizedText)) {
        continue;
      }

      final prices = _extractPrices(normalizedText);
      if (prices.isEmpty) {
        if (_looksLikeProductDescription(normalizedText)) {
          pendingDescription = ReceiptOcrLine(
            text: _cleanDescription(normalizedText),
            photoIndex: line.photoIndex,
            box: line.box,
          );
        }
        continue;
      }

      final price = prices.last;
      final inlineDescription = _inlineDescription(normalizedText);

      String? name;
      ReceiptOcrBox? ocrBox;
      var photoIndex = line.photoIndex;
      if (inlineDescription != null &&
          _looksLikeProductDescription(inlineDescription)) {
        name = _cleanDescription(inlineDescription);
        ocrBox = line.box;
      } else if (pendingDescription != null &&
          pendingDescription.photoIndex == line.photoIndex) {
        name = _cleanDescription(pendingDescription.text);
        ocrBox = _mergeBoxes(pendingDescription.box, line.box);
        photoIndex = pendingDescription.photoIndex;
      }

      pendingDescription = null;

      if (name == null || name.isEmpty) {
        continue;
      }

      items.add(
        ReceiptLineItem(
          name: name,
          price: price,
          photoIndex: photoIndex,
          ocrBox: ocrBox,
        ),
      );
    }

    return items;
  }

  ReceiptOcrBox? _mergeBoxes(ReceiptOcrBox? left, ReceiptOcrBox? right) {
    if (left == null) {
      return right;
    }
    if (right == null) {
      return left;
    }
    return left.union(right);
  }

  String _normalizeWhitespace(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _shouldIgnoreLine(String line) {
    final lower = line.toLowerCase();
    final normalized = lower.replaceAll(RegExp(r'[^a-z]+'), ' ').trim();

    if (_ignoredPhrases.any(lower.contains)) {
      return true;
    }

    if (_departmentHeadings.contains(normalized)) {
      return true;
    }

    if (_ignoredKeywords.any((keyword) => lower.startsWith(keyword))) {
      return true;
    }

    if ((lower.contains('hst') ||
            lower.contains('gst') ||
            lower.contains('vat')) &&
        lower.contains('%')) {
      return true;
    }

    if (RegExp(r'^[\d\s\-().]+$').hasMatch(line)) {
      return true;
    }

    return false;
  }

  List<double> _extractPrices(String line) {
    return _moneyPattern
        .allMatches(line)
        .map((match) => double.tryParse(match.group(0)!.replaceAll(',', '.')))
        .whereType<double>()
        .toList();
  }

  String? _inlineDescription(String line) {
    final matches = _moneyPattern.allMatches(line).toList();
    if (matches.isEmpty) {
      return null;
    }

    final last = matches.last;
    final beforePrice = line.substring(0, last.start);
    final cleaned = beforePrice
        .replaceAll(RegExp(r'[$€£]'), ' ')
        .replaceAll(RegExp(r'\b[HFBTN]\b\s*$'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return cleaned.isEmpty ? null : cleaned;
  }

  bool _looksLikeProductDescription(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    if (!RegExp(r'[A-Za-z]').hasMatch(trimmed)) {
      return false;
    }

    if (trimmed.contains(':')) {
      return false;
    }

    if (trimmed.contains('@')) {
      return false;
    }

    if (RegExp(
      r'\bkg\b|\blb\b|\boz\b',
      caseSensitive: false,
    ).hasMatch(trimmed)) {
      return false;
    }

    final alphaCount = RegExp(r'[A-Za-z]').allMatches(trimmed).length;
    return alphaCount >= 3;
  }

  String _cleanDescription(String value) {
    return value
        .replaceAll(RegExp(r'[$€£]'), ' ')
        .replaceAll(RegExp(r'\b[HFBTN]\b\s*$'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
