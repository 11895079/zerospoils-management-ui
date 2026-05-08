import 'dart:convert';
import 'dart:io';

import 'package:zerospoils/domain/utils/receipt_parser.dart';

Future<void> main() async {
  final input = await stdin.transform(utf8.decoder).join();
  final parser = ReceiptParser();
  final items = parser.parse(input);

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
