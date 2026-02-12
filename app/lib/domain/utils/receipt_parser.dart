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
  ];

  List<ReceiptLineItem> parse(String rawText) {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final items = <ReceiptLineItem>[];

    for (final line in lines) {
      final lower = line.toLowerCase();
      if (_ignoredKeywords.any((k) => lower.startsWith(k))) {
        continue;
      }

      final match = RegExp(r'([\d]+[\.,]\d{2})').firstMatch(line);
      if (match == null) continue;

      final priceString = match.group(1)!.replaceAll(',', '.');
      final price = double.tryParse(priceString);
      if (price == null) continue;

      final name = line
          .replaceAll(RegExp(r'[$€£]'), '')
          .replaceAll(priceString, '')
          .trim();

      if (name.isEmpty) continue;

      items.add(ReceiptLineItem(name: name, price: price));
    }

    return items;
  }
}
