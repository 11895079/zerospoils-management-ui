import '../../core/vision/batch_goods_photo_service.dart';
import '../../core/vision/receipt_alias_corpus.dart';
import '../../core/vision/receipt_goods_matcher.dart';
import '../screens/receipt_batch_review_screen.dart';

class ReceiptReviewItemMerger {
  const ReceiptReviewItemMerger({
    ReceiptGoodsMatcher matcher = const ReceiptGoodsMatcher(),
  }) : _matcher = matcher;

  final ReceiptGoodsMatcher _matcher;
  static const double _siblingSuppressionWindow = 0.2;

  List<ParsedReceiptItem> merge({
    required List<ParsedReceiptItem> parsedItems,
    required List<BatchGoodsPhotoSuggestion> goodsSuggestions,
  }) {
    final merged = <ParsedReceiptItem>[];
    final suppressedGoods = <String>{};
    final preferredStoreStyle = ReceiptAliasCorpus.inferPreferredStoreStyle(
      parsedItems.map((item) => item.name),
    );

    for (final item in parsedItems) {
      final goodsMatch = _matcher.bestMatchResult(
        item.name,
        goodsSuggestions,
        preferredStoreStyle: preferredStoreStyle,
      );

      if (goodsMatch != null) {
        final winningScore = goodsMatch.score;
        for (final suggestion in goodsSuggestions) {
          final suggestionScore = _matcher.similarityScore(
            item.name,
            suggestion.name,
            preferredStoreStyle: preferredStoreStyle,
          );
          if ((suggestionScore >= ReceiptGoodsMatcher.matchThreshold &&
                  winningScore - suggestionScore <=
                      _siblingSuppressionWindow) ||
              _isNestedSiblingSuggestion(
                goodsMatch.suggestion.name,
                suggestion.name,
              )) {
            suppressedGoods.add(_normalize(suggestion.name));
          }
        }
      }

      merged.add(
        ParsedReceiptItem(
          name: item.name,
          price: item.price,
          receiptPhotoIndex: item.receiptPhotoIndex,
          receiptBox: item.receiptBox,
          sourceLabel: goodsMatch == null
              ? item.sourceLabel
              : 'Receipt OCR + goods photo',
          matchExplanation: goodsMatch == null
              ? item.matchExplanation
              : _buildMatchedExplanation(goodsMatch),
        ),
      );
    }

    for (final suggestion in goodsSuggestions) {
      if (suppressedGoods.contains(_normalize(suggestion.name))) {
        continue;
      }

      merged.add(
        ParsedReceiptItem(
          name: suggestion.name,
          price: 0,
          sourceLabel: 'Goods photo',
          matchExplanation: _buildGoodsOnlyExplanation(suggestion),
        ),
      );
    }

    return merged;
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  String _buildMatchedExplanation(ReceiptGoodsMatchResult match) {
    final confidence = (match.suggestion.confidence * 100).round();
    final styleNote =
        match.styleBoostApplied && match.preferredStoreStyle != null
        ? ', ${match.preferredStoreStyle} style'
        : '';
    return 'Matched to ${match.suggestion.name} from goods photo ($confidence% confidence$styleNote).';
  }

  String _buildGoodsOnlyExplanation(BatchGoodsPhotoSuggestion suggestion) {
    final confidence = (suggestion.confidence * 100).round();
    return 'Suggested from goods photo ($confidence% confidence).';
  }

  bool _isNestedSiblingSuggestion(String winnerName, String candidateName) {
    final winner = _normalize(winnerName);
    final candidate = _normalize(candidateName);
    return winner != candidate &&
        (winner.contains(candidate) || candidate.contains(winner));
  }
}
