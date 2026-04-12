import 'package:flutter/widgets.dart';

import 'local_image_preview_stub.dart'
    if (dart.library.io) 'local_image_preview_io.dart'
    if (dart.library.html) 'local_image_preview_web.dart';

Widget buildLocalImagePreview(String path, {BoxFit fit = BoxFit.cover}) {
  return createLocalImagePreview(path, fit: fit);
}
