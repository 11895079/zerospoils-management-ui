class InputImage {
  InputImage._(this.path);

  final String path;

  factory InputImage.fromFilePath(String path) => InputImage._(path);
}

class ImageLabel {
  const ImageLabel({required this.label, required this.confidence});

  final String label;
  final double confidence;
}

class ImageLabelerOptions {
  const ImageLabelerOptions({this.confidenceThreshold = 0.0});

  final double confidenceThreshold;
}

class ImageLabeler {
  ImageLabeler({required ImageLabelerOptions options}) : _options = options;

  final ImageLabelerOptions _options;

  Future<List<ImageLabel>> processImage(InputImage inputImage) async {
    // Stub labeler returns no labels so app falls back to manual categorization.
    final _ = (_options, inputImage);
    return const <ImageLabel>[];
  }

  Future<void> close() async {}
}
