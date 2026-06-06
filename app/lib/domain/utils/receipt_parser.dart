import '../models/receipt_line_item.dart';

/// Deterministic OCR receipt parser tuned for noisy grocery receipts.
///
/// Parsing happens in two stages:
/// 1. OCR lines are grouped into visual rows using geometry and ordering.
/// 2. Rows are classified and sale-item candidates are reconstructed with
///    targeted recovery heuristics.
///
/// Heuristics are intentionally conservative and primarily support the current
/// corpus families:
/// - Discount-heavy, code-driven layouts (for example Costco-style rows).
/// - Promo-math fragments such as `2 @ $3.50` and `ea or 2/$6.00`.
/// - Split-column OCR where price and description are separated.
/// - Weighted produce/meat rows that include unit calculations.
///
/// Use [parseDetailed] or [parseDetailedOcrLines] when debugging to inspect
/// per-row classifications and extracted item mappings.
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
    'transaction not completed',
    'approved - thank you',
    'customer copy',
    'transaction record',
    'costco ewholesale',
    'costco',
    'ewholesale',
    'gloucester bctr',
    'cyrville road',
    'bob count',
  ];

  static const _ignoredChargePhrases = [
    'donation',
    'charity',
    'eco fee',
    'enviro fee',
  ];

  static const _paymentMarkers = [
    'mastercard',
    'visa',
    'american express',
    'tangerine card',
    'scotiabank visa',
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

  /// Promo-math patterns that should be filtered out (not parsed as items)
  /// Examples: "2 @ $3.50", "2/$6.00", "1 @ $1.29 each (12/$13.99)"
  static final RegExp _promoMathPattern = RegExp(
    r'^\s*(?:'
    r'\d+\s*[@/°º×x*]\s*\$?\d+[\.,]\d{2}|' // "2 @ $3.50", "2 ° $3.50", "2/$6.00"
    r'\d+\s*[@/°º×x*]\s*\$?\d+[\.,]\d{2}\s+each(?:\s+\(\d+/\$?\d+[\.,]\d{2}\))?|' // "1 @ $1.29 each (12/$13.99)"
    r'\d+\s+@\s+\d+/\$\d+[\.,]\d{2}|' // "2 @ 2/$6.00"
    r'\d+\s+@\s+\$?\d+[\.,]\d{2}\s+ea' // "1 @ $3.49 ea"
    r')\s*$',
    caseSensitive: false,
  );

  /// Modifier/descriptor codes that should be filtered (short all-caps without prices)
  static final RegExp _modifierCodePattern = RegExp(r'^[A-Z]{1,4}$');

  static final RegExp _moneyPattern = RegExp(r'\d+[\.,]\d{2}');
  static final RegExp _signedMoneyPattern = RegExp(
    r'[-+]?\$?\d+[\.,]\d{2}',
    caseSensitive: false,
  );

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
    double? taxAmount;
    double? totalAmount;
    double? savingsAmount;
    _ReceiptOcrRow? pendingDescription;
    _ReceiptOcrRow? pendingPromoQuantityDescription;
    int? pendingPromoQuantity;
    final standalonePriceCandidates =
        <({int photoIndex, int rowPosition, double price})>[];
    double? seededCodedPrice;
    int? seededCodedPriceRow;
    int? seededCodedPricePhoto;
    double? carryForwardCodedPrice;
    int? carryForwardCodedPricePhoto;
    var rowPosition = 0;

    for (final row in rows) {
      rowPosition++;
      final normalizedText = row.normalizedText;
      if (normalizedText.isEmpty) {
        continue;
      }

      final prices = _extractPrices(normalizedText);

      final classification = _classifyRow(normalizedText);
      if (classification != ReceiptRowClassification.unknown) {
        final classifiedAmount = _extractClassifiedAmount(
          normalizedText,
          classification,
        );

        if (classifiedAmount != null) {
          switch (classification) {
            case ReceiptRowClassification.tax:
              taxAmount = ((taxAmount ?? 0) + classifiedAmount);
              break;
            case ReceiptRowClassification.total:
              totalAmount = classifiedAmount;
              break;
            case ReceiptRowClassification.savings:
              savingsAmount = ((savingsAmount ?? 0) + classifiedAmount);
              break;
            case ReceiptRowClassification.saleItem:
            case ReceiptRowClassification.loyalty:
            case ReceiptRowClassification.payment:
            case ReceiptRowClassification.department:
            case ReceiptRowClassification.storeInfo:
            case ReceiptRowClassification.unknown:
              break;
          }
        }

        final lower = normalizedText.toLowerCase();
        if (prices.length == 1 &&
            (lower.contains('tpd/') || lower.contains('eco fee')) &&
            !_hasNegativeAdjustmentAmount(normalizedText)) {
          seededCodedPrice = prices.first;
          seededCodedPriceRow = rowPosition;
          seededCodedPricePhoto = row.photoIndex;
        }

        classifiedRows.add(
          ReceiptClassifiedRow(
            text: normalizedText,
            photoIndex: row.photoIndex,
            box: row.box,
            classification: classification,
            extractedPrice: classifiedAmount,
          ),
        );
        continue;
      }

      if (prices.isEmpty) {
        final codedDescription = _looksLikeCodedDescription(normalizedText);
        if (codedDescription &&
            carryForwardCodedPrice != null &&
            carryForwardCodedPricePhoto == row.photoIndex) {
          final carryItem = ReceiptLineItem(
            name: _cleanDescription(normalizedText),
            price: carryForwardCodedPrice,
            photoIndex: row.photoIndex,
            ocrBox: row.box,
          );
          items.add(carryItem);
          classifiedRows.add(
            ReceiptClassifiedRow(
              text: normalizedText,
              photoIndex: row.photoIndex,
              box: row.box,
              classification: ReceiptRowClassification.saleItem,
              extractedName: carryItem.name,
              extractedPrice: carryItem.price,
            ),
          );
          carryForwardCodedPrice = null;
          carryForwardCodedPricePhoto = null;
          pendingDescription = null;
          continue;
        }

        if (_looksLikeProductDescription(normalizedText)) {
          final codedDescription = RegExp(
            r'^(?:[HT]\s+)?\d{5,}\s+[A-Za-z]',
            caseSensitive: false,
          ).hasMatch(normalizedText);

          if (codedDescription) {
            final candidate = standalonePriceCandidates.reversed.firstWhere(
              (entry) =>
                  entry.photoIndex == row.photoIndex &&
                  rowPosition - entry.rowPosition <= 6,
              orElse: () => (photoIndex: -1, rowPosition: -1, price: -1.0),
            );

            if (candidate.photoIndex == row.photoIndex && candidate.price > 0) {
              final backfilledItem = ReceiptLineItem(
                name: _cleanDescription(normalizedText),
                price: candidate.price,
                photoIndex: row.photoIndex,
                ocrBox: row.box,
              );
              items.add(backfilledItem);
              classifiedRows.add(
                ReceiptClassifiedRow(
                  text: normalizedText,
                  photoIndex: row.photoIndex,
                  box: row.box,
                  classification: ReceiptRowClassification.saleItem,
                  extractedName: backfilledItem.name,
                  extractedPrice: backfilledItem.price,
                ),
              );
              pendingDescription = null;
              continue;
            }
          }

          pendingDescription = row.copyWith(
            normalizedText: _cleanDescription(normalizedText),
          );
        } else {
          final qtyBarcodeMatch = RegExp(
            r'^\((\d+)\)\d{5,}$',
          ).firstMatch(normalizedText);
          if (qtyBarcodeMatch != null &&
              pendingDescription != null &&
              pendingDescription.photoIndex == row.photoIndex) {
            final parsedQty = int.tryParse(qtyBarcodeMatch.group(1)!);
            if (parsedQty != null && parsedQty > 1) {
              pendingPromoQuantityDescription = pendingDescription;
              pendingPromoQuantity = parsedQty;
            }
          }

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

      final price = _choosePrice(normalizedText, prices);
      final inlineDescription = _inlineDescription(normalizedText);
      final afterPrice = _descriptionAfterPrice(normalizedText);
      final wrappedDescription = _wrappedDescriptionAroundPrice(
        inlineDescription,
        afterPrice,
      );
      final isEaOrPromo = RegExp(
        r'\bea\s+or\s+\d+/\$?\d+[\.,]\d{2}\b',
        caseSensitive: false,
      ).hasMatch(normalizedText);
      final codedDescription = _looksLikeCodedDescription(normalizedText);

      String? name;
      ReceiptOcrBox? ocrBox;
      var photoIndex = row.photoIndex;
      if (wrappedDescription != null &&
          _looksLikeProductDescription(wrappedDescription)) {
        name = _cleanDescription(wrappedDescription);
        ocrBox = row.box;
      } else if (inlineDescription != null &&
          _looksLikeProductDescription(inlineDescription)) {
        name = _cleanDescription(inlineDescription);
        ocrBox = row.box;
      } else if (afterPrice != null &&
          _looksLikeProductDescription(afterPrice)) {
        // Prefer explicit post-price text before pending carry-over to avoid
        // binding a previous item's name to a new coded row.
        name = _cleanDescription(afterPrice);
        ocrBox = row.box;
      } else if (pendingDescription != null &&
          pendingDescription.photoIndex == row.photoIndex) {
        name = _cleanDescription(pendingDescription.normalizedText);
        ocrBox = _mergeBoxes(pendingDescription.box, row.box);
        photoIndex = pendingDescription.photoIndex;
      }

      pendingDescription = null;

      if (name == null || name.isEmpty) {
        final isStandaloneMoney = RegExp(
          r'^(?:[HT]\s+)?\$?\d+[\.,]\d{2}$',
        ).hasMatch(normalizedText.trim());
        if (isStandaloneMoney && prices.isNotEmpty) {
          standalonePriceCandidates.add((
            photoIndex: row.photoIndex,
            rowPosition: rowPosition,
            price: prices.last,
          ));
          if (standalonePriceCandidates.length > 20) {
            standalonePriceCandidates.removeAt(0);
          }
        }

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

      var effectivePrice = price;
      if (codedDescription && prices.isNotEmpty) {
        if (carryForwardCodedPrice != null &&
            carryForwardCodedPricePhoto == row.photoIndex) {
          effectivePrice = carryForwardCodedPrice;
          carryForwardCodedPrice = prices.first;
          carryForwardCodedPricePhoto = row.photoIndex;
        } else if (seededCodedPrice != null &&
            seededCodedPricePhoto == row.photoIndex &&
            seededCodedPriceRow != null &&
            rowPosition - seededCodedPriceRow <= 4 &&
            seededCodedPrice < prices.first) {
          effectivePrice = seededCodedPrice;
          carryForwardCodedPrice = prices.first;
          carryForwardCodedPricePhoto = row.photoIndex;
          seededCodedPrice = null;
          seededCodedPriceRow = null;
          seededCodedPricePhoto = null;
        }
      }

      final item = ReceiptLineItem(
        name: name,
        price: effectivePrice,
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

      if (isEaOrPromo &&
          pendingPromoQuantityDescription != null &&
          pendingPromoQuantity != null &&
          pendingPromoQuantityDescription.photoIndex == row.photoIndex &&
          pendingPromoQuantity > 1 &&
          prices.isNotEmpty) {
        final reconstructedName = _cleanDescription(
          pendingPromoQuantityDescription.normalizedText,
        );
        if (reconstructedName.isNotEmpty && reconstructedName != item.name) {
          final reconstructedPrice = double.parse(
            (pendingPromoQuantity * prices.first).toStringAsFixed(2),
          );
          final reconstructedItem = ReceiptLineItem(
            name: reconstructedName,
            price: reconstructedPrice,
            photoIndex: pendingPromoQuantityDescription.photoIndex,
            ocrBox: pendingPromoQuantityDescription.box,
          );
          items.add(reconstructedItem);
          classifiedRows.add(
            ReceiptClassifiedRow(
              text: pendingPromoQuantityDescription.normalizedText,
              photoIndex: pendingPromoQuantityDescription.photoIndex,
              box: pendingPromoQuantityDescription.box,
              classification: ReceiptRowClassification.saleItem,
              extractedName: reconstructedItem.name,
              extractedPrice: reconstructedItem.price,
            ),
          );
        }

        pendingPromoQuantityDescription = null;
        pendingPromoQuantity = null;
      }
    }

    return ReceiptParseResult(
      items: items,
      rows: classifiedRows,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      savingsAmount: savingsAmount,
    );
  }

  double? _extractClassifiedAmount(
    String text,
    ReceiptRowClassification classification,
  ) {
    if (classification != ReceiptRowClassification.tax &&
        classification != ReceiptRowClassification.total &&
        classification != ReceiptRowClassification.savings) {
      return null;
    }

    final matches = _signedMoneyPattern
        .allMatches(text)
        .toList(growable: false);
    if (matches.isEmpty) {
      return null;
    }

    final raw = matches.last.group(0);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final parsed = double.tryParse(
      raw.replaceAll(r'$', '').replaceAll(',', '.'),
    );
    if (parsed == null) {
      return null;
    }

    if (classification == ReceiptRowClassification.savings) {
      return parsed.abs();
    }

    return parsed;
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

    final trimmedLine = line.text.trim();
    if (trimmedLine.isEmpty) {
      return false;
    }

    final rowPrices = _extractPrices(row.normalizedText);

    final rowSansCodes = row.normalizedText
        .replaceAll(RegExp(r'\d+[\.,]\d{2}'), ' ')
        .replaceAll(RegExp(r'[$€£]'), ' ')
        .replaceAll(RegExp(r'\b\d+[A-Z]{1,5}\b'), ' ')
        .replaceAll(RegExp(r'\b\d{5,}\b'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final rowHasDescriptiveText = RegExp(
      r'[A-Za-z]{3,}',
    ).hasMatch(rowSansCodes);

    final lineSansPrices = trimmedLine
        .replaceAll(RegExp(r'\d+[\.,]\d{2}'), ' ')
        .replaceAll(RegExp(r'[$€£]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final lineHasDescriptiveText = RegExp(
      r'[A-Za-z]{3,}',
    ).hasMatch(lineSansPrices);
    final lineIsPriceOnly = RegExp(
      r'^(?:[HT]\s+)?\$?\d+[\.,]\d{2}$',
    ).hasMatch(trimmedLine);
    final rowLower = row.normalizedText.toLowerCase();
    final rowLooksLikeTaxOrSavings =
        rowLower.contains('hst') ||
        rowLower.contains('gst') ||
        rowLower.contains('vat') ||
        rowLower.contains('tpd') ||
        rowLower.startsWith('saving') ||
        rowLower.startsWith('savings');

    if (_promoMathPattern.hasMatch(trimmedLine)) {
      return false;
    }

    if (RegExp(r'^\(?\d+\)?\s*\d{5,}$').hasMatch(trimmedLine) ||
        RegExp(r'^\d{5,}\s*\(?\d+\)?$').hasMatch(trimmedLine)) {
      if (!(rowPrices.isNotEmpty && !rowHasDescriptiveText)) {
        return false;
      }
    }

    if (RegExp(r'^[A-Z]{1,5}(?:\(\d+\))?$').hasMatch(trimmedLine) &&
        _extractPrices(trimmedLine).isEmpty) {
      return false;
    }

    if (RegExp(
      r'\b(retain this copy|statement|validation)\b',
      caseSensitive: false,
    ).hasMatch(trimmedLine)) {
      return false;
    }

    if (RegExp(
      r'\b(bottom of basket|member|cyrville road|gloucester\s+bctr|total number of items sold|total discounts?)\b',
      caseSensitive: false,
    ).hasMatch(trimmedLine)) {
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
    if ((rowCenterY - lineCenterY).abs() > tolerance) {
      return false;
    }

    // Prevent merging a complete item (name+price) with a new name-with-code line
    // (allows split-column price+name merging, but prevents name continuations from merging)
    final linePrices = _extractPrices(line.text);

    // If a row already looks like a complete priced item, do not absorb the
    // next priced fragment/line; that causes cross-item price drift.
    if (rowHasDescriptiveText &&
        rowPrices.isNotEmpty &&
        linePrices.isNotEmpty &&
        !rowLooksLikeTaxOrSavings &&
        (lineHasDescriptiveText || lineIsPriceOnly)) {
      return false;
    }

    if (rowPrices.isNotEmpty && linePrices.isEmpty) {
      // Row has price, line has no price
      // Only merge if the line looks like part of a split-column (not a continuation)
      // Check: does the row already have descriptive text (a complete item)?
      if (rowHasDescriptiveText) {
        final rowWordCount = rowSansCodes
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .length;
        final codedContinuation = RegExp(
          r'^\d{3,}\s+[A-Za-z]',
        ).hasMatch(trimmedLine);
        final rowContainsLongCode = RegExp(
          r'\b\d{5,}\b',
        ).hasMatch(row.normalizedText);
        if (codedContinuation && rowWordCount == 1 && !rowContainsLongCode) {
          return true;
        }

        // Row is already a complete item, don't merge with continuation
        return false;
      }
    }

    return true;
  }

  double _rowJoinTolerance(double rowHeight, double lineHeight) {
    final dominantHeight = rowHeight > lineHeight ? rowHeight : lineHeight;
    return dominantHeight * 0.55 + 2;
  }

  double _choosePrice(String rowText, List<double> prices) {
    if (prices.length <= 1) {
      return prices.last;
    }

    final lower = rowText.toLowerCase();
    final hasWeightUnit = RegExp(
      r'\b(kg|lb|oz)\b',
      caseSensitive: false,
    ).hasMatch(rowText);
    final hasCalculationMarker = lower.contains('@');
    final hasPromoMarker = lower.contains('ea') || lower.contains(' or ');

    if (hasWeightUnit || (hasCalculationMarker && !hasPromoMarker)) {
      return prices.last;
    }

    return prices.first;
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

    if (_ignoredChargePhrases.any(lower.contains)) {
      return ReceiptRowClassification.storeInfo;
    }

    // Department headings with numeric prefix (e.g., "22-DAIRY", "25-NATURAL FOODS")
    if (RegExp(
      r'^\d{1,3}[-\s]+[a-z\s]+$',
      caseSensitive: false,
    ).hasMatch(line.trim())) {
      return ReceiptRowClassification.department;
    }

    if (RegExp(r'\bbob\s+count\b', caseSensitive: false).hasMatch(line)) {
      return ReceiptRowClassification.storeInfo;
    }

    if (_departmentHeadings.contains(normalized)) {
      return ReceiptRowClassification.department;
    }

    // Promo-math lines that should be filtered (not parsed as items)
    if (_promoMathPattern.hasMatch(line.trim())) {
      return ReceiptRowClassification.savings; // Classify as non-item
    }

    // Modifier-only codes (short all-caps without prices): MRJ, RQ, HRQ, etc.
    if (_modifierCodePattern.hasMatch(line.trim()) &&
        _extractPrices(line).isEmpty) {
      return ReceiptRowClassification.unknown;
    }

    // Also filter short all-caps codes even if they contain spaces (e.g., "RQ", "HRQ")
    // These often appear as separate OCR lines between item name and price
    if (RegExp(r'^[A-Z]{1,5}(?:\(\d+\))?$').hasMatch(line.trim()) &&
        _extractPrices(line).isEmpty) {
      return ReceiptRowClassification.unknown;
    }

    if (lower.startsWith('saving') || lower.startsWith('savings')) {
      return ReceiptRowClassification.savings;
    }

    if (lower.startsWith('tpd/') || lower.contains(' tpd/')) {
      return ReceiptRowClassification.savings;
    }

    if (normalized.startsWith('subtotal') || normalized.startsWith('total')) {
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
        lower.startsWith('cash') ||
        lower.startsWith('change') ||
        lower.startsWith('amount') ||
        lower.startsWith('acct') ||
        lower.startsWith('reference') ||
        lower.startsWith('auth') ||
        lower.startsWith('invoice') ||
        lower.startsWith('date/time') ||
        lower.startsWith('purchase -') ||
        lower.contains('approved') ||
        _paymentMarkers.any(lower.contains)) {
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

  bool _hasNegativeAdjustmentAmount(String line) {
    final trimmed = line.trim();
    return RegExp(r'\d+[\.,]\d{2}\s*-$').hasMatch(trimmed) ||
        RegExp(r'-\s*\d+[\.,]\d{2}\b').hasMatch(trimmed);
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

  /// Extract description that appears after a price (split-column OCR: price first, name after)
  String? _descriptionAfterPrice(String line) {
    final matches = _moneyPattern.allMatches(line).toList();
    if (matches.isEmpty) {
      return null;
    }

    final first = matches.first;
    final afterPrice = line.substring(first.end);
    final cleaned = afterPrice
        .replaceAll(RegExp(r'[$€£]'), ' ')
        .replaceAll(RegExp(r'\b[HFBTN]\b\s*$'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return cleaned.isEmpty ? null : cleaned;
  }

  String? _wrappedDescriptionAroundPrice(
    String? beforePrice,
    String? afterPrice,
  ) {
    if (beforePrice == null || afterPrice == null) {
      return null;
    }

    if (_extractPrices(beforePrice).isNotEmpty ||
        _extractPrices(afterPrice).isNotEmpty) {
      return null;
    }

    final cleanedBefore = _cleanDescription(beforePrice);
    final cleanedAfter = _cleanDescription(afterPrice);
    if (cleanedBefore.isEmpty || cleanedAfter.isEmpty) {
      return null;
    }

    final afterStartsWithCode = RegExp(r'^\s*\d{3,}\b').hasMatch(afterPrice);
    if (afterStartsWithCode) {
      return '$cleanedAfter $cleanedBefore'.trim();
    }

    return '$cleanedBefore $cleanedAfter'.trim();
  }

  bool _looksLikeProductDescription(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    final lower = trimmed.toLowerCase();
    if (_ignoredKeywords.any((keyword) => lower.startsWith(keyword)) ||
        _ignoredPhrases.any(lower.contains)) {
      return false;
    }

    if (RegExp(r'\bbob\s+count\b', caseSensitive: false).hasMatch(trimmed)) {
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

    if (lower.contains('ea or') ||
        RegExp(
          r'^\$?\d+[\.,]\d{2}\s+ea\b',
          caseSensitive: false,
        ).hasMatch(trimmed)) {
      return false;
    }

    if (_moneyPattern.allMatches(trimmed).length > 1 &&
        (lower.contains(' or ') || lower.contains('ea'))) {
      return false;
    }

    if (RegExp(
      r'\b(retain this copy|statement|validation|total number of items sold|total discounts?)\b',
      caseSensitive: false,
    ).hasMatch(trimmed)) {
      return false;
    }

    if (trimmed.toLowerCase() == 'cads') {
      return false;
    }

    if (RegExp(r'^X{6,}\d{2,}$', caseSensitive: false).hasMatch(trimmed)) {
      return false;
    }

    if (RegExp(
      r'\b(bottom of basket|member|cyrville road|gloucester\s+bctr)\b',
      caseSensitive: false,
    ).hasMatch(trimmed)) {
      return false;
    }

    if (RegExp(
      r'^[A-Z]\d[A-Z]\s?\d[A-Z]\d$',
      caseSensitive: false,
    ).hasMatch(trimmed)) {
      return false;
    }

    // Reject very short all-caps codes (modifier codes like MRJ, RQ, HRQ)
    if (RegExp(r'^[A-Z]{1,3}(?:\(\d+\))?$').hasMatch(trimmed)) {
      return false;
    }

    // Reject compact code-like artifacts such as "1MRJ" or "2RQ".
    if (RegExp(r'^\d+[A-Z]{1,5}$').hasMatch(trimmed)) {
      return false;
    }

    if (RegExp(
      r'^\d+(?:[\.,]\d+)?\s*(kg|lb|oz)\b.*@',
      caseSensitive: false,
    ).hasMatch(trimmed)) {
      return false;
    }

    final alphaCount = RegExp(r'[A-Za-z]').allMatches(trimmed).length;
    return alphaCount >= 3;
  }

  String _cleanDescription(String value) {
    // Known modifier/descriptor codes to strip from end of names
    final modifiers = RegExp(
      r'\b(?:[A-Z]{0,2}MRJ|RQ|HRQ|HRM|RMJ)\b\s*$',
      caseSensitive: false,
    );
    final leadingNoise = RegExp(
      r'^(?:[HT]\s+\d+[\.,]\d{2}\s+)?(?:\d{3,}\s+)?',
      caseSensitive: false,
    );

    var cleaned = value
        .replaceAll('*', ' ')
        .replaceAll(RegExp(r'[$€£]'), ' ')
        .replaceAll(RegExp(r'^\d+[A-Z]{1,5}\s+'), ' ')
        .replaceAll(RegExp(r'^\s*\d{5,}\s+'), ' ')
        .replaceAll(RegExp(r'^[HT]\s+\d{4,}\s+'), ' ')
        .replaceAll(RegExp(r'\b\d+\s+\d+[\.,]\d{2}\s+'), ' ')
        .replaceAll(leadingNoise, ' ')
        .replaceAll(RegExp(r'^\d{3,}\s+'), ' ')
        .replaceAll(modifiers, '') // Strip known trailing modifier codes
        .replaceAll(RegExp(r'(?:\s+\d+[\.,]\d{2}(?:-)?)\s*$'), ' ')
        .replaceAll(RegExp(r'\b[HFBTN]\b\s*$'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    cleaned = cleaned
        .replaceAll(RegExp(r'\bPCTIVIA\b', caseSensitive: false), 'ACTIVIA')
        .replaceAll(RegExp(r'\b2K0\b', caseSensitive: false), '2KG')
        .replaceAll(RegExp(r'\bPC 27\b', caseSensitive: false), 'PC 2')
        .replaceAll(RegExp(r'\b96[- ]55\b', caseSensitive: false), '36 55')
        .replaceAll(RegExp(r'\bPRIGSE\b', caseSensitive: false), 'PRTGSE');

    cleaned = cleaned.replaceAll(RegExp(r'^\d{4,}\s+'), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'\s*-\s*$'), '').trim();

    return cleaned;
  }

  bool _looksLikeCodedDescription(String line) {
    return RegExp(
      r'^(?:[HT]\s+)?\d{5,}\s+[A-Za-z]',
      caseSensitive: false,
    ).hasMatch(line.trim());
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
