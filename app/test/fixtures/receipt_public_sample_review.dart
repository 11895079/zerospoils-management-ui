class ReviewedReceiptAliasSample {
  const ReviewedReceiptAliasSample({
    required this.dataset,
    required this.styleBucket,
    required this.receiptLine,
    required this.expectedGoodsName,
    this.notes,
  });

  final String dataset;
  final String styleBucket;
  final String receiptLine;
  final String expectedGoodsName;
  final String? notes;
}

class ReviewedReceiptMergeSample {
  const ReviewedReceiptMergeSample({
    required this.dataset,
    required this.styleBucket,
    required this.receiptLines,
    required this.goodsSuggestions,
    required this.expectedSourceLabels,
    required this.expectedTrailingGoodsOnly,
    this.notes,
  });

  final String dataset;
  final String styleBucket;
  final List<String> receiptLines;
  final List<String> goodsSuggestions;
  final List<String> expectedSourceLabels;
  final List<String> expectedTrailingGoodsOnly;
  final String? notes;
}

class ReviewedReceiptRankingSample {
  const ReviewedReceiptRankingSample({
    required this.dataset,
    required this.styleBucket,
    required this.receiptLine,
    required this.goodsCandidates,
    required this.expectedGoodsName,
    this.preferredStoreStyle,
    this.notes,
  });

  final String dataset;
  final String styleBucket;
  final String receiptLine;
  final List<({String name, double confidence})> goodsCandidates;
  final String expectedGoodsName;
  final String? preferredStoreStyle;
  final String? notes;
}

class ReceiptPublicSampleReview {
  const ReceiptPublicSampleReview._();

  static const List<ReviewedReceiptAliasSample> matcherSamples = [
    ReviewedReceiptAliasSample(
      dataset: 'sroie-style-review',
      styleBucket: 'generic-grocery-produce',
      receiptLine: 'BNS',
      expectedGoodsName: 'Banana',
      notes: 'Short produce token kept after OCR normalization review.',
    ),
    ReviewedReceiptAliasSample(
      dataset: 'sroie-style-review',
      styleBucket: 'generic-grocery-protein',
      receiptLine: 'CHK THGHS',
      expectedGoodsName: 'Chicken thighs',
      notes: 'Protein abbreviation with omitted vowels.',
    ),
    ReviewedReceiptAliasSample(
      dataset: 'cord-style-review',
      styleBucket: 'generic-grocery-dairy',
      receiptLine: 'ORG MLK',
      expectedGoodsName: 'Milk',
      notes: 'Qualifier is intentionally removed by normalization.',
    ),
    ReviewedReceiptAliasSample(
      dataset: 'sroie-style-review',
      styleBucket: 'compact-chain-grocery',
      receiptLine: 'BRST CHKN',
      expectedGoodsName: 'Chicken breast',
      notes: 'Compact style with reversed token order.',
    ),
    ReviewedReceiptAliasSample(
      dataset: 'cord-style-review',
      styleBucket: 'compact-chain-grocery',
      receiptLine: 'WHL MLK',
      expectedGoodsName: 'Whole milk',
      notes: 'Two-token dairy shorthand reviewed from public OCR samples.',
    ),
    ReviewedReceiptAliasSample(
      dataset: 'cord-style-review',
      styleBucket: 'compact-chain-grocery',
      receiptLine: 'GRK YGRT',
      expectedGoodsName: 'Greek yogurt',
      notes: 'Dairy abbreviation variant with full yogurt consonant form.',
    ),
  ];

  static const List<ReviewedReceiptMergeSample> mergeSamples = [
    ReviewedReceiptMergeSample(
      dataset: 'reviewed-public-mix',
      styleBucket: 'compact-chain-grocery',
      receiptLines: ['BNNS', 'WHL MLK'],
      goodsSuggestions: ['Banana', 'Whole milk', 'Greek yogurt'],
      expectedSourceLabels: [
        'Receipt OCR + goods photo',
        'Receipt OCR + goods photo',
        'Goods photo',
      ],
      expectedTrailingGoodsOnly: ['Greek yogurt'],
      notes: 'Two matched OCR items plus one unmatched goods-only suggestion.',
    ),
    ReviewedReceiptMergeSample(
      dataset: 'reviewed-ambiguity-suppression',
      styleBucket: 'compact-chain-grocery',
      receiptLines: ['CHKN'],
      goodsSuggestions: ['Chicken thighs', 'Chicken breast'],
      expectedSourceLabels: ['Receipt OCR + goods photo'],
      expectedTrailingGoodsOnly: [],
      notes:
          'Generic OCR line should not produce an extra sibling goods row once one poultry candidate wins.',
    ),
    ReviewedReceiptMergeSample(
      dataset: 'reviewed-dairy-suppression',
      styleBucket: 'generic-grocery-dairy',
      receiptLines: ['ORG MLK', 'GRK YGT'],
      goodsSuggestions: ['Milk', 'Greek yogurt', 'Yogurt'],
      expectedSourceLabels: [
        'Receipt OCR + goods photo',
        'Receipt OCR + goods photo',
      ],
      expectedTrailingGoodsOnly: [],
      notes:
          'Goods suggestions that are close siblings of matched dairy lines should not create extra review noise.',
    ),
  ];

  static const List<ReviewedReceiptRankingSample> rankingSamples = [
    ReviewedReceiptRankingSample(
      dataset: 'reviewed-confidence-tiebreak',
      styleBucket: 'compact-chain-grocery',
      receiptLine: 'CHKN',
      goodsCandidates: [
        (name: 'Chicken breast', confidence: 0.62),
        (name: 'Chicken thighs', confidence: 0.94),
      ],
      expectedGoodsName: 'Chicken thighs',
      notes:
          'When textual relevance ties, higher goods-photo confidence should win.',
    ),
    ReviewedReceiptRankingSample(
      dataset: 'reviewed-style-weighting',
      styleBucket: 'compact-chain-grocery',
      receiptLine: 'CHKN',
      goodsCandidates: [
        (name: 'Chicken thighs', confidence: 0.75),
        (name: 'Chicken breast', confidence: 0.75),
      ],
      expectedGoodsName: 'Chicken breast',
      preferredStoreStyle: 'compact-chain-grocery',
      notes:
          'Compact-chain style should prefer the candidate represented in that store-style bucket when confidence is tied.',
    ),
    ReviewedReceiptRankingSample(
      dataset: 'reviewed-produce-confidence',
      styleBucket: 'generic-grocery-produce',
      receiptLine: 'ROM LETT',
      goodsCandidates: [
        (name: 'Romaine lettuce', confidence: 0.71),
        (name: 'Tomato', confidence: 0.96),
      ],
      expectedGoodsName: 'Romaine lettuce',
      notes:
          'Better text relevance should beat a much higher unrelated confidence value.',
    ),
    ReviewedReceiptRankingSample(
      dataset: 'reviewed-dairy-style-weighting',
      styleBucket: 'generic-grocery-dairy',
      receiptLine: 'ORG MLK',
      goodsCandidates: [
        (name: 'Milk', confidence: 0.72),
        (name: 'Whole milk yogurt', confidence: 0.72),
      ],
      expectedGoodsName: 'Milk',
      preferredStoreStyle: 'generic-grocery-dairy',
      notes:
          'Generic dairy style should keep the simpler milk mapping when confidence is tied.',
    ),
  ];
}
