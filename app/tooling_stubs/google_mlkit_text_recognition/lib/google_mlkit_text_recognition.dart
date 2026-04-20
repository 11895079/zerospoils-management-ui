import 'dart:typed_data';
import 'dart:ui';

enum TextRecognitionScript { latin }

enum InputImageFormat { bgra8888, nv21 }

enum InputImageRotation {
  rotation0deg,
  rotation90deg,
  rotation180deg,
  rotation270deg,
}

class InputImageRotationValue {
  const InputImageRotationValue._();

  static InputImageRotation? fromRawValue(int rawValue) {
    switch (rawValue) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return null;
    }
  }
}

class InputImageMetadata {
  const InputImageMetadata({
    required this.size,
    required this.rotation,
    required this.format,
    required this.bytesPerRow,
  });

  final Size size;
  final InputImageRotation rotation;
  final InputImageFormat format;
  final int bytesPerRow;
}

class InputImage {
  InputImage._({this.path, this.bytes, this.metadata});

  final String? path;
  final Uint8List? bytes;
  final InputImageMetadata? metadata;

  factory InputImage.fromFilePath(String path) => InputImage._(path: path);

  factory InputImage.fromBytes({
    required Uint8List bytes,
    required InputImageMetadata metadata,
  }) => InputImage._(bytes: bytes, metadata: metadata);
}

class TextElement {
  const TextElement({required this.text, required this.boundingBox});
  final String text;
  final Rect boundingBox;
}

class TextLine {
  const TextLine({
    required this.text,
    required this.boundingBox,
    this.elements = const [],
  });
  final String text;
  final Rect boundingBox;
  final List<TextElement> elements;
}

class TextBlock {
  const TextBlock({
    required this.text,
    required this.boundingBox,
    this.lines = const [],
  });
  final String text;
  final Rect boundingBox;
  final List<TextLine> lines;
}

class RecognizedText {
  const RecognizedText({required this.text, this.blocks = const []});

  final String text;
  final List<TextBlock> blocks;
}

class TextRecognizer {
  TextRecognizer({TextRecognitionScript script = TextRecognitionScript.latin})
    : _script = script;

  final TextRecognitionScript _script;

  Future<RecognizedText> processImage(InputImage inputImage) async {
    // Stub recognizer returns no text so app falls back to manual entry flows.
    final _ = _script;
    return const RecognizedText(text: '', blocks: []);
  }

  Future<void> close() async {}
}
