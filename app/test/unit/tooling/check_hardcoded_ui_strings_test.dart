import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/tooling/check_hardcoded_ui_strings.dart';

void main() {
  group('findHardcodedUiStringViolationsFromDiff', () {
    test('flags newly added hardcoded Text and InputDecoration strings', () {
      const diff = '''
diff --git a/lib/presentation/screens/sample_screen.dart b/lib/presentation/screens/sample_screen.dart
index 1111111..2222222 100644
--- a/lib/presentation/screens/sample_screen.dart
+++ b/lib/presentation/screens/sample_screen.dart
@@ -10,0 +11,4 @@
+      title: const Text('Enable Camera'),
+      decoration: const InputDecoration(labelText: 'Item name'),
+      child: const Text('Continue'),
+      tooltip: 'Open settings',
''';

      final violations = findHardcodedUiStringViolationsFromDiff(
        diff,
        'lib/presentation/screens/sample_screen.dart',
      );

      expect(violations, hasLength(4));
      expect(violations.first.lineNumber, 11);
      expect(
        violations.first.lineText,
        "      title: const Text('Enable Camera'),",
      );
      expect(
        violations.map((violation) => violation.lineText),
        contains(
          "      decoration: const InputDecoration(labelText: 'Item name'),",
        ),
      );
    });

    test('ignores localized string references', () {
      const diff = '''
diff --git a/lib/presentation/screens/sample_screen.dart b/lib/presentation/screens/sample_screen.dart
index 1111111..2222222 100644
--- a/lib/presentation/screens/sample_screen.dart
+++ b/lib/presentation/screens/sample_screen.dart
@@ -10,0 +11,3 @@
+      title: Text(l10n.enableCamera),
+      decoration: InputDecoration(labelText: l10n.itemNameLabel),
+      child: Text(context.l10n.continueLabel),
''';

      final violations = findHardcodedUiStringViolationsFromDiff(
        diff,
        'lib/presentation/screens/sample_screen.dart',
      );

      expect(violations, isEmpty);
    });
  });
}
