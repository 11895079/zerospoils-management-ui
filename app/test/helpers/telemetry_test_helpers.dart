import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/domain/models/zesto_model.dart';
import 'package:zerospoils/domain/repositories/zesto_service.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/presentation/di/service_locator.dart' as sl;

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

/// Returns a [Override] for [zestoServiceProvider] suitable for widget tests.
///
/// The service is configured with:
/// - A far-future clock (`DateTime(9999)`) so the anti-spam gap always passes,
///   regardless of any [SharedPreferences] state left by other tests.
/// - `displayDuration: Duration.zero` so the auto-dismiss timer fires on the
///   very next pump.
/// - A telemetry logger that pipes events into whatever
///   [sl.telemetryClientProvider] is overridden to in the same [ProviderScope].
///
/// Usage:
/// ```dart
/// ProviderScope(
///   overrides: [
///     itemRepositoryProvider.overrideWithValue(mockRepo),
///     sl.telemetryClientProvider.overrideWithValue(mockTelemetry),
///     zestoTestOverride(),
///   ],
///   child: ...,
/// )
/// ```
Override zestoTestOverride() {
  return zestoServiceProvider.overrideWith((ref) {
    final telemetry = ref.watch(sl.telemetryClientProvider);
    final svc = ZestoService(
      getSettings: () => const MascotSettings(
        enabled: true,
        frequency: MascotFrequency.always,
      ),
      displayDuration: Duration.zero,
      // skipPersistence prevents anti-spam timestamps written by one test from
      // leaking into a concurrently-running test via SharedPreferences.
      skipPersistence: true,
      telemetryLogger: (eventName, props) {
        telemetry.enqueue({'name': eventName, 'properties': props});
      },
    );
    ref.onDispose(svc.dispose);
    return svc;
  });
}
