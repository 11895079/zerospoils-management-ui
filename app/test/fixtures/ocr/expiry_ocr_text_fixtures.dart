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

  static const String multilingualEmbossedBestBefore = '''
A consommer de
preference avant le :
Ten minste
houdbaar tot:
Best before:
28 10 2028
0F 09353F
3016 43010
''';

  static const String multilingualEmbossedBestBeforeOcrConfused = '''
A consommer de
preference avant le :
Ten minste
houdbaar tot:
Best before:
2B 1O 2O2B
0F 09353F
3016 43010
''';

  static const String yearMonthDayCompactStamp = '''
BEST
BEFORE
MEILLEUR
AVANT
YEAR/MONTH/DAY · ANNEE/MOIS/JOUR
27APR22A
Use this number in correspondence related to this product.
''';

  static const String bestIfUsedByLabel = '''
BEST IF USED BY
APR 22 2026
KEEP REFRIGERATED
''';

  static const String compactNumericExpiryStamp = '''
EXPIRATION DATE
20270422
LOT 4C91
''';

  static const String yearlessUseOrFreezeBy = '''
USE OR FREEZE BY
APR 22
KEEP FROZEN
''';

  static const String spanishBestBeforeMonthAbbrev = '''
CONSUMIR PREFERENTEMENTE ANTES DE
22 ABR 2026
MANTENGASE REFRIGERADO
''';
}
