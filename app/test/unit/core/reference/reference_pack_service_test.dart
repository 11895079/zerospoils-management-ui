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

    test('upgrades an existing active barcode pack to a newer version', () async {
      const initialPack =
          '{"schema_version":1,"records":[{"barcode":"055000132152","product_name":"Legacy Coffee","category_hint":"pantry"}]}';
      final initialChecksum = sha256
          .convert(utf8.encode(initialPack))
          .toString();

      const upgradedPackUrl =
          'https://firebase.storage.googleapis.com/packs/barcode-ca-v10.json';
      const manifestUrl =
          'https://firebase.storage.googleapis.com/manifests/reference-manifest.json';
      const upgradedPack =
          '{"schema_version":1,"records":[{"barcode":"055000132152","product_name":"Updated Coffee","category_hint":"pantry"},{"barcode":"055000999999","product_name":"Updated Tea","category_hint":"beverages"}]}';
      final upgradedChecksum = sha256
          .convert(utf8.encode(upgradedPack))
          .toString();

      final manifestJson =
          '''
{
  "schema_version": 1,
  "packs": [
    {
      "type": "barcode_catalog",
      "region": "ca",
      "version": "v10",
      "checksum": "$upgradedChecksum",
      "minimum_app_version": "1.0.0",
      "download_url": "$upgradedPackUrl"
    }
  ]
}
''';

      final service = ReferencePackService(
        preferences: prefs,
        appVersionProvider: () async => '1.0.0',
      );

      final initialDescriptor = ReferencePackDescriptor(
        type: ReferencePackType.barcodeCatalog,
        region: 'ca',
        version: 'v1',
        checksum: initialChecksum,
        minimumAppVersion: '1.0.0',
        downloadUrl: Uri.parse('https://example.com/barcode-ca-v1.json'),
      );

      final initialActivation = await service.activateBarcodeCatalogPack(
        descriptor: initialDescriptor,
        packJson: initialPack,
      );
      expect(initialActivation.success, isTrue);

      final upgradeResult = await service.syncBarcodeCatalogPack(
        manifestUrlProvider: _FakeManifestUrlProvider(Uri.parse(manifestUrl)),
        downloader: _MapDownloader({
          manifestUrl: manifestJson,
          upgradedPackUrl: upgradedPack,
        }),
        region: 'ca',
      );

      expect(upgradeResult.success, isTrue);

      final status = await service.barcodeCatalogStatus();
      expect(status.version, 'v10');
      expect(status.recordCount, 2);

      final records = ReferencePackService.activeBarcodeCatalogRecords(prefs);
      expect(records.map((record) => record['product_name']).toList(), [
        'Updated Coffee',
        'Updated Tea',
      ]);
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

    test('syncs locale-scoped categories, locations, and types packs', () async {
      const manifestUrl =
          'https://firebase.storage.googleapis.com/manifests/reference-manifest.json';
      const categoriesUrl =
          'https://firebase.storage.googleapis.com/packs/categories-ca-fr.json';
      const locationsUrl =
          'https://firebase.storage.googleapis.com/packs/locations-ca-fr.json';
      const typesUrl =
          'https://firebase.storage.googleapis.com/packs/types-ca-fr.json';

      const categoriesPack =
          '{"metadata":{"schema_version":1,"type":"categories","region":"ca","locale":"fr-CA"},"records":[{"id":"produce","label":"Fruits et legumes","app_category":"produce","synonyms":["fruit"]}] }';
      const locationsPack =
          '{"metadata":{"schema_version":1,"type":"locations","region":"ca","locale":"fr-CA"},"records":[{"id":"fridge","label":"Frigo","app_location":"fridge","synonyms":["refrigerateur"]}] }';
      const typesPack =
          '{"metadata":{"schema_version":1,"type":"types","region":"ca","locale":"fr-CA"},"records":[{"id":"raw","label":"Brut","app_type":"raw","synonyms":["frais"]},{"id":"cooked","label":"Cuit","app_type":"cooked","synonyms":["prepare"]},{"id":"packaged","label":"Emballe","app_type":"packaged","synonyms":["code barre"]}] }';

      final categoriesChecksum = sha256
          .convert(utf8.encode(categoriesPack))
          .toString();
      final locationsChecksum = sha256
          .convert(utf8.encode(locationsPack))
          .toString();
      final typesChecksum = sha256.convert(utf8.encode(typesPack)).toString();

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
    },
    {
      "type": "types",
      "region": "ca",
      "locale": "fr-CA",
      "version": "1.0.0",
      "checksum": "$typesChecksum",
      "minimum_app_version": "1.0.0",
      "download_url": "$typesUrl"
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
        typesUrl: typesPack,
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
      final typesResult = await service.syncTypesPack(
        manifestUrlProvider: manifestProvider,
        downloader: downloader,
        region: 'ca',
        locale: 'fr-CA',
      );

      expect(categoriesResult.success, isTrue);
      expect(locationsResult.success, isTrue);
      expect(typesResult.success, isTrue);

      final categoryRecords = ReferencePackService.activeCategoryRecords(prefs);
      final locationRecords = ReferencePackService.activeLocationRecords(prefs);
      final typeRecords = ReferencePackService.activeTypeRecords(prefs);
      expect(categoryRecords, hasLength(1));
      expect(categoryRecords.single.label, 'Fruits et legumes');
      expect(locationRecords, hasLength(1));
      expect(locationRecords.single.label, 'Frigo');
      expect(typeRecords, hasLength(3));
      expect(
        typeRecords
            .where((record) => record.appType.name == 'raw')
            .single
            .label,
        'Brut',
      );
      expect(
        typeRecords
            .where((record) => record.appType.name == 'prepared')
            .single
            .label,
        'Cuit',
      );
      expect(
        typeRecords
            .where((record) => record.appType.name == 'packaged')
            .single
            .label,
        'Emballe',
      );
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

    test('sync selects highest compatible barcode pack version', () async {
      const manifestUrl =
          'https://firebase.storage.googleapis.com/manifests/reference-manifest.json';
      const packV2Url =
          'https://firebase.storage.googleapis.com/packs/barcode-ca-v2.json';
      const packV5Url =
          'https://firebase.storage.googleapis.com/packs/barcode-ca-v5.json';

      const packV2 =
          '{"schema_version":1,"records":[{"barcode":"111111111111","product_name":"Pack V2"}]}';
      const packV5 =
          '{"schema_version":1,"records":[{"barcode":"222222222222","product_name":"Pack V5"}]}';
      final checksumV2 = sha256.convert(utf8.encode(packV2)).toString();
      final checksumV5 = sha256.convert(utf8.encode(packV5)).toString();

      final manifestJson =
          '''
{
  "schema_version": 1,
  "packs": [
    {
      "type": "barcode_catalog",
      "region": "ca",
      "version": "v2",
      "checksum": "$checksumV2",
      "minimum_app_version": "1.0.0",
      "download_url": "$packV2Url"
    },
    {
      "type": "barcode_catalog",
      "region": "ca",
      "version": "v5",
      "checksum": "$checksumV5",
      "minimum_app_version": "2.0.0",
      "download_url": "$packV5Url"
    }
  ]
}
''';

      final service = ReferencePackService(
        preferences: prefs,
        appVersionProvider: () async => '1.5.0',
      );

      final result = await service.syncBarcodeCatalogPack(
        manifestUrlProvider: _FakeManifestUrlProvider(Uri.parse(manifestUrl)),
        downloader: _MapDownloader({
          manifestUrl: manifestJson,
          packV2Url: packV2,
          packV5Url: packV5,
        }),
        region: 'ca',
      );

      expect(result.success, isTrue);

      final status = await service.barcodeCatalogStatus();
      expect(status.version, 'v2');
      final records = ReferencePackService.activeBarcodeCatalogRecords(prefs);
      expect(records.single['product_name'], 'Pack V2');
    });

    test(
      'sync falls back to highest version when no descriptor is compatible',
      () async {
        const manifestUrl =
            'https://firebase.storage.googleapis.com/manifests/reference-manifest.json';
        const packV2Url =
            'https://firebase.storage.googleapis.com/packs/barcode-ca-v2.json';
        const packV5Url =
            'https://firebase.storage.googleapis.com/packs/barcode-ca-v5.json';

        const packV2 =
            '{"schema_version":1,"records":[{"barcode":"111111111111","product_name":"Pack V2"}]}';
        const packV5 =
            '{"schema_version":1,"records":[{"barcode":"222222222222","product_name":"Pack V5"}]}';
        final checksumV2 = sha256.convert(utf8.encode(packV2)).toString();
        final checksumV5 = sha256.convert(utf8.encode(packV5)).toString();

        final manifestJson =
            '''
{
  "schema_version": 1,
  "packs": [
    {
      "type": "barcode_catalog",
      "region": "ca",
      "version": "v2",
      "checksum": "$checksumV2",
      "minimum_app_version": "2.0.0",
      "download_url": "$packV2Url"
    },
    {
      "type": "barcode_catalog",
      "region": "ca",
      "version": "v5",
      "checksum": "$checksumV5",
      "minimum_app_version": "3.0.0",
      "download_url": "$packV5Url"
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
            packV2Url: packV2,
            packV5Url: packV5,
          }),
          region: 'ca',
        );

        expect(result.success, isFalse);
        expect(result.failureReason, 'minimum_app_version_not_met');

        final status = await service.barcodeCatalogStatus();
        expect(status.version, isNull);
        expect(status.recordCount, 0);
      },
    );
  });
}
