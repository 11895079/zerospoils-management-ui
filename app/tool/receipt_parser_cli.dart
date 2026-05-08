import 'dart:convert';
import 'dart:io';

import 'package:zerospoils/domain/models/receipt_line_item.dart';
import 'package:zerospoils/domain/utils/receipt_parser.dart';

Future<void> main() async {
  final input = await stdin.transform(utf8.decoder).join();
  final parser = ReceiptParser();
  final trimmed = input.trimLeft();

  final items = trimmed.startsWith('{')
      ? _parseStructuredInput(parser, trimmed)
      : parser.parse(input);

  final payload = items
      .map(
        (item) => {
          'name': item.name,
          'price': item.price,
        },
      )
      .toList(growable: false);

  stdout.writeln(jsonEncode({'items': payload}));
}

List<ReceiptLineItem> _parseStructuredInput(ReceiptParser parser, String input) {
  final payload = jsonDecode(input) as Map<String, dynamic>;
  final lines = (payload['lines'] as List<dynamic>? ?? const [])
      .map((entry) => entry as Map<String, dynamic>)
      .map(
        (entry) => ReceiptOcrLine(
          text: entry['text'] as String? ?? '',
          box: ReceiptOcrBox(
            left: (entry['left'] as num?)?.toDouble() ?? 0,
            top: (entry['top'] as num?)?.toDouble() ?? 0,
            right: (entry['right'] as num?)?.toDouble() ?? 0,
            bottom: (entry['bottom'] as num?)?.toDouble() ?? 0,
          ),
        ),
      )
      .toList(growable: false);

  return parser.parseOcrLines(lines);
}
