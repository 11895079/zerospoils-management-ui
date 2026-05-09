import 'dart:convert';
import 'dart:io';

import 'package:zerospoils/domain/models/receipt_line_item.dart';
import 'package:zerospoils/domain/utils/receipt_parser.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln('Usage: dart run tool/receipt_parser_cli.dart [--trace]');
    stdout.writeln('Reads OCR text or JSON payload from stdin and emits JSON.');
    return;
  }

  final trace = args.contains('--trace');
  final input = await stdin.transform(utf8.decoder).join();
  final parser = ReceiptParser();
  final trimmed = input.trimLeft();

  final result = trimmed.startsWith('{')
      ? _parseStructuredInput(parser, trimmed)
      : parser.parseDetailed(input);
  final items = result.items;

  final payload = items
      .map(
        (item) => {
          'name': item.name,
          'price': item.price,
        },
      )
      .toList(growable: false);

  final output = <String, Object?>{'items': payload};
  if (trace) {
    output['trace'] = result.rows
        .map(
          (row) => {
            'text': row.text,
            'photo_index': row.photoIndex,
            'classification': row.classification.name,
            if (row.extractedName != null) 'extracted_name': row.extractedName,
            if (row.extractedPrice != null)
              'extracted_price': row.extractedPrice,
            if (row.box != null) 'box': _serializeBox(row.box!),
          },
        )
        .toList(growable: false);
  }

  stdout.writeln(jsonEncode(output));
}

ReceiptParseResult _parseStructuredInput(ReceiptParser parser, String input) {
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

  return parser.parseDetailedOcrLines(lines);
}

Map<String, double> _serializeBox(ReceiptOcrBox box) {
  return {
    'left': box.left,
    'top': box.top,
    'right': box.right,
    'bottom': box.bottom,
  };
}
