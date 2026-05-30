library;

import '../models/item_model.dart';
import 'expiry_date_parser.dart';

enum FreshProduceClassification {
  fishSeafood,
  meatPoultry,
  deliPrepared,
  other,
}

enum OcrFieldConfidence { low, medium, high }

class FreshProduceOcrParseResult {
  const FreshProduceOcrParseResult({
    required this.isLikelyFreshProduce,
    required this.productDescription,
    required this.netWeightValue,
    required this.netWeightUnit,
    required this.pricePerWeight,
    required this.totalPrice,
    required this.packDate,
    required this.bestBeforeDate,
    required this.classification,
    required this.suggestedCategory,
    required this.extractedFieldCount,
    required this.productDescriptionConfidence,
    required this.netWeightConfidence,
    required this.pricePerWeightConfidence,
    required this.totalPriceConfidence,
    required this.packDateConfidence,
    required this.bestBeforeDateConfidence,
    required this.classificationConfidence,
  });

  final bool isLikelyFreshProduce;
  final String? productDescription;
  final double? netWeightValue;
  final Unit? netWeightUnit;
  final double? pricePerWeight;
  final double? totalPrice;
  final DateTime? packDate;
  final DateTime? bestBeforeDate;
  final FreshProduceClassification classification;
  final ItemCategory suggestedCategory;
  final int extractedFieldCount;
  final OcrFieldConfidence? productDescriptionConfidence;
  final OcrFieldConfidence? netWeightConfidence;
  final OcrFieldConfidence? pricePerWeightConfidence;
  final OcrFieldConfidence? totalPriceConfidence;
  final OcrFieldConfidence? packDateConfidence;
  final OcrFieldConfidence? bestBeforeDateConfidence;
  final OcrFieldConfidence classificationConfidence;

  bool get shouldFallbackToGenericOcr => extractedFieldCount < 2;
}

class FreshProduceOcrParser {
  const FreshProduceOcrParser({ExpiryDateParser? expiryDateParser})
    : _expiryDateParser = expiryDateParser ?? const ExpiryDateParser();

  final ExpiryDateParser _expiryDateParser;

  static final RegExp _pricePerWeightPattern = RegExp(
    r'(?:\$\s*)?(\d+(?:\.\d{1,2})?)\s*(?:\$\s*)?/\s*(kg|lb|100g)',
    caseSensitive: false,
  );

  static final RegExp _netWeightPattern = RegExp(
    r'(\d+(?:[\.,]\d+)?)\s*(kg|g|lb|lbs|oz)\b',
    caseSensitive: false,
  );

  static final RegExp _amountPattern = RegExp(
    r'(?:\$\s*)?(\d+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  bool shouldUseFreshProduceMode(
    String text, {
    required bool hasBarcodeDetected,
  }) {
    if (hasBarcodeDetected) {
      return false;
    }

    if (!_pricePerWeightPattern.hasMatch(text)) {
      return false;
    }

    final lower = text.toLowerCase();
    final hasKeyword = _containsAny(lower, const [
      'salmon',
      'fish',
      'seafood',
      'shrimp',
      'beef',
      'chicken',
      'pork',
      'lamb',
      'ham',
      'sausage',
      'deli',
      'fillet',
    ]);

    if (hasKeyword) {
      return true;
    }

    final nonEmptyLines = text
        .split(RegExp(r'\r?\n'))
        .where((line) => line.trim().isNotEmpty)
        .length;

    return nonEmptyLines >= 3;
  }

  FreshProduceOcrParseResult parseLabel(
    String text, {
    required bool hasBarcodeDetected,
    DateTime? now,
    String preferredDateFormat = 'MM/DD/YYYY',
  }) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final productDescription = _extractProductDescription(lines);
    final netWeight = _extractNetWeight(text);
    final pricePerWeight = _extractPricePerWeight(text);
    final totalPrice = _extractTotalPrice(lines);
    final packDate = _extractLabeledDate(
      lines,
      preferredDateFormat: preferredDateFormat,
      now: now,
      labelKeywords: const ['pack', 'packed', 'pkd', 'pack date'],
    );
    final bestBeforeDate =
        _extractLabeledDate(
          lines,
          preferredDateFormat: preferredDateFormat,
          now: now,
          labelKeywords: const [
            'best before',
            'best by',
            'use by',
            'expiry',
            'exp',
            'bb',
          ],
        ) ??
        _expiryDateParser
            .parse(text, now: now, preferredDateFormat: preferredDateFormat)
            ?.date;

    final classification = _classify(productDescription);
    final suggestedCategory = switch (classification) {
      FreshProduceClassification.fishSeafood => ItemCategory.meat,
      FreshProduceClassification.meatPoultry => ItemCategory.meat,
      FreshProduceClassification.deliPrepared => ItemCategory.other,
      FreshProduceClassification.other => ItemCategory.other,
    };

    var extractedFieldCount = 0;
    if (productDescription != null) extractedFieldCount++;
    if (netWeight.$1 != null && netWeight.$2 != null) extractedFieldCount++;
    if (pricePerWeight != null) extractedFieldCount++;
    if (totalPrice != null) extractedFieldCount++;
    if (packDate != null) extractedFieldCount++;
    if (bestBeforeDate != null) extractedFieldCount++;

    final productDescriptionConfidence = productDescription == null
        ? null
        : _confidenceForDescription(productDescription, classification);
    final netWeightConfidence = (netWeight.$1 != null && netWeight.$2 != null)
        ? OcrFieldConfidence.high
        : (netWeight.$1 != null ? OcrFieldConfidence.medium : null);
    final pricePerWeightConfidence = pricePerWeight != null
        ? OcrFieldConfidence.high
        : null;
    final totalPriceConfidence = totalPrice != null
        ? OcrFieldConfidence.high
        : null;
    final packDateConfidence = packDate != null
        ? OcrFieldConfidence.high
        : null;
    final bestBeforeDateConfidence = bestBeforeDate != null
        ? _bestBeforeConfidence(lines)
        : null;
    final classificationConfidence =
        classification == FreshProduceClassification.other
        ? OcrFieldConfidence.low
        : OcrFieldConfidence.high;

    return FreshProduceOcrParseResult(
      isLikelyFreshProduce: shouldUseFreshProduceMode(
        text,
        hasBarcodeDetected: hasBarcodeDetected,
      ),
      productDescription: productDescription,
      netWeightValue: netWeight.$1,
      netWeightUnit: netWeight.$2,
      pricePerWeight: pricePerWeight,
      totalPrice: totalPrice,
      packDate: packDate,
      bestBeforeDate: bestBeforeDate,
      classification: classification,
      suggestedCategory: suggestedCategory,
      extractedFieldCount: extractedFieldCount,
      productDescriptionConfidence: productDescriptionConfidence,
      netWeightConfidence: netWeightConfidence,
      pricePerWeightConfidence: pricePerWeightConfidence,
      totalPriceConfidence: totalPriceConfidence,
      packDateConfidence: packDateConfidence,
      bestBeforeDateConfidence: bestBeforeDateConfidence,
      classificationConfidence: classificationConfidence,
    );
  }

  OcrFieldConfidence _confidenceForDescription(
    String description,
    FreshProduceClassification classification,
  ) {
    final hasMultipleWords =
        description
            .split(RegExp(r'\s+'))
            .where((word) => word.isNotEmpty)
            .length >=
        2;
    if (classification != FreshProduceClassification.other &&
        hasMultipleWords) {
      return OcrFieldConfidence.high;
    }
    return OcrFieldConfidence.medium;
  }

  // Matches 'bb' or 'exp' only as whole words/abbreviations so that strings
  // like "BBQ" or "export" don't trigger a high-confidence best-before hit.
  static final _bbWordRegex = RegExp(r'\bbb\b', caseSensitive: false);
  static final _expWordRegex = RegExp(r'\bexp\b', caseSensitive: false);

  OcrFieldConfidence _bestBeforeConfidence(List<String> lines) {
    final directLabelHit = lines.any((line) {
      final lower = line.toLowerCase();
      return lower.contains('best before') ||
          lower.contains('best by') ||
          lower.contains('use by') ||
          lower.contains('expiry') ||
          _bbWordRegex.hasMatch(line) ||
          _expWordRegex.hasMatch(line);
    });
    if (directLabelHit) {
      return OcrFieldConfidence.high;
    }
    return OcrFieldConfidence.medium;
  }

  String? _extractProductDescription(List<String> lines) {
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (_containsAny(lower, const [
        'upc',
        'barcode',
        'total',
        'price',
        'best before',
        'best by',
        'pack',
        'expiry',
        'exp',
      ])) {
        continue;
      }
      if (_netWeightPattern.hasMatch(line) ||
          _pricePerWeightPattern.hasMatch(line)) {
        continue;
      }
      if (RegExp(r'[a-zA-Z]').hasMatch(line)) {
        return _titleCase(line);
      }
    }
    return null;
  }

  (double?, Unit?) _extractNetWeight(String text) {
    final match = _netWeightPattern.firstMatch(text);
    if (match == null) {
      return (null, null);
    }

    final rawValue = (match.group(1) ?? '').replaceAll(',', '.');
    final value = double.tryParse(rawValue);
    final unitRaw = (match.group(2) ?? '').toLowerCase();
    final unit = switch (unitRaw) {
      'kg' => Unit.kg,
      'g' => Unit.g,
      'lb' => Unit.lb,
      'lbs' => Unit.lb,
      'oz' => Unit.oz,
      _ => null,
    };

    return (value, unit);
  }

  double? _extractPricePerWeight(String text) {
    final match = _pricePerWeightPattern.firstMatch(text);
    if (match == null) {
      return null;
    }
    return double.tryParse(match.group(1) ?? '');
  }

  double? _extractTotalPrice(List<String> lines) {
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (!_containsAny(lower, const ['total', 'price', 'amount'])) {
        continue;
      }
      if (_pricePerWeightPattern.hasMatch(lower)) {
        continue;
      }
      final amounts = _amountPattern
          .allMatches(line)
          .map((m) => double.tryParse(m.group(1) ?? ''))
          .whereType<double>()
          .toList();
      if (amounts.isNotEmpty) {
        return amounts.last;
      }
    }
    return null;
  }

  DateTime? _extractLabeledDate(
    List<String> lines, {
    required List<String> labelKeywords,
    required String preferredDateFormat,
    DateTime? now,
  }) {
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (!_containsAny(lower, labelKeywords)) {
        continue;
      }
      final parsed = _expiryDateParser.parse(
        line,
        preferredDateFormat: preferredDateFormat,
        now: now,
      );
      if (parsed != null) {
        return parsed.date;
      }
    }
    return null;
  }

  FreshProduceClassification _classify(String? description) {
    if (description == null || description.trim().isEmpty) {
      return FreshProduceClassification.other;
    }

    final lower = description.toLowerCase();
    if (_containsAny(lower, const [
      'salmon',
      'tilapia',
      'cod',
      'halibut',
      'tuna',
      'shrimp',
      'lobster',
      'crab',
      'scallop',
      'seafood',
      'fish',
      'fillet',
    ])) {
      return FreshProduceClassification.fishSeafood;
    }

    if (_containsAny(lower, const [
      'beef',
      'chicken',
      'pork',
      'lamb',
      'turkey',
      'veal',
      'duck',
      'goose',
      'venison',
      'steak',
      'roast',
      'ribs',
      'chop',
      'tenderloin',
      'ground',
      'mince',
      'sausage',
      'bacon',
      'meat',
    ])) {
      return FreshProduceClassification.meatPoultry;
    }

    if (_containsAny(lower, const [
      'ham',
      'prosciutto',
      'salami',
      'pepperoni',
      'pastrami',
      'mortadella',
      'bologna',
      'liverwurst',
      'deli',
    ])) {
      return FreshProduceClassification.deliPrepared;
    }

    return FreshProduceClassification.other;
  }

  bool _containsAny(String value, List<String> candidates) {
    for (final candidate in candidates) {
      if (value.contains(candidate)) {
        return true;
      }
    }
    return false;
  }

  String _titleCase(String value) {
    final words = value
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    return words
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}
