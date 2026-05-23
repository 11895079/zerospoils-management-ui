import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/domain/models/zesto_model.dart';
import 'package:zerospoils/domain/repositories/zesto_service.dart';

void main() {
  group('ZestoService (issue 350)', () {
    late DateTime now;
    late List<Map<String, Object?>> telemetry;

    ZestoService buildService() {
      return ZestoService(
        getSettings: () => const MascotSettings(
          enabled: true,
          frequency: MascotFrequency.always,
        ),
        getStorageTips: () => const {
          'general': ['Tip A', 'Tip B'],
          'produce': ['Produce tip'],
        },
        now: () => now,
        random: Random(1),
        displayDuration: Duration.zero,
        telemetryLogger: (name, properties) {
          telemetry.add({'name': name, ...properties});
        },
      );
    }

    setUp(() {
      now = DateTime(2026, 5, 22, 12, 0, 0);
      telemetry = [];
      SharedPreferences.setMockInitialValues({});
    });

    test('anti-spam prevents second mascot event within 5 seconds', () async {
      final service = buildService();

      await service.showMascot(MascotMessageType.badgeUnlocked);
      await service.showMascot(MascotMessageType.badgeUnlocked);

      final shownEvents = telemetry
          .where((event) => event['name'] == 'mascot_shown')
          .toList();
      expect(shownEvents, hasLength(1));
    });

    test('message history avoids repeating recent messages', () async {
      final service = buildService();

      for (var i = 0; i < 4; i++) {
        now = now.add(const Duration(seconds: 6));
        await service.showMascot(MascotMessageType.consumed);
      }

      final shownMessages = telemetry
          .where((event) => event['name'] == 'mascot_shown')
          .map((event) => event['message'] as String)
          .toList();

      expect(shownMessages.length, 4);
      expect(shownMessages.toSet().length, 4);
    });

    test('first item trigger only fires for truly first item', () async {
      final service = buildService();

      await service.onItemAdded(inventoryCountBeforeAdd: 0);
      now = now.add(const Duration(seconds: 6));
      await service.onItemAdded(inventoryCountBeforeAdd: 1);

      final shownTypes = telemetry
          .where((event) => event['name'] == 'mascot_shown')
          .map((event) => event['messageType'] as String)
          .toList();

      expect(shownTypes, ['firstItem']);
    });

    test('consumed trigger selects quickSave when expiry is under 24h', () async {
      final service = buildService();

      await service.onItemConsumed(
        expiryDate: now.add(const Duration(hours: 23)),
      );
      now = now.add(const Duration(seconds: 6));
      await service.onItemConsumed(
        expiryDate: now.add(const Duration(hours: 48)),
      );

      final shownTypes = telemetry
          .where((event) => event['name'] == 'mascot_shown')
          .map((event) => event['messageType'] as String)
          .toList();

      expect(shownTypes, ['quickSave', 'consumed']);
    });

    test('expiry alert trigger requires at least 3 expiring items', () async {
      final service = buildService();

      await service.onInventoryScannedForExpiry(expiringWithin24hCount: 2);
      now = now.add(const Duration(seconds: 6));
      await service.onInventoryScannedForExpiry(expiringWithin24hCount: 3);

      final shownTypes = telemetry
          .where((event) => event['name'] == 'mascot_shown')
          .map((event) => event['messageType'] as String)
          .toList();

      expect(shownTypes, ['expiryAlert']);
    });

    test('anti-spam survives service recreation', () async {
      final firstService = buildService();

      await firstService.showMascot(MascotMessageType.badgeUnlocked);

      final secondService = buildService();
      await secondService.showMascot(MascotMessageType.badgeUnlocked);

      final shownEvents = telemetry
          .where((event) => event['name'] == 'mascot_shown')
          .toList();

      expect(shownEvents, hasLength(1));
    });

    test('daily welcome is shown only once per day across restarts', () async {
      final firstService = buildService();

      await firstService.onAppOpened();

      final secondService = buildService();
      await secondService.onAppOpened();

      final shownTypes = telemetry
          .where((event) => event['name'] == 'mascot_shown')
          .map((event) => event['messageType'] as String)
          .toList();

      expect(shownTypes, ['dailyWelcome']);
    });
  });
}
