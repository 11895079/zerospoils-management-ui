import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/core/reference/reference_pack_manifest.dart';
import 'package:zerospoils/core/reference/reference_pack_service.dart';

void main() {
  group('ReferencePackService', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('activates valid barcode pack and exposes status', () async {
      const packJson =
          '{"schema_version":1,"records":[{"barcode":"055000132152","product_name":"Downloaded Coffee","category_hint":"pantry"}]}';
      final checksum = sha256.convert(utf8.encode(packJson)).toString();

      final service = ReferencePackService(
        preferences: prefs,
        appVersionProvider: () async => '1.0.0',
      );

      final descriptor = ReferencePackDescriptor(
        type: ReferencePackType.barcodeCatalog,
        region: 'ca',
        version: 'v3',
        checksum: checksum,
        minimumAppVersion: '1.0.0',
        downloadUrl: Uri.parse('https://example.com/barcode-ca-v3.json'),
      );

      final result = await service.activateBarcodeCatalogPack(
        descriptor: descriptor,
        packJson: packJson,
      );

      expect(result.success, isTrue);

      final status = await service.barcodeCatalogStatus();
      expect(status.version, 'v3');
      expect(status.region, 'ca');
      expect(status.recordCount, 1);
    });

    test('rejects pack when checksum mismatches', () async {
      const packJson =
          '{"schema_version":1,"records":[{"barcode":"055000132152","product_name":"Downloaded Coffee"}]}';

      final service = ReferencePackService(
        preferences: prefs,
        appVersionProvider: () async => '1.0.0',
      );

      final descriptor = ReferencePackDescriptor(
        type: ReferencePackType.barcodeCatalog,
        region: 'ca',
        version: 'v3',
        checksum: 'badchecksum',
        minimumAppVersion: '1.0.0',
        downloadUrl: Uri.parse('https://example.com/barcode-ca-v3.json'),
      );

      final result = await service.activateBarcodeCatalogPack(
        descriptor: descriptor,
        packJson: packJson,
      );

      expect(result.success, isFalse);
      expect(result.failureReason, 'checksum_mismatch');
    });

    test('rejects pack when min app version is not met', () async {
      const packJson =
          '{"schema_version":1,"records":[{"barcode":"055000132152","product_name":"Downloaded Coffee"}]}';
      final checksum = sha256.convert(utf8.encode(packJson)).toString();

      final service = ReferencePackService(
        preferences: prefs,
        appVersionProvider: () async => '1.0.0',
      );

      final descriptor = ReferencePackDescriptor(
        type: ReferencePackType.barcodeCatalog,
        region: 'ca',
        version: 'v3',
        checksum: checksum,
        minimumAppVersion: '1.1.0',
        downloadUrl: Uri.parse('https://example.com/barcode-ca-v3.json'),
      );

      final result = await service.activateBarcodeCatalogPack(
        descriptor: descriptor,
        packJson: packJson,
      );

      expect(result.success, isFalse);
      expect(result.failureReason, 'minimum_app_version_not_met');
    });

    test('preserves previous active pack after failed activation', () async {
      const firstPack =
          '{"schema_version":1,"records":[{"barcode":"055000132152","product_name":"First Pack Coffee"}]}';
      final firstChecksum = sha256.convert(utf8.encode(firstPack)).toString();

      final service = ReferencePackService(
        preferences: prefs,
        appVersionProvider: () async => '1.0.0',
      );

      final firstDescriptor = ReferencePackDescriptor(
        type: ReferencePackType.barcodeCatalog,
        region: 'ca',
        version: 'v1',
        checksum: firstChecksum,
        minimumAppVersion: '1.0.0',
        downloadUrl: Uri.parse('https://example.com/barcode-ca-v1.json'),
      );

      final firstResult = await service.activateBarcodeCatalogPack(
        descriptor: firstDescriptor,
        packJson: firstPack,
      );
      expect(firstResult.success, isTrue);

      const badPack =
          '{"schema_version":1,"records":[{"barcode":"055000132152","product_name":"Bad Pack Coffee"}]}';

      final badDescriptor = ReferencePackDescriptor(
        type: ReferencePackType.barcodeCatalog,
        region: 'ca',
        version: 'v2',
        checksum: 'mismatch',
        minimumAppVersion: '1.0.0',
        downloadUrl: Uri.parse('https://example.com/barcode-ca-v2.json'),
      );

      final badResult = await service.activateBarcodeCatalogPack(
        descriptor: badDescriptor,
        packJson: badPack,
      );

      expect(badResult.success, isFalse);

      final status = await service.barcodeCatalogStatus();
      expect(status.version, 'v1');
      expect(status.recordCount, 1);
    });
  });
}
