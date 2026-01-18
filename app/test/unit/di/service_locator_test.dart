// Unit tests for service locator and dependency injection
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerospoils/presentation/di/service_locator.dart';

void main() {
  group('Service Locator Tests', () {
    test('Telemetry client provider resolves successfully', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Verify telemetry client provider resolves
      final telemetryClient = container.read(telemetryClientProvider);
      expect(telemetryClient, isNotNull);
      expect(telemetryClient, isA<TelemetryClient>());
    });

    test('Item repository provider resolves successfully', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Verify repository provider resolves
      final repository = container.read(itemRepositoryProvider);
      expect(repository, isNotNull);
      expect(repository, isA<ItemRepository>());
    });

    test('Telemetry client can enqueue events', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final telemetryClient = container.read(telemetryClientProvider);

      // Verify enqueue doesn't throw (stub implementation prints to console)
      expect(
        () => telemetryClient.enqueue({
          'name': 'test_event',
          'properties': {'test': 'value'},
        }),
        returnsNormally,
      );
    });
  });
}
