import 'dart:convert';

class HardcodedUiStringViolation {
  HardcodedUiStringViolation({
    required this.filePath,
    required this.lineNumber,
    required this.lineText,
  });

  final String filePath;
  final int lineNumber;
  final String lineText;

  @override
  String toString() => '$filePath:$lineNumber: $lineText';
}

final List<RegExp> _hardcodedUiStringPatterns = [
  RegExp(r'''\bText\(\s*['"]'''),
  RegExp(r'''\bTextSpan\([^\)]*text:\s*['"]'''),
  RegExp(
    r'''\b(?:labelText|hintText|helperText|errorText|prefixText|suffixText|counterText|message|tooltip|barrierLabel|semanticLabel|label)\s*:\s*['"]''',
  ),
];

List<HardcodedUiStringViolation> findHardcodedUiStringViolationsFromDiff(
  String diff,
  String filePath,
) {
  final violations = <HardcodedUiStringViolation>[];
  final lines = const LineSplitter().convert(diff);
  int? currentLineNumber;

  for (final line in lines) {
    if (line.startsWith('@@ ')) {
      currentLineNumber = _parseNewFileLineNumber(line);
      continue;
    }

    if (line.startsWith('+++ ') || line.startsWith('--- ')) {
      continue;
    }

    if (line.startsWith('+')) {
      if (currentLineNumber == null) {
        continue;
      }

      final content = line.substring(1);
      if (_looksLikeHardcodedUiString(content)) {
        violations.add(
          HardcodedUiStringViolation(
            filePath: filePath,
            lineNumber: currentLineNumber,
            lineText: content,
          ),
        );
      }
      currentLineNumber++;
      continue;
    }

    if (line.startsWith('-')) {
      continue;
    }

    if (currentLineNumber != null) {
      currentLineNumber++;
    }
  }

  return violations;
}

bool _looksLikeHardcodedUiString(String line) {
  return _hardcodedUiStringPatterns.any((pattern) => pattern.hasMatch(line));
}

int? _parseNewFileLineNumber(String hunkHeader) {
  final match = RegExp(r'\+(\d+)(?:,\d+)?').firstMatch(hunkHeader);
  if (match == null) {
    return null;
  }

  return int.parse(match.group(1)!);
}
