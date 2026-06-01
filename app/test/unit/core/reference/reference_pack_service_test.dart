import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/core/reference/reference_pack_fetchers.dart';
import 'package:zerospoils/core/reference/reference_pack_manifest.dart';
import 'package:zerospoils/core/reference/reference_pack_service.dart';

class _FakeManifestUrlProvider implements ReferencePackManifestUrlProvider {
  _FakeManifestUrlProvider(this.url);

  final Uri? url;

  @override
  Future<Uri?> getManifestUrl() async => url;
}

class _MapDownloader implements ReferencePackDownloader {
  _MapDownloader(this.payloadsByUrl);

  final Map<String, String> payloadsByUrl;

  @override
  Future<String> downloadJson(Uri url) async {
    final payload = payloadsByUrl[url.toString()];
    if (payload == null) {
      throw Exception('missing payload for ${url.toString()}');
    }
    return payload;
  }
}

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

    test('syncs barcode pack from manifest URL via downloader', () async {
      const packUrl =
          'https://firebase.storage.googleapis.com/packs/barcode-ca-v9.json';
      const manifestUrl =
          'https://firebase.storage.googleapis.com/manifests/reference-manifest.json';

      const packJson =
          '{"schema_version":1,"records":[{"barcode":"055000132152","product_name":"Firebase Pack Coffee","category_hint":"pantry"}]}';
      final checksum = sha256.convert(utf8.encode(packJson)).toString();

      final manifestJson =
          '''
{
  "schema_version": 1,
  "packs": [
    {
      "type": "barcode_catalog",
      "region": "ca",
      "version": "v9",
      "checksum": "$checksum",
      "minimum_app_version": "1.0.0",
      "download_url": "$packUrl"
    }
  ]
}
''';

      final service = ReferencePackService(
        preferences: prefs,
        appVersionProvider: () async => '1.0.0',
      );

      final result = await service.syncBarcodeCatalogPack(
        manifestUrlProvider: _FakeManifestUrlProvider(Uri.parse(manifestUrl)),
        downloader: _MapDownloader({
          manifestUrl: manifestJson,
          packUrl: packJson,
        }),
        region: 'ca',
      );

      expect(result.success, isTrue);

      final status = await service.barcodeCatalogStatus();
      expect(status.version, 'v9');
      expect(status.recordCount, 1);
    });

    test('accepts barcode packs with metadata.schema_version format', () async {
      const packJson =
          '{"metadata":{"schema_version":1,"region":"ca"},"records":[{"barcode":"055000132152","product_name":"Metadata Coffee","category_hint":"pantry"}]}';
      final checksum = sha256.convert(utf8.encode(packJson)).toString();

      final service = ReferencePackService(
        preferences: prefs,
        appVersionProvider: () async => '1.0.0',
      );

      final descriptor = ReferencePackDescriptor(
        type: ReferencePackType.barcodeCatalog,
        region: 'ca',
        version: 'v10',
        checksum: checksum,
        minimumAppVersion: '1.0.0',
        downloadUrl: Uri.parse('https://example.com/barcode-ca-v10.json'),
      );

      final result = await service.activateBarcodeCatalogPack(
        descriptor: descriptor,
        packJson: packJson,
      );

      expect(result.success, isTrue);
      final status = await service.barcodeCatalogStatus();
      expect(status.version, 'v10');
      expect(status.recordCount, 1);
    });

    test('syncs locale-scoped categories and locations packs', () async {
      const manifestUrl =
          'https://firebase.storage.googleapis.com/manifests/reference-manifest.json';
      const categoriesUrl =
          'https://firebase.storage.googleapis.com/packs/categories-ca-fr.json';
      const locationsUrl =
          'https://firebase.storage.googleapis.com/packs/locations-ca-fr.json';

      const categoriesPack =
          '{"metadata":{"schema_version":1,"type":"categories","region":"ca","locale":"fr-CA"},"records":[{"id":"produce","label":"Fruits et legumes","app_category":"produce","synonyms":["fruit"]}] }';
      const locationsPack =
          '{"metadata":{"schema_version":1,"type":"locations","region":"ca","locale":"fr-CA"},"records":[{"id":"fridge","label":"Frigo","app_location":"fridge","synonyms":["refrigerateur"]}] }';

      final categoriesChecksum = sha256
          .convert(utf8.encode(categoriesPack))
          .toString();
      final locationsChecksum = sha256
          .convert(utf8.encode(locationsPack))
          .toString();

      final manifestJson =
          '''
{
  "schema_version": 1,
  "packs": [
    {
      "type": "categories",
      "region": "ca",
      "locale": "fr-CA",
      "version": "1.0.0",
      "checksum": "$categoriesChecksum",
      "minimum_app_version": "1.0.0",
      "download_url": "$categoriesUrl"
    },
    {
      "type": "locations",
      "region": "ca",
      "locale": "fr-CA",
      "version": "1.0.0",
      "checksum": "$locationsChecksum",
      "minimum_app_version": "1.0.0",
      "download_url": "$locationsUrl"
    }
  ]
}
''';

      final service = ReferencePackService(
        preferences: prefs,
        appVersionProvider: () async => '1.0.0',
      );

      final downloader = _MapDownloader({
        manifestUrl: manifestJson,
        categoriesUrl: categoriesPack,
        locationsUrl: locationsPack,
      });
      final manifestProvider = _FakeManifestUrlProvider(Uri.parse(manifestUrl));

      final categoriesResult = await service.syncCategoriesPack(
        manifestUrlProvider: manifestProvider,
        downloader: downloader,
        region: 'ca',
        locale: 'fr-CA',
      );
      final locationsResult = await service.syncLocationsPack(
        manifestUrlProvider: manifestProvider,
        downloader: downloader,
        region: 'ca',
        locale: 'fr-CA',
      );

      expect(categoriesResult.success, isTrue);
      expect(locationsResult.success, isTrue);

      final categoryRecords = ReferencePackService.activeCategoryRecords(prefs);
      final locationRecords = ReferencePackService.activeLocationRecords(prefs);
      expect(categoryRecords, hasLength(1));
      expect(categoryRecords.single.label, 'Fruits et legumes');
      expect(locationRecords, hasLength(1));
      expect(locationRecords.single.label, 'Frigo');
    });

    test('fails sync when manifest URL is unset', () async {
      final service = ReferencePackService(
        preferences: prefs,
        appVersionProvider: () async => '1.0.0',
      );

      final result = await service.syncBarcodeCatalogPack(
        manifestUrlProvider: _FakeManifestUrlProvider(null),
        downloader: _MapDownloader(const {}),
      );

      expect(result.success, isFalse);
      expect(result.failureReason, 'manifest_url_unset');
    });

    test('fails sync when no matching pack exists for region', () async {
      const manifestUrl =
          'https://firebase.storage.googleapis.com/manifests/reference-manifest.json';

      const manifestJson = '''
{
  "schema_version": 1,
  "packs": [
    {
      "type": "barcode_catalog",
      "region": "us",
      "version": "v1",
      "checksum": "abc",
      "minimum_app_version": "1.0.0",
      "download_url": "https://example.com/us-pack.json"
    }
  ]
}
''';

      final service = ReferencePackService(
        preferences: prefs,
        appVersionProvider: () async => '1.0.0',
      );

      final result = await service.syncBarcodeCatalogPack(
        manifestUrlProvider: _FakeManifestUrlProvider(Uri.parse(manifestUrl)),
        downloader: _MapDownloader({manifestUrl: manifestJson}),
        region: 'ca',
      );

      expect(result.success, isFalse);
      expect(result.failureReason, 'pack_not_found_for_region');
    });
  });
}
