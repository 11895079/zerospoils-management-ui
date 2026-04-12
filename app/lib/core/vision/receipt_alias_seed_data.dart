class ReceiptAliasEntry {
  const ReceiptAliasEntry({
    required this.alias,
    required this.canonical,
    required this.source,
    this.store,
    this.notes,
  });

  final String alias;
  final String canonical;
  final String source;
  final String? store;
  final String? notes;

  bool get isPhraseAlias => alias.contains(' ');
  bool get expandsToMultipleTokens => canonical.contains(' ');
}

class ReceiptAliasGroup {
  const ReceiptAliasGroup({
    required this.id,
    required this.label,
    required this.storeStyle,
    required this.priority,
    required this.entries,
  });

  final String id;
  final String label;
  final String storeStyle;
  final int priority;
  final List<ReceiptAliasEntry> entries;
}

class ReceiptAliasSeedData {
  const ReceiptAliasSeedData._();

  static const List<ReceiptAliasGroup> groups = [
    ReceiptAliasGroup(
      id: 'produce-shortcodes',
      label: 'Produce Shortcodes',
      storeStyle: 'generic-grocery-produce',
      priority: 1,
      entries: [
        ReceiptAliasEntry(
          alias: 'apl',
          canonical: 'apple',
          source: 'public-ocr-seed',
          store: 'generic-grocery-produce',
        ),
        ReceiptAliasEntry(
          alias: 'apls',
          canonical: 'apple',
          source: 'public-ocr-seed',
          store: 'generic-grocery-produce',
        ),
        ReceiptAliasEntry(
          alias: 'avo',
          canonical: 'avocado',
          source: 'public-ocr-seed',
          store: 'generic-grocery-produce',
        ),
        ReceiptAliasEntry(
          alias: 'avoc',
          canonical: 'avocado',
          source: 'public-ocr-seed',
          store: 'generic-grocery-produce',
        ),
        ReceiptAliasEntry(
          alias: 'ban',
          canonical: 'banana',
          source: 'public-ocr-seed',
          store: 'generic-grocery-produce',
        ),
        ReceiptAliasEntry(
          alias: 'bns',
          canonical: 'banana',
          source: 'public-ocr-seed',
          store: 'generic-grocery-produce',
        ),
        ReceiptAliasEntry(
          alias: 'broc',
          canonical: 'broccoli',
          source: 'public-ocr-seed',
          store: 'generic-grocery-produce',
        ),
        ReceiptAliasEntry(
          alias: 'cuk',
          canonical: 'cucumber',
          source: 'public-ocr-seed',
          store: 'generic-grocery-produce',
        ),
        ReceiptAliasEntry(
          alias: 'cuke',
          canonical: 'cucumber',
          source: 'public-ocr-seed',
          store: 'generic-grocery-produce',
        ),
        ReceiptAliasEntry(
          alias: 'pot',
          canonical: 'potato',
          source: 'public-ocr-seed',
          store: 'generic-grocery-produce',
        ),
        ReceiptAliasEntry(
          alias: 'rom',
          canonical: 'romaine',
          source: 'public-ocr-seed',
          store: 'generic-grocery-produce',
        ),
        ReceiptAliasEntry(
          alias: 'rom lett',
          canonical: 'romaine lettuce',
          source: 'public-ocr-seed',
          store: 'generic-grocery-produce',
        ),
        ReceiptAliasEntry(
          alias: 'strawb',
          canonical: 'strawberry',
          source: 'public-ocr-seed',
          store: 'generic-grocery-produce',
        ),
        ReceiptAliasEntry(
          alias: 'strwb',
          canonical: 'strawberry',
          source: 'public-ocr-seed',
          store: 'generic-grocery-produce',
        ),
        ReceiptAliasEntry(
          alias: 'swt',
          canonical: 'sweet',
          source: 'public-ocr-seed',
          store: 'generic-grocery-produce',
        ),
        ReceiptAliasEntry(
          alias: 'swt pot',
          canonical: 'sweet potato',
          source: 'public-ocr-seed',
          store: 'generic-grocery-produce',
        ),
        ReceiptAliasEntry(
          alias: 'tmto',
          canonical: 'tomato',
          source: 'public-ocr-seed',
          store: 'generic-grocery-produce',
        ),
        ReceiptAliasEntry(
          alias: 'tom',
          canonical: 'tomato',
          source: 'public-ocr-seed',
          store: 'generic-grocery-produce',
        ),
      ],
    ),
    ReceiptAliasGroup(
      id: 'protein-abbreviations',
      label: 'Protein Abbreviations',
      storeStyle: 'generic-grocery-protein',
      priority: 1,
      entries: [
        ReceiptAliasEntry(
          alias: 'chk',
          canonical: 'chicken',
          source: 'public-ocr-seed',
          store: 'generic-grocery-protein',
        ),
        ReceiptAliasEntry(
          alias: 'chkn',
          canonical: 'chicken',
          source: 'public-ocr-seed',
          store: 'generic-grocery-protein',
        ),
        ReceiptAliasEntry(
          alias: 'chk brst',
          canonical: 'chicken breast',
          source: 'public-ocr-seed',
          store: 'generic-grocery-protein',
        ),
        ReceiptAliasEntry(
          alias: 'chk thghs',
          canonical: 'chicken thighs',
          source: 'public-ocr-seed',
          store: 'generic-grocery-protein',
        ),
        ReceiptAliasEntry(
          alias: 'pk',
          canonical: 'pork',
          source: 'public-ocr-seed',
          store: 'generic-grocery-protein',
        ),
        ReceiptAliasEntry(
          alias: 'salm',
          canonical: 'salmon',
          source: 'public-ocr-seed',
          store: 'generic-grocery-protein',
        ),
        ReceiptAliasEntry(
          alias: 'thgh',
          canonical: 'thigh',
          source: 'public-ocr-seed',
          store: 'generic-grocery-protein',
        ),
        ReceiptAliasEntry(
          alias: 'thghs',
          canonical: 'thigh',
          source: 'public-ocr-seed',
          store: 'generic-grocery-protein',
        ),
        ReceiptAliasEntry(
          alias: 'thgs',
          canonical: 'thigh',
          source: 'public-ocr-seed',
          store: 'generic-grocery-protein',
        ),
      ],
    ),
    ReceiptAliasGroup(
      id: 'dairy-and-chilled',
      label: 'Dairy And Chilled',
      storeStyle: 'generic-grocery-dairy',
      priority: 1,
      entries: [
        ReceiptAliasEntry(
          alias: 'grk',
          canonical: 'greek',
          source: 'public-ocr-seed',
          store: 'generic-grocery-dairy',
        ),
        ReceiptAliasEntry(
          alias: 'grk ygt',
          canonical: 'greek yogurt',
          source: 'public-ocr-seed',
          store: 'generic-grocery-dairy',
        ),
        ReceiptAliasEntry(
          alias: 'mlk',
          canonical: 'milk',
          source: 'public-ocr-seed',
          store: 'generic-grocery-dairy',
        ),
        ReceiptAliasEntry(
          alias: 'org',
          canonical: 'organic',
          source: 'public-ocr-seed',
          store: 'generic-grocery-dairy',
        ),
        ReceiptAliasEntry(
          alias: 'org mlk',
          canonical: 'milk',
          source: 'public-ocr-seed',
          store: 'generic-grocery-dairy',
        ),
        ReceiptAliasEntry(
          alias: 'wmlk',
          canonical: 'whole milk',
          source: 'public-ocr-seed',
          store: 'generic-grocery-dairy',
        ),
        ReceiptAliasEntry(
          alias: 'wmlk yog',
          canonical: 'whole milk yogurt',
          source: 'public-ocr-seed',
          store: 'generic-grocery-dairy',
        ),
        ReceiptAliasEntry(
          alias: 'ygrt',
          canonical: 'yogurt',
          source: 'public-ocr-seed',
          store: 'generic-grocery-dairy',
        ),
        ReceiptAliasEntry(
          alias: 'ygt',
          canonical: 'yogurt',
          source: 'public-ocr-seed',
          store: 'generic-grocery-dairy',
        ),
      ],
    ),
    ReceiptAliasGroup(
      id: 'prepared-and-shelf',
      label: 'Prepared And Shelf Stable',
      storeStyle: 'generic-grocery-packaged',
      priority: 1,
      entries: [
        ReceiptAliasEntry(
          alias: 'tmto soup',
          canonical: 'tomato soup',
          source: 'public-ocr-seed',
          store: 'generic-grocery-packaged',
        ),
      ],
    ),
    ReceiptAliasGroup(
      id: 'compact-chain-variants',
      label: 'Compact Chain Receipt Variants',
      storeStyle: 'compact-chain-grocery',
      priority: 2,
      entries: [
        ReceiptAliasEntry(
          alias: 'bnns',
          canonical: 'banana',
          source: 'public-ocr-compact-style',
          store: 'compact-chain-grocery',
          notes: 'Compact line-item style with doubled trailing consonant.',
        ),
        ReceiptAliasEntry(
          alias: 'rmn lett',
          canonical: 'romaine lettuce',
          source: 'public-ocr-compact-style',
          store: 'compact-chain-grocery',
          notes: 'Condensed produce abbreviation pattern.',
        ),
        ReceiptAliasEntry(
          alias: 'brst chkn',
          canonical: 'chicken breast',
          source: 'public-ocr-compact-style',
          store: 'compact-chain-grocery',
          notes: 'Protein descriptor appears before the meat token.',
        ),
        ReceiptAliasEntry(
          alias: 'whl mlk',
          canonical: 'whole milk',
          source: 'public-ocr-compact-style',
          store: 'compact-chain-grocery',
          notes: 'Whole is shortened without removing the milk token.',
        ),
        ReceiptAliasEntry(
          alias: 'grk ygrt',
          canonical: 'greek yogurt',
          source: 'public-ocr-compact-style',
          store: 'compact-chain-grocery',
          notes: 'Two-token dairy shorthand variant.',
        ),
      ],
    ),
  ];
}
