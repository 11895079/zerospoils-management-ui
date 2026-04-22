import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/core/feature_flags/feature_flag_key.dart';
import 'package:zerospoils/core/feature_flags/feature_flags_service.dart';

/// Fake SharedPreferences for testing
class FakeSharedPreferences implements SharedPreferences {
  final Map<String, dynamic> _data = {};

  @override
  bool containsKey(String key) => _data.containsKey(key);

  @override
  dynamic get(String key) => _data[key];

  @override
  bool? getBool(String key) => _data[key] as bool?;

  @override
  double? getDouble(String key) => _data[key] as double?;

  @override
  int? getInt(String key) => _data[key] as int?;

  @override
  String? getString(String key) => _data[key] as String?;

  @override
  List<String>? getStringList(String key) => _data[key] as List<String>?;

  @override
  Set<String> getKeys() => _data.keys.toSet();

  @override
  Future<bool> setBool(String key, bool value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _data.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _data.clear();
    return true;
  }

  @override
  Future<void> reload() async {}

  @override
  Future<bool> commit() async {
    return true;
  }
}

void main() {
  group('FeatureFlagsService', () {
    late FakeSharedPreferences fakePrefs;
    late FeatureFlagsService service;

    setUp(() {
      fakePrefs = FakeSharedPreferences();
      service = FeatureFlagsService(prefs: fakePrefs);
    });

    group('Default values', () {
      test('flags return default values when no override set', () {
        expect(service.isEnabled(FeatureFlagKey.cloudSync), false);
        expect(service.isEnabled(FeatureFlagKey.cloudAnalyticsExport), false);
        expect(service.isEnabled(FeatureFlagKey.receiptBatchCapture), true);
        expect(service.isEnabled(FeatureFlagKey.receiptOcr), true);
        expect(service.isEnabled(FeatureFlagKey.batchPhotoCapture), false);
        expect(service.isEnabled(FeatureFlagKey.freshItemCv), true);
        expect(service.isEnabled(FeatureFlagKey.householdSync), false);
        expect(service.isEnabled(FeatureFlagKey.iotHooks), false);
        expect(service.isEnabled(FeatureFlagKey.expiryDateOcr), true);
      });
    });

    group('Local override precedence', () {
      test('local override takes precedence over default', () async {
        await fakePrefs.setBool('feature_flag_override_receipt_ocr', true);

        expect(service.isEnabled(FeatureFlagKey.receiptOcr), true);
      });

      test('local override false takes precedence over default', () async {
        await fakePrefs.setBool('feature_flag_override_cloud_sync', false);

        expect(service.isEnabled(FeatureFlagKey.cloudSync), false);
      });
    });

    group('Local override persistence', () {
      test('setLocalOverride stores value in SharedPreferences', () async {
        final result = await service.setLocalOverride(
          FeatureFlagKey.receiptOcr,
          true,
        );

        expect(result, true);
        expect(fakePrefs.getBool('feature_flag_override_receipt_ocr'), true);
      });

      test(
        'removeLocalOverride clears override from SharedPreferences',
        () async {
          await fakePrefs.setBool('feature_flag_override_receipt_ocr', true);

          final result = await service.removeLocalOverride(
            FeatureFlagKey.receiptOcr,
          );

          expect(result, true);
          expect(
            fakePrefs.containsKey('feature_flag_override_receipt_ocr'),
            false,
          );
        },
      );
    });

    group('hasLocalOverride', () {
      test('returns true when override is set', () async {
        await fakePrefs.setBool('feature_flag_override_cloud_sync', true);

        expect(service.hasLocalOverride(FeatureFlagKey.cloudSync), true);
      });

      test('returns false when no override is set', () {
        expect(service.hasLocalOverride(FeatureFlagKey.cloudSync), false);
      });
    });

    group('Reset overrides', () {
      test('resetAllOverrides clears all override keys', () async {
        await fakePrefs.setBool('feature_flag_override_cloud_sync', true);
        await fakePrefs.setBool('feature_flag_override_receipt_ocr', true);
        await fakePrefs.setString('other_key', 'value');

        final result = await service.resetAllOverrides();

        expect(result, true);
        expect(
          fakePrefs.containsKey('feature_flag_override_cloud_sync'),
          false,
        );
        expect(
          fakePrefs.containsKey('feature_flag_override_receipt_ocr'),
          false,
        );
        expect(fakePrefs.containsKey('other_key'), true);
      });
    });

    group('getAllFlags', () {
      test('returns all flags with their current values', () {
        final flags = service.getAllFlags();

        expect(flags.keys.length, 9);
        expect(flags[FeatureFlagKey.cloudSync], false);
        expect(flags[FeatureFlagKey.receiptBatchCapture], true);
        expect(flags[FeatureFlagKey.receiptOcr], true);
        expect(flags[FeatureFlagKey.freshItemCv], true);
        expect(flags[FeatureFlagKey.expiryDateOcr], true);
      });

      test('getAllFlags respects overrides', () async {
        await fakePrefs.setBool('feature_flag_override_receipt_ocr', true);

        final flags = service.getAllFlags();

        expect(flags[FeatureFlagKey.receiptOcr], true);
        expect(flags[FeatureFlagKey.cloudSync], false);
      });
    });

    group('getAllFlagsWithStatus', () {
      test('includes override status for each flag', () async {
        await fakePrefs.setBool('feature_flag_override_receipt_ocr', true);

        final status = service.getAllFlagsWithStatus();

        expect(status[FeatureFlagKey.receiptOcr]?.isOverridden, true);
        expect(status[FeatureFlagKey.receiptOcr]?.value, true);
        expect(status[FeatureFlagKey.cloudSync]?.isOverridden, false);
        expect(status[FeatureFlagKey.cloudSync]?.value, false);
      });
    });

    group('Remote override support', () {
      test(
        'remote override takes precedence over default but not local',
        () async {
          final serviceWithRemote = FeatureFlagsService(
            prefs: fakePrefs,
            getRemoteOverrides: () => {'receipt_ocr': true},
          );

          expect(serviceWithRemote.isEnabled(FeatureFlagKey.receiptOcr), true);
        },
      );

      test('local override takes precedence over remote override', () async {
        await fakePrefs.setBool('feature_flag_override_receipt_ocr', false);

        final serviceWithRemote = FeatureFlagsService(
          prefs: fakePrefs,
          getRemoteOverrides: () => {'receipt_ocr': true},
        );

        expect(serviceWithRemote.isEnabled(FeatureFlagKey.receiptOcr), false);
      });
    });
  });
}
