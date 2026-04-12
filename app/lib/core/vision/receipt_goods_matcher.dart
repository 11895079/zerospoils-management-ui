import 'batch_goods_photo_service.dart';
import 'receipt_alias_corpus.dart';

class ReceiptGoodsMatchResult {
  const ReceiptGoodsMatchResult({
    required this.suggestion,
    required this.score,
    required this.styleBoostApplied,
    this.preferredStoreStyle,
  });

  final BatchGoodsPhotoSuggestion suggestion;
  final double score;
  final bool styleBoostApplied;
  final String? preferredStoreStyle;
}

class ReceiptGoodsMatcher {
  const ReceiptGoodsMatcher();

  static const double matchThreshold = 0.6;
  static const double _scoreTieEpsilon = 0.0001;
  static const double _styleBoost = 0.08;

  BatchGoodsPhotoSuggestion? bestMatch(
    String receiptName,
    Iterable<BatchGoodsPhotoSuggestion> goodsSuggestions, {
    String? preferredStoreStyle,
  }) {
    return bestMatchResult(
      receiptName,
      goodsSuggestions,
      preferredStoreStyle: preferredStoreStyle,
    )?.suggestion;
  }

  ReceiptGoodsMatchResult? bestMatchResult(
    String receiptName,
    Iterable<BatchGoodsPhotoSuggestion> goodsSuggestions, {
    String? preferredStoreStyle,
  }) {
    BatchGoodsPhotoSuggestion? best;
    var bestScore = 0.0;
    var bestConfidence = 0.0;
    var styleBoostApplied = false;

    for (final suggestion in goodsSuggestions) {
      final scoreResult = _weightedScore(
        receiptName,
        suggestion.name,
        preferredStoreStyle: preferredStoreStyle,
      );
      final score = scoreResult.score;
      if (score > bestScore + _scoreTieEpsilon ||
          ((score - bestScore).abs() <= _scoreTieEpsilon &&
              suggestion.confidence > bestConfidence)) {
        best = suggestion;
        bestScore = score;
        bestConfidence = suggestion.confidence;
        styleBoostApplied = scoreResult.styleBoostApplied;
      }
    }

    if (best != null && bestScore >= matchThreshold) {
      return ReceiptGoodsMatchResult(
        suggestion: best,
        score: bestScore,
        styleBoostApplied: styleBoostApplied,
        preferredStoreStyle: preferredStoreStyle,
      );
    }
    return null;
  }

  double similarityScore(
    String receiptName,
    String goodsName, {
    String? preferredStoreStyle,
  }) {
    return _weightedScore(
      receiptName,
      goodsName,
      preferredStoreStyle: preferredStoreStyle,
    ).score;
  }

  ({double score, bool styleBoostApplied}) _weightedScore(
    String receiptName,
    String goodsName, {
    String? preferredStoreStyle,
  }) {
    final textScore = _textSimilarityScore(receiptName, goodsName);
    final styleBoostApplied =
        preferredStoreStyle != null &&
        ReceiptAliasCorpus.canonicalExistsInStoreStyle(
          goodsName,
          preferredStoreStyle,
        );
    final weightedScore = textScore + (styleBoostApplied ? _styleBoost : 0);
    return (score: weightedScore, styleBoostApplied: styleBoostApplied);
  }

  double _textSimilarityScore(String receiptName, String goodsName) {
    final receiptTokens = _normalizeTokens(receiptName);
    final goodsTokens = _normalizeTokens(goodsName);
    if (receiptTokens.isEmpty || goodsTokens.isEmpty) {
      return 0;
    }

    final receiptJoined = receiptTokens.join(' ');
    final goodsJoined = goodsTokens.join(' ');
    if (receiptJoined == goodsJoined) {
      return 1;
    }
    if (receiptJoined.contains(goodsJoined) ||
        goodsJoined.contains(receiptJoined)) {
      return 0.8;
    }

    final remainingGoods = [...goodsTokens];
    var matches = 0;
    for (final receiptToken in receiptTokens) {
      final matchIndex = remainingGoods.indexWhere(
        (goodsToken) => _tokenMatches(receiptToken, goodsToken),
      );
      if (matchIndex >= 0) {
        matches++;
        remainingGoods.removeAt(matchIndex);
      }
    }

    final baseScore =
        matches /
        (receiptTokens.length > goodsTokens.length
            ? receiptTokens.length
            : goodsTokens.length);
    final abbreviationScore = _abbreviationScore(receiptTokens, goodsTokens);
    return baseScore > abbreviationScore ? baseScore : abbreviationScore;
  }

  List<String> _normalizeTokens(String value) {
    final normalizedValue = _applyPhraseAliases(_normalizeValue(value));

    return normalizedValue
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .map((token) => ReceiptAliasCorpus.tokenAliases[token] ?? token)
        .map(_singularize)
        .where(
          (token) =>
              token.isNotEmpty && !ReceiptAliasCorpus.stopWords.contains(token),
        )
        .toList();
  }

  String _normalizeValue(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  String _applyPhraseAliases(String value) {
    var normalized = ' $value ';
    for (final entry in ReceiptAliasCorpus.phraseAliases) {
      normalized = normalized.replaceAll(
        ' ${entry.alias} ',
        ' ${entry.canonical} ',
      );
    }

    return normalized.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _tokenMatches(String left, String right) {
    if (left == right) {
      return true;
    }

    final minLength = left.length < right.length ? left.length : right.length;
    if (minLength < 3) {
      return false;
    }

    return left.startsWith(right) || right.startsWith(left);
  }

  double _abbreviationScore(
    List<String> receiptTokens,
    List<String> goodsTokens,
  ) {
    final receiptAbbreviation = receiptTokens.map((token) => token[0]).join();
    final goodsAbbreviation = goodsTokens.map((token) => token[0]).join();
    if (receiptAbbreviation == goodsAbbreviation) {
      return 0.75;
    }
    return 0;
  }

  String _singularize(String token) {
    if (token.length > 3 && token.endsWith('ies')) {
      return '${token.substring(0, token.length - 3)}y';
    }
    if (token.length > 3 && token.endsWith('s') && !token.endsWith('ss')) {
      return token.substring(0, token.length - 1);
    }
    return token;
  }
}
