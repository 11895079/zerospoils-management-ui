// Unit tests for service locator and dependency injection
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerospoils/presentation/di/service_locator.dart';
import 'package:zerospoils/data/repositories/hive_item_repository.dart';

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
      expect(repository, isA<HiveItemRepository>());
    });

    test('Telemetry client can enqueue events', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final telemetryClient = container.read(telemetryClientProvider);

      expect(
        () => telemetryClient.enqueue({
          'name': 'test_event',
          'properties': {'test': 'value'},
        }),
        returnsNormally,
      );
    });

    test('Telemetry client tracks helper events into memory sink', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final telemetryClient = container.read(telemetryClientProvider);

      telemetryClient.trackAppInstalled(isFirstInstall: true);
      telemetryClient.trackTabSwitched(tabName: 'inventory');

      expect(telemetryClient.events.length, 2);
      expect(telemetryClient.events.first['name'], equals('app_installed'));
      expect(
        telemetryClient.events.last['properties']['tab_name'],
        equals('inventory'),
      );
    });
  });
}
