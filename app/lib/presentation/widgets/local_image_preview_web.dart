import 'package:flutter/widgets.dart';

Widget createLocalImagePreview(String path, {BoxFit fit = BoxFit.cover}) {
  return Image.network(path, fit: fit);
}
