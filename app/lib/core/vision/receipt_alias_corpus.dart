import 'receipt_alias_seed_data.dart';

class ReceiptAliasCorpus {
  const ReceiptAliasCorpus._();

  static const Set<String> stopWords = {
    'fresh',
    'food',
    'item',
    'large',
    'medium',
    'organic',
  };

  static final List<ReceiptAliasEntry> entries = List.unmodifiable(
    ReceiptAliasSeedData.groups.expand((group) => group.entries),
  );

  static final Map<String, List<ReceiptAliasEntry>> entriesByStoreStyle =
      Map<String, List<ReceiptAliasEntry>>.unmodifiable({
        for (final group in ReceiptAliasSeedData.groups)
          group.storeStyle: List<ReceiptAliasEntry>.unmodifiable(group.entries),
      });

  static final Map<String, Set<String>> canonicalNamesByStoreStyle =
      Map<String, Set<String>>.unmodifiable({
        for (final group in ReceiptAliasSeedData.groups)
          group.storeStyle: Set<String>.unmodifiable(
            group.entries.map(
              (entry) => _normalizeLookupValue(entry.canonical),
            ),
          ),
      });

  static final Map<String, String> tokenAliases = Map.unmodifiable({
    for (final entry in entries)
      if (!entry.isPhraseAlias && !entry.expandsToMultipleTokens)
        entry.alias: entry.canonical,
  });

  static final List<ReceiptAliasEntry> phraseAliases = List.unmodifiable(
    entries
        .where((entry) => entry.isPhraseAlias || entry.expandsToMultipleTokens)
        .toList()
      ..sort((left, right) => right.alias.length.compareTo(left.alias.length)),
  );

  static bool canonicalExistsInStoreStyle(
    String canonicalName,
    String storeStyle,
  ) {
    return canonicalNamesByStoreStyle[storeStyle]?.contains(
          _normalizeLookupValue(canonicalName),
        ) ??
        false;
  }

  static String? inferPreferredStoreStyle(Iterable<String> receiptLines) {
    final scores = <String, double>{};

    for (final line in receiptLines) {
      final normalizedLineValue = _normalizeLookupValue(line);
      final normalizedLine = ' $normalizedLineValue ';
      for (final group in ReceiptAliasSeedData.groups) {
        for (final entry in group.entries) {
          final normalizedAliasValue = _normalizeLookupValue(entry.alias);
          final alias = ' $normalizedAliasValue ';
          if (normalizedLine.contains(alias)) {
            final isExactLineMatch =
                normalizedLineValue == normalizedAliasValue;
            final isPhraseLike =
                entry.isPhraseAlias || entry.expandsToMultipleTokens;
            final weight =
                (entry.alias.length * group.priority) +
                (isExactLineMatch ? 10 : 0) +
                (isPhraseLike ? 6 : 0);
            scores[group.storeStyle] = (scores[group.storeStyle] ?? 0) + weight;
          }
        }
      }
    }

    String? bestStyle;
    var bestScore = 0.0;
    scores.forEach((style, score) {
      if (score > bestScore) {
        bestStyle = style;
        bestScore = score;
      }
    });
    return bestStyle;
  }

  static String _normalizeLookupValue(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }
}
