import 'dart:io';

import 'package:zerospoils/tooling/check_hardcoded_ui_strings.dart';

Future<void> main(List<String> args) async {
  final baseRef = args.isNotEmpty ? args.first : 'origin/main';
  final repoRoot = File.fromUri(Platform.script).parent.parent.path;

  final changedFiles = await _gitLines([
    'diff',
    '--name-only',
    '--diff-filter=AM',
    '$baseRef...HEAD',
    '--',
    'lib/presentation',
  ], workingDirectory: repoRoot);

  final violations = <HardcodedUiStringViolation>[];
  for (final filePath in changedFiles.where((path) => path.endsWith('.dart'))) {
    final diff = await _gitOutput([
      'diff',
      '--unified=0',
      '$baseRef...HEAD',
      '--',
      filePath,
    ], workingDirectory: repoRoot);
    violations.addAll(findHardcodedUiStringViolationsFromDiff(diff, filePath));
  }

  if (violations.isEmpty) {
    stdout.writeln(
      'No new hardcoded UI strings found in changed presentation files.',
    );
    return;
  }

  stderr.writeln(
    'Hardcoded UI strings detected in changed presentation files:',
  );
  for (final violation in violations) {
    stderr.writeln(
      '  ${violation.filePath}:${violation.lineNumber}: ${violation.lineText}',
    );
  }
  stderr.writeln(
    '\nMove these strings into app/l10n ARB files and use AppLocalizations instead.',
  );
  exitCode = 1;
}

Future<List<String>> _gitLines(
  List<String> arguments, {
  required String workingDirectory,
}) async {
  final output = await _gitOutput(
    arguments,
    workingDirectory: workingDirectory,
  );
  return output
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
}

Future<String> _gitOutput(
  List<String> arguments, {
  required String workingDirectory,
}) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: workingDirectory,
    runInShell: true,
  );

  if (result.exitCode != 0) {
    throw ProcessException(
      'git',
      arguments,
      result.stderr.toString(),
      result.exitCode,
    );
  }

  return result.stdout.toString();
}
