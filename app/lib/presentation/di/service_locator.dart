// Service locator and dependency injection setup using Riverpod
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity service provider
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((result) {
    return result.contains(ConnectivityResult.none) == false;
  });
});

/// Example: Telemetry client provider (stub for now)
final telemetryClientProvider = Provider((ref) {
  return TelemetryClient();
});

/// Example: Repository provider
final itemRepositoryProvider = Provider((ref) {
  return ItemRepository();
});

// Stub implementations for M1/090

/// Basic telemetry client for local event queuing
class TelemetryClient {
  /// Enqueue an event locally (no upload yet)
  void enqueue(Map<String, dynamic> event) {
    // TODO: M1/090 - Implement local queue with Hive
    // - Apply redaction rules from telemetry/policies/redaction.yaml
    // - Apply sampling from telemetry/policies/sampling.yaml
    // - Store in Hive queue for later batch upload
    // ignore: avoid_print
    print('Telemetry event enqueued: ${event['name']}');
  }

  /// Enqueue app installed event (called on first launch)
  void trackAppInstalled({required bool isFirstInstall}) {
    enqueue({
      'name': 'app_installed',
      'properties': {'is_first_install': isFirstInstall},
    });
  }

  /// Enqueue tab switched event
  void trackTabSwitched({required String tabName}) {
    enqueue({
      'name': 'tab_switched',
      'properties': {'tab_name': tabName},
    });
  }
}

/// Example repository (stub)
class ItemRepository {
  /// Get all items from local Hive database
  Future<List<Item>> getAllItems() async {
    // TODO: M1/090 - Implement with Hive
    return [];
  }

  /// Add item to local database
  Future<void> addItem(Item item) async {
    // TODO: M1/090 - Implement with Hive
  }
}

/// Item model (stub)
class Item {
  final String id;
  final String name;
  final String category;

  Item({required this.id, required this.name, required this.category});
}
