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
    return parseDetailed(rawText).items;
  }

  ReceiptParseResult parseDetailed(String rawText) {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map(_normalizeWhitespace)
        .where((line) => line.isNotEmpty)
        .map((line) => ReceiptOcrLine(text: line))
        .toList();

    return parseDetailedOcrLines(lines);
  }

  List<ReceiptLineItem> parseOcrLines(List<ReceiptOcrLine> rawLines) {
    return parseDetailedOcrLines(rawLines).items;
  }

  ReceiptParseResult parseDetailedOcrLines(List<ReceiptOcrLine> rawLines) {
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

    final rows = _buildRows(indexedLines.map((entry) => entry.value).toList());

    final items = <ReceiptLineItem>[];
    final classifiedRows = <ReceiptClassifiedRow>[];
    _ReceiptOcrRow? pendingDescription;

    for (final row in rows) {
      final normalizedText = row.normalizedText;
      if (normalizedText.isEmpty) {
        continue;
      }

      final classification = _classifyRow(normalizedText);
      if (classification != ReceiptRowClassification.unknown) {
        classifiedRows.add(
          ReceiptClassifiedRow(
            text: normalizedText,
            photoIndex: row.photoIndex,
            box: row.box,
            classification: classification,
          ),
        );
        continue;
      }

      final prices = _extractPrices(normalizedText);
      if (prices.isEmpty) {
        if (_looksLikeProductDescription(normalizedText)) {
          pendingDescription = row.copyWith(
            normalizedText: _cleanDescription(normalizedText),
          );
          classifiedRows.add(
            ReceiptClassifiedRow(
              text: normalizedText,
              photoIndex: row.photoIndex,
              box: row.box,
              classification: ReceiptRowClassification.unknown,
            ),
          );
        } else {
          classifiedRows.add(
            ReceiptClassifiedRow(
              text: normalizedText,
              photoIndex: row.photoIndex,
              box: row.box,
              classification: ReceiptRowClassification.unknown,
            ),
          );
        }
        continue;
      }

      final price = prices.last;
      final inlineDescription = _inlineDescription(normalizedText);

      String? name;
      ReceiptOcrBox? ocrBox;
      var photoIndex = row.photoIndex;
      if (inlineDescription != null &&
          _looksLikeProductDescription(inlineDescription)) {
        name = _cleanDescription(inlineDescription);
        ocrBox = row.box;
      } else if (pendingDescription != null &&
          pendingDescription.photoIndex == row.photoIndex) {
        name = _cleanDescription(pendingDescription.normalizedText);
        ocrBox = _mergeBoxes(pendingDescription.box, row.box);
        photoIndex = pendingDescription.photoIndex;
      }

      pendingDescription = null;

      if (name == null || name.isEmpty) {
        classifiedRows.add(
          ReceiptClassifiedRow(
            text: normalizedText,
            photoIndex: row.photoIndex,
            box: row.box,
            classification: ReceiptRowClassification.unknown,
          ),
        );
        continue;
      }

      final item = ReceiptLineItem(
        name: name,
        price: price,
        photoIndex: photoIndex,
        ocrBox: ocrBox,
      );
      items.add(item);
      classifiedRows.add(
        ReceiptClassifiedRow(
          text: normalizedText,
          photoIndex: row.photoIndex,
          box: ocrBox ?? row.box,
          classification: ReceiptRowClassification.saleItem,
          extractedName: item.name,
          extractedPrice: item.price,
        ),
      );
    }

    return ReceiptParseResult(items: items, rows: classifiedRows);
  }

  List<_ReceiptOcrRow> _buildRows(List<ReceiptOcrLine> lines) {
    final rows = <_ReceiptOcrRow>[];

    for (final line in lines) {
      final normalizedText = _normalizeWhitespace(line.text);
      if (normalizedText.isEmpty) {
        continue;
      }

      if (rows.isEmpty) {
        rows.add(_ReceiptOcrRow.fromLine(line, normalizedText));
        continue;
      }

      final current = rows.last;
      if (_belongsToRow(current, line)) {
        rows[rows.length - 1] = current.addLine(line, normalizedText);
      } else {
        rows.add(_ReceiptOcrRow.fromLine(line, normalizedText));
      }
    }

    return rows;
  }

  bool _belongsToRow(_ReceiptOcrRow row, ReceiptOcrLine line) {
    if (row.photoIndex != line.photoIndex) {
      return false;
    }

    final rowBox = row.box;
    final lineBox = line.box;
    if (rowBox == null || lineBox == null) {
      return false;
    }

    final rowCenterY = (rowBox.top + rowBox.bottom) / 2;
    final lineCenterY = (lineBox.top + lineBox.bottom) / 2;
    final tolerance = _rowJoinTolerance(rowBox.height, lineBox.height);
    return (rowCenterY - lineCenterY).abs() <= tolerance;
  }

  double _rowJoinTolerance(double rowHeight, double lineHeight) {
    final dominantHeight = rowHeight > lineHeight ? rowHeight : lineHeight;
    return dominantHeight * 0.55 + 2;
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

  ReceiptRowClassification _classifyRow(String line) {
    final lower = line.toLowerCase();
    final normalized = lower.replaceAll(RegExp(r'[^a-z]+'), ' ').trim();

    if (_ignoredPhrases.any(lower.contains)) {
      return ReceiptRowClassification.storeInfo;
    }

    if (_departmentHeadings.contains(normalized)) {
      return ReceiptRowClassification.department;
    }

    if (lower.startsWith('saving') || lower.startsWith('savings')) {
      return ReceiptRowClassification.savings;
    }

    if (lower.startsWith('subtotal') || lower.startsWith('total')) {
      return ReceiptRowClassification.total;
    }

    if (lower.startsWith('hst') ||
        lower.startsWith('gst') ||
        lower.startsWith('vat') ||
        ((lower.contains('hst') ||
                lower.contains('gst') ||
                lower.contains('vat')) &&
            lower.contains('%'))) {
      return ReceiptRowClassification.tax;
    }

    if (lower.startsWith('points') ||
        lower.contains('reward') ||
        lower.contains('bonus points')) {
      return ReceiptRowClassification.loyalty;
    }

    if (lower.startsWith('credit') ||
        lower.startsWith('debit') ||
        lower.startsWith('cash')) {
      return ReceiptRowClassification.payment;
    }

    if (_ignoredKeywords.any((keyword) => lower.startsWith(keyword))) {
      return ReceiptRowClassification.unknown;
    }

    if (RegExp(r'^[\d\s\-().]+$').hasMatch(line)) {
      return ReceiptRowClassification.unknown;
    }

    return ReceiptRowClassification.unknown;
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

class _ReceiptOcrRow {
  final int photoIndex;
  final List<ReceiptOcrLine> lines;
  final String normalizedText;
  final ReceiptOcrBox? box;

  const _ReceiptOcrRow({
    required this.photoIndex,
    required this.lines,
    required this.normalizedText,
    required this.box,
  });

  factory _ReceiptOcrRow.fromLine(ReceiptOcrLine line, String normalizedText) {
    return _ReceiptOcrRow(
      photoIndex: line.photoIndex,
      lines: [line],
      normalizedText: normalizedText,
      box: line.box,
    );
  }

  _ReceiptOcrRow addLine(ReceiptOcrLine line, String normalizedLineText) {
    final mergedLines = [...lines, line]
      ..sort((left, right) {
        final leftBox = left.box;
        final rightBox = right.box;
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
        return 0;
      });

    ReceiptOcrBox? mergedBox = box;
    if (mergedBox == null) {
      mergedBox = line.box;
    } else if (line.box != null) {
      mergedBox = mergedBox.union(line.box!);
    }

    final mergedText = mergedLines
        .map((entry) => entry.text)
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return _ReceiptOcrRow(
      photoIndex: photoIndex,
      lines: mergedLines,
      normalizedText: mergedText.isEmpty ? normalizedLineText : mergedText,
      box: mergedBox,
    );
  }

  _ReceiptOcrRow copyWith({String? normalizedText}) {
    return _ReceiptOcrRow(
      photoIndex: photoIndex,
      lines: lines,
      normalizedText: normalizedText ?? this.normalizedText,
      box: box,
    );
  }
}
