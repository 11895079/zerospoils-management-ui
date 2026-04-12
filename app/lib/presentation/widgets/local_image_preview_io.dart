import 'dart:io';

import 'package:flutter/widgets.dart';

Widget createLocalImagePreview(String path, {BoxFit fit = BoxFit.cover}) {
  return Image.file(File(path), fit: fit);
}
