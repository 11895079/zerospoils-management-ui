import 'package:flutter_test/flutter_test.dart';

/// Pumps the tester until a telemetry event with [eventName] appears in
/// [events], or throws after ~1s if it never arrives. Use for assertions on
/// events emitted by code that fires after a [Future.microtask] / unawaited
/// future (e.g. ZestoService mascot triggers).
Future<Map<String, dynamic>> waitForTelemetryEvent(
  List<Map<String, dynamic>> events,
  String eventName,
  WidgetTester tester,
) async {
  for (var i = 0; i < 20; i++) {
    final match = events.where((event) => event['name'] == eventName);
    if (match.isNotEmpty) {
      return match.last;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  throw StateError('Telemetry event not found: $eventName');
}
