class ExpiryOcrTextFixtures {
  static const String canadianBbMaWithPackedDate = '''
TANGY GREEK YOGURT
LOT L2404
PKD 01/04/2026
BB/MA 21/04/2026
KEEP REFRIGERATED
''';

  static const String stampedBbMaDotted = '''
PLAIN YOGURT
BB / MA
21.04.26
L2 04A
''';

  static const String frenchBestBefore = '''
MEILLEUR AVANT
21/04/2026
GARDE AU FROID
''';

  static const String canadianMonthCodeBestBefore = '''
93TPAMER 2425 1029
BB/MA 2027 NO 20
''';

  static const String canadianMonthCodePackedAndBestBefore = '''
PKD 2025 OC29
BB/MA 2027 NO 20
''';
}
