library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/item_model.dart';
import 'reference_pack_fetchers.dart';
import 'reference_pack_keys.dart';
import 'reference_pack_manifest.dart';

typedef TelemetryLogger =
    void Function(String eventName, Map<String, dynamic> properties);

class ReferencePackActivationResult {
  const ReferencePackActivationResult({
    required this.success,
    this.failureReason,
  });

  final bool success;
  final String? failureReason;
}

class ReferencePackStatus {
  const ReferencePackStatus({
    this.version,
    this.region,
    this.checksum,
    this.updatedAt,
    required this.recordCount,
  });

  final String? version;
  final String? region;
  final String? checksum;
  final DateTime? updatedAt;
  final int recordCount;
}

class ReferenceCategoryRecord {
  const ReferenceCategoryRecord({
    required this.id,
    required this.label,
    required this.appCategory,
    required this.synonyms,
  });

  final String id;
  final String label;
  final ItemCategory appCategory;
  final List<String> synonyms;
}

class ReferenceLocationRecord {
  const ReferenceLocationRecord({
    required this.id,
    required this.label,
    required this.appLocation,
    required this.synonyms,
  });

  final String id;
  final String label;
  final StorageLocation appLocation;
  final List<String> synonyms;
}

class ReferencePackService {
  ReferencePackService({
    SharedPreferences? preferences,
    Future<String> Function()? appVersionProvider,
    TelemetryLogger? telemetry,
  }) : _preferences = preferences,
       _appVersionProvider = appVersionProvider,
       _telemetry = telemetry;

  final SharedPreferences? _preferences;
  final Future<String> Function()? _appVersionProvider;
  final TelemetryLogger? _telemetry;

  Future<SharedPreferences> _prefs() async {
    return _preferences ?? SharedPreferences.getInstance();
  }

  Future<String> _appVersion() async {
    if (_appVersionProvider != null) {
      return _appVersionProvider();
    }

    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return '0.0.0';
    }
  }

  Future<ReferencePackStatus> barcodeCatalogStatus() async {
    final prefs = await _prefs();
    final records = activeBarcodeCatalogRecords(prefs);

    final updatedAtRaw = prefs.getString(
      ReferencePackKeys.activeBarcodePackUpdatedAt,
    );
    final updatedAt = updatedAtRaw == null
        ? null
        : DateTime.tryParse(updatedAtRaw);

    return ReferencePackStatus(
      version: prefs.getString(ReferencePackKeys.activeBarcodePackVersion),
      region: prefs.getString(ReferencePackKeys.activeBarcodePackRegion),
      checksum: prefs.getString(ReferencePackKeys.activeBarcodePackChecksum),
      updatedAt: updatedAt,
      recordCount: records.length,
    );
  }

  Future<ReferencePackActivationResult> syncBarcodeCatalogPack({
    ReferencePackManifestUrlProvider? manifestUrlProvider,
    ReferencePackDownloader? downloader,
    String region = 'ca',
  }) async {
    final resolvedManifestProvider =
        manifestUrlProvider ?? FirebaseRemoteConfigManifestUrlProvider();
    final resolvedDownloader = downloader ?? HttpReferencePackDownloader();

    _telemetry?.call('reference_pack_check_started', {
      'pack_type': ReferencePackType.barcodeCatalog.wireName,
      'region': region,
    });

    final manifestUrl = await resolvedManifestProvider.getManifestUrl();
    if (manifestUrl == null) {
      _telemetry?.call('reference_pack_check_failed', {
        'pack_type': ReferencePackType.barcodeCatalog.wireName,
        'reason': 'manifest_url_unset',
      });
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'manifest_url_unset',
      );
    }

    final String manifestJson;
    try {
      manifestJson = await resolvedDownloader.downloadJson(manifestUrl);
    } catch (_) {
      _telemetry?.call('reference_pack_check_failed', {
        'pack_type': ReferencePackType.barcodeCatalog.wireName,
        'reason': 'manifest_download_failed',
      });
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'manifest_download_failed',
      );
    }

    final ReferencePackManifest manifest;
    try {
      manifest = ReferencePackManifest.parse(manifestJson);
    } catch (_) {
      _telemetry?.call('reference_pack_check_failed', {
        'pack_type': ReferencePackType.barcodeCatalog.wireName,
        'reason': 'manifest_invalid',
      });
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'manifest_invalid',
      );
    }

    final currentVersion = await _appVersion();

    final descriptor = _selectPackDescriptor(
      manifest: manifest,
      type: ReferencePackType.barcodeCatalog,
      region: region,
      locale: null,
      appVersion: currentVersion,
    );

    if (descriptor == null) {
      _telemetry?.call('reference_pack_check_failed', {
        'pack_type': ReferencePackType.barcodeCatalog.wireName,
        'region': region,
        'reason': 'pack_not_found_for_region',
      });
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'pack_not_found_for_region',
      );
    }

    final String packJson;
    try {
      packJson = await resolvedDownloader.downloadJson(descriptor.downloadUrl);
    } catch (_) {
      _telemetry?.call('reference_pack_download_failed', {
        'pack_type': descriptor.type.wireName,
        'region': descriptor.region,
        'version': descriptor.version,
      });
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'pack_download_failed',
      );
    }

    final activation = await activateBarcodeCatalogPack(
      descriptor: descriptor,
      packJson: packJson,
    );

    if (!activation.success) {
      _telemetry?.call('reference_pack_sync_failed', {
        'pack_type': descriptor.type.wireName,
        'region': descriptor.region,
        'version': descriptor.version,
        'reason': activation.failureReason ?? 'activation_failed',
      });
      return activation;
    }

    _telemetry?.call('reference_pack_sync_succeeded', {
      'pack_type': descriptor.type.wireName,
      'region': descriptor.region,
      'version': descriptor.version,
    });

    return activation;
  }

  Future<ReferencePackActivationResult> syncCategoriesPack({
    ReferencePackManifestUrlProvider? manifestUrlProvider,
    ReferencePackDownloader? downloader,
    String region = 'ca',
    String locale = 'en',
  }) async {
    final resolvedManifestProvider =
        manifestUrlProvider ?? FirebaseRemoteConfigManifestUrlProvider();
    final resolvedDownloader = downloader ?? HttpReferencePackDownloader();

    _telemetry?.call('reference_pack_check_started', {
      'pack_type': ReferencePackType.categories.wireName,
      'region': region,
      'locale': locale,
    });

    final manifestUrl = await resolvedManifestProvider.getManifestUrl();
    if (manifestUrl == null) {
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'manifest_url_unset',
      );
    }

    final String manifestJson;
    try {
      manifestJson = await resolvedDownloader.downloadJson(manifestUrl);
    } catch (_) {
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'manifest_download_failed',
      );
    }

    final ReferencePackManifest manifest;
    try {
      manifest = ReferencePackManifest.parse(manifestJson);
    } catch (_) {
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'manifest_invalid',
      );
    }

    final currentVersion = await _appVersion();

    final descriptor = _selectPackDescriptor(
      manifest: manifest,
      type: ReferencePackType.categories,
      region: region,
      locale: locale,
      appVersion: currentVersion,
    );
    if (descriptor == null) {
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'pack_not_found_for_region',
      );
    }

    final String packJson;
    try {
      packJson = await resolvedDownloader.downloadJson(descriptor.downloadUrl);
    } catch (_) {
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'pack_download_failed',
      );
    }

    return activateCategoriesPack(descriptor: descriptor, packJson: packJson);
  }

  Future<ReferencePackActivationResult> syncLocationsPack({
    ReferencePackManifestUrlProvider? manifestUrlProvider,
    ReferencePackDownloader? downloader,
    String region = 'ca',
    String locale = 'en',
  }) async {
    final resolvedManifestProvider =
        manifestUrlProvider ?? FirebaseRemoteConfigManifestUrlProvider();
    final resolvedDownloader = downloader ?? HttpReferencePackDownloader();

    _telemetry?.call('reference_pack_check_started', {
      'pack_type': ReferencePackType.locations.wireName,
      'region': region,
      'locale': locale,
    });

    final manifestUrl = await resolvedManifestProvider.getManifestUrl();
    if (manifestUrl == null) {
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'manifest_url_unset',
      );
    }

    final String manifestJson;
    try {
      manifestJson = await resolvedDownloader.downloadJson(manifestUrl);
    } catch (_) {
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'manifest_download_failed',
      );
    }

    final ReferencePackManifest manifest;
    try {
      manifest = ReferencePackManifest.parse(manifestJson);
    } catch (_) {
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'manifest_invalid',
      );
    }

    final currentVersion = await _appVersion();

    final descriptor = _selectPackDescriptor(
      manifest: manifest,
      type: ReferencePackType.locations,
      region: region,
      locale: locale,
      appVersion: currentVersion,
    );
    if (descriptor == null) {
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'pack_not_found_for_region',
      );
    }

    final String packJson;
    try {
      packJson = await resolvedDownloader.downloadJson(descriptor.downloadUrl);
    } catch (_) {
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'pack_download_failed',
      );
    }

    return activateLocationsPack(descriptor: descriptor, packJson: packJson);
  }

  Future<ReferencePackActivationResult> activateBarcodeCatalogPack({
    required ReferencePackDescriptor descriptor,
    required String packJson,
  }) async {
    final prefs = await _prefs();

    _telemetry?.call('reference_pack_activation_attempted', {
      'pack_type': descriptor.type.wireName,
      'region': descriptor.region,
      'version': descriptor.version,
    });

    if (descriptor.type != ReferencePackType.barcodeCatalog) {
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'unsupported_pack_type',
      );
    }

    final currentVersion = await _appVersion();
    if (_compareVersions(currentVersion, descriptor.minimumAppVersion) < 0) {
      _telemetry?.call('reference_pack_activation_failed', {
        'pack_type': descriptor.type.wireName,
        'reason': 'minimum_app_version_not_met',
      });
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'minimum_app_version_not_met',
      );
    }

    final normalizedExpectedChecksum = descriptor.checksum.toLowerCase();
    final normalizedActualChecksum = sha256
        .convert(utf8.encode(packJson))
        .toString();
    if (normalizedActualChecksum != normalizedExpectedChecksum) {
      _telemetry?.call('reference_pack_activation_failed', {
        'pack_type': descriptor.type.wireName,
        'reason': 'checksum_mismatch',
      });
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'checksum_mismatch',
      );
    }

    final validation = _validateBarcodePack(packJson);
    if (validation != null) {
      _telemetry?.call('reference_pack_activation_failed', {
        'pack_type': descriptor.type.wireName,
        'reason': validation,
      });
      return ReferencePackActivationResult(
        success: false,
        failureReason: validation,
      );
    }

    final previousState = _snapshotBarcodeState(prefs);

    try {
      await prefs.setString(
        ReferencePackKeys.activeBarcodePackRecordsJson,
        packJson,
      );
      await prefs.setString(
        ReferencePackKeys.activeBarcodePackVersion,
        descriptor.version,
      );
      await prefs.setString(
        ReferencePackKeys.activeBarcodePackRegion,
        descriptor.region,
      );
      await prefs.setString(
        ReferencePackKeys.activeBarcodePackChecksum,
        normalizedActualChecksum,
      );
      await prefs.setString(
        ReferencePackKeys.activeBarcodePackUpdatedAt,
        DateTime.now().toUtc().toIso8601String(),
      );
    } catch (_) {
      await _restoreBarcodeState(prefs, previousState);
      _telemetry?.call('reference_pack_activation_rolled_back', {
        'pack_type': descriptor.type.wireName,
      });
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'activation_failed_rolled_back',
      );
    }

    _telemetry?.call('reference_pack_activation_succeeded', {
      'pack_type': descriptor.type.wireName,
      'region': descriptor.region,
      'version': descriptor.version,
    });

    return const ReferencePackActivationResult(success: true);
  }

  Future<ReferencePackActivationResult> activateCategoriesPack({
    required ReferencePackDescriptor descriptor,
    required String packJson,
  }) async {
    if (descriptor.type != ReferencePackType.categories) {
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'unsupported_pack_type',
      );
    }

    final currentVersion = await _appVersion();
    if (_compareVersions(currentVersion, descriptor.minimumAppVersion) < 0) {
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'minimum_app_version_not_met',
      );
    }

    final normalizedExpectedChecksum = descriptor.checksum.toLowerCase();
    final normalizedActualChecksum = sha256
        .convert(utf8.encode(packJson))
        .toString();
    if (normalizedActualChecksum != normalizedExpectedChecksum) {
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'checksum_mismatch',
      );
    }

    final validation = _validateCategoriesPack(packJson);
    if (validation != null) {
      return ReferencePackActivationResult(
        success: false,
        failureReason: validation,
      );
    }

    final prefs = await _prefs();
    final snapshot = _snapshotCategoriesState(prefs);
    try {
      await prefs.setString(
        ReferencePackKeys.activeCategoriesPackRecordsJson,
        packJson,
      );
      await prefs.setString(
        ReferencePackKeys.activeCategoriesPackVersion,
        descriptor.version,
      );
      await prefs.setString(
        ReferencePackKeys.activeCategoriesPackRegion,
        descriptor.region,
      );
      if (descriptor.locale != null) {
        await prefs.setString(
          ReferencePackKeys.activeCategoriesPackLocale,
          descriptor.locale!,
        );
      } else {
        await prefs.remove(ReferencePackKeys.activeCategoriesPackLocale);
      }
      await prefs.setString(
        ReferencePackKeys.activeCategoriesPackChecksum,
        normalizedActualChecksum,
      );
      await prefs.setString(
        ReferencePackKeys.activeCategoriesPackUpdatedAt,
        DateTime.now().toUtc().toIso8601String(),
      );
    } catch (_) {
      await _restoreCategoriesState(prefs, snapshot);
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'activation_failed_rolled_back',
      );
    }

    return const ReferencePackActivationResult(success: true);
  }

  Future<ReferencePackActivationResult> activateLocationsPack({
    required ReferencePackDescriptor descriptor,
    required String packJson,
  }) async {
    if (descriptor.type != ReferencePackType.locations) {
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'unsupported_pack_type',
      );
    }

    final currentVersion = await _appVersion();
    if (_compareVersions(currentVersion, descriptor.minimumAppVersion) < 0) {
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'minimum_app_version_not_met',
      );
    }

    final normalizedExpectedChecksum = descriptor.checksum.toLowerCase();
    final normalizedActualChecksum = sha256
        .convert(utf8.encode(packJson))
        .toString();
    if (normalizedActualChecksum != normalizedExpectedChecksum) {
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'checksum_mismatch',
      );
    }

    final validation = _validateLocationsPack(packJson);
    if (validation != null) {
      return ReferencePackActivationResult(
        success: false,
        failureReason: validation,
      );
    }

    final prefs = await _prefs();
    final snapshot = _snapshotLocationsState(prefs);
    try {
      await prefs.setString(
        ReferencePackKeys.activeLocationsPackRecordsJson,
        packJson,
      );
      await prefs.setString(
        ReferencePackKeys.activeLocationsPackVersion,
        descriptor.version,
      );
      await prefs.setString(
        ReferencePackKeys.activeLocationsPackRegion,
        descriptor.region,
      );
      if (descriptor.locale != null) {
        await prefs.setString(
          ReferencePackKeys.activeLocationsPackLocale,
          descriptor.locale!,
        );
      } else {
        await prefs.remove(ReferencePackKeys.activeLocationsPackLocale);
      }
      await prefs.setString(
        ReferencePackKeys.activeLocationsPackChecksum,
        normalizedActualChecksum,
      );
      await prefs.setString(
        ReferencePackKeys.activeLocationsPackUpdatedAt,
        DateTime.now().toUtc().toIso8601String(),
      );
    } catch (_) {
      await _restoreLocationsState(prefs, snapshot);
      return const ReferencePackActivationResult(
        success: false,
        failureReason: 'activation_failed_rolled_back',
      );
    }

    return const ReferencePackActivationResult(success: true);
  }

  static List<Map<String, dynamic>> activeBarcodeCatalogRecords(
    SharedPreferences prefs,
  ) {
    return _extractPackRecords(
      prefs.getString(ReferencePackKeys.activeBarcodePackRecordsJson),
    );
  }

  static List<ReferenceCategoryRecord> activeCategoryRecords(
    SharedPreferences prefs,
  ) {
    final records = _extractPackRecords(
      prefs.getString(ReferencePackKeys.activeCategoriesPackRecordsJson),
    );

    final result = <ReferenceCategoryRecord>[];
    for (final row in records) {
      final id = row['id'] as String?;
      final label = row['label'] as String?;
      final appCategoryRaw = row['app_category'] as String?;
      if (id == null || id.isEmpty || label == null || label.isEmpty) {
        continue;
      }

      if (appCategoryRaw == null || appCategoryRaw.isEmpty) {
        continue;
      }
      final appCategory = ItemCategory.fromString(appCategoryRaw);

      final synonymsRaw = row['synonyms'];
      final synonyms = synonymsRaw is List
          ? synonymsRaw
                .whereType<String>()
                .where((s) => s.trim().isNotEmpty)
                .toList()
          : const <String>[];

      result.add(
        ReferenceCategoryRecord(
          id: id,
          label: label,
          appCategory: appCategory,
          synonyms: synonyms,
        ),
      );
    }

    return result;
  }

  static List<ReferenceLocationRecord> activeLocationRecords(
    SharedPreferences prefs,
  ) {
    final records = _extractPackRecords(
      prefs.getString(ReferencePackKeys.activeLocationsPackRecordsJson),
    );

    final result = <ReferenceLocationRecord>[];
    for (final row in records) {
      final id = row['id'] as String?;
      final label = row['label'] as String?;
      final appLocationRaw = row['app_location'] as String?;
      if (id == null || id.isEmpty || label == null || label.isEmpty) {
        continue;
      }

      if (appLocationRaw == null || appLocationRaw.isEmpty) {
        continue;
      }
      final appLocation = StorageLocation.fromString(appLocationRaw);

      final synonymsRaw = row['synonyms'];
      final synonyms = synonymsRaw is List
          ? synonymsRaw
                .whereType<String>()
                .where((s) => s.trim().isNotEmpty)
                .toList()
          : const <String>[];

      result.add(
        ReferenceLocationRecord(
          id: id,
          label: label,
          appLocation: appLocation,
          synonyms: synonyms,
        ),
      );
    }

    return result;
  }

  String? _validateBarcodePack(String packJson) {
    final records = _extractPackRecords(packJson);
    if (records.isEmpty) {
      return 'records_missing';
    }

    for (final record in records) {
      final barcode = record['barcode'];
      final productName = record['product_name'];
      if (barcode is! String || barcode.isEmpty) {
        return 'invalid_record_barcode';
      }
      if (productName is! String || productName.isEmpty) {
        return 'invalid_record_product_name';
      }
    }

    return null;
  }

  String? _validateCategoriesPack(String packJson) {
    final records = _extractPackRecords(packJson);
    if (records.isEmpty) {
      return 'records_missing';
    }

    for (final record in records) {
      final label = record['label'];
      final appCategory = record['app_category'];
      if (label is! String || label.isEmpty) {
        return 'invalid_record_label';
      }
      if (appCategory is! String ||
          !ItemCategory.values.any(
            (category) => category.name == appCategory,
          )) {
        return 'invalid_record_app_category';
      }
    }

    return null;
  }

  String? _validateLocationsPack(String packJson) {
    final records = _extractPackRecords(packJson);
    if (records.isEmpty) {
      return 'records_missing';
    }

    for (final record in records) {
      final label = record['label'];
      final appLocation = record['app_location'];
      if (label is! String || label.isEmpty) {
        return 'invalid_record_label';
      }
      if (appLocation is! String ||
          !StorageLocation.values.any(
            (location) => location.name == appLocation,
          )) {
        return 'invalid_record_app_location';
      }
    }

    return null;
  }

  Map<String, String?> _snapshotBarcodeState(SharedPreferences prefs) {
    return {
      ReferencePackKeys.activeBarcodePackRecordsJson: prefs.getString(
        ReferencePackKeys.activeBarcodePackRecordsJson,
      ),
      ReferencePackKeys.activeBarcodePackVersion: prefs.getString(
        ReferencePackKeys.activeBarcodePackVersion,
      ),
      ReferencePackKeys.activeBarcodePackRegion: prefs.getString(
        ReferencePackKeys.activeBarcodePackRegion,
      ),
      ReferencePackKeys.activeBarcodePackChecksum: prefs.getString(
        ReferencePackKeys.activeBarcodePackChecksum,
      ),
      ReferencePackKeys.activeBarcodePackUpdatedAt: prefs.getString(
        ReferencePackKeys.activeBarcodePackUpdatedAt,
      ),
    };
  }

  Map<String, String?> _snapshotCategoriesState(SharedPreferences prefs) {
    return {
      ReferencePackKeys.activeCategoriesPackRecordsJson: prefs.getString(
        ReferencePackKeys.activeCategoriesPackRecordsJson,
      ),
      ReferencePackKeys.activeCategoriesPackVersion: prefs.getString(
        ReferencePackKeys.activeCategoriesPackVersion,
      ),
      ReferencePackKeys.activeCategoriesPackRegion: prefs.getString(
        ReferencePackKeys.activeCategoriesPackRegion,
      ),
      ReferencePackKeys.activeCategoriesPackLocale: prefs.getString(
        ReferencePackKeys.activeCategoriesPackLocale,
      ),
      ReferencePackKeys.activeCategoriesPackChecksum: prefs.getString(
        ReferencePackKeys.activeCategoriesPackChecksum,
      ),
      ReferencePackKeys.activeCategoriesPackUpdatedAt: prefs.getString(
        ReferencePackKeys.activeCategoriesPackUpdatedAt,
      ),
    };
  }

  Map<String, String?> _snapshotLocationsState(SharedPreferences prefs) {
    return {
      ReferencePackKeys.activeLocationsPackRecordsJson: prefs.getString(
        ReferencePackKeys.activeLocationsPackRecordsJson,
      ),
      ReferencePackKeys.activeLocationsPackVersion: prefs.getString(
        ReferencePackKeys.activeLocationsPackVersion,
      ),
      ReferencePackKeys.activeLocationsPackRegion: prefs.getString(
        ReferencePackKeys.activeLocationsPackRegion,
      ),
      ReferencePackKeys.activeLocationsPackLocale: prefs.getString(
        ReferencePackKeys.activeLocationsPackLocale,
      ),
      ReferencePackKeys.activeLocationsPackChecksum: prefs.getString(
        ReferencePackKeys.activeLocationsPackChecksum,
      ),
      ReferencePackKeys.activeLocationsPackUpdatedAt: prefs.getString(
        ReferencePackKeys.activeLocationsPackUpdatedAt,
      ),
    };
  }

  Future<void> _restoreBarcodeState(
    SharedPreferences prefs,
    Map<String, String?> snapshot,
  ) async {
    for (final entry in snapshot.entries) {
      final value = entry.value;
      if (value == null) {
        await prefs.remove(entry.key);
      } else {
        await prefs.setString(entry.key, value);
      }
    }
  }

  Future<void> _restoreCategoriesState(
    SharedPreferences prefs,
    Map<String, String?> snapshot,
  ) async {
    for (final entry in snapshot.entries) {
      final value = entry.value;
      if (value == null) {
        await prefs.remove(entry.key);
      } else {
        await prefs.setString(entry.key, value);
      }
    }
  }

  Future<void> _restoreLocationsState(
    SharedPreferences prefs,
    Map<String, String?> snapshot,
  ) async {
    for (final entry in snapshot.entries) {
      final value = entry.value;
      if (value == null) {
        await prefs.remove(entry.key);
      } else {
        await prefs.setString(entry.key, value);
      }
    }
  }

  static List<Map<String, dynamic>> _extractPackRecords(String? rawJson) {
    if (rawJson == null || rawJson.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        return const [];
      }

      final schemaVersion =
          decoded['schema_version'] ??
          (decoded['metadata'] is Map<String, dynamic>
              ? (decoded['metadata'] as Map<String, dynamic>)['schema_version']
              : null);
      if (schemaVersion is! int || schemaVersion <= 0) {
        return const [];
      }

      final records = decoded['records'];
      if (records is! List) {
        return const [];
      }

      return records.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return const [];
    }
  }

  ReferencePackDescriptor? _selectPackDescriptor({
    required ReferencePackManifest manifest,
    required ReferencePackType type,
    required String region,
    required String? locale,
    required String appVersion,
  }) {
    final typed = manifest.packs
        .where((pack) => pack.type == type && pack.region == region)
        .toList();
    if (typed.isEmpty) {
      return null;
    }

    final List<ReferencePackDescriptor> candidates;
    if (type == ReferencePackType.barcodeCatalog || locale == null) {
      candidates = typed;
    } else {
      candidates = [];
      final localeCandidates = _localeCandidates(region: region, locale: locale);
      for (final candidate in localeCandidates) {
        for (final pack in typed) {
          if (pack.locale == candidate && !candidates.contains(pack)) {
            candidates.add(pack);
          }
        }
      }

      for (final pack in typed) {
        if ((pack.locale == null || pack.locale!.trim().isEmpty) &&
            !candidates.contains(pack)) {
          candidates.add(pack);
        }
      }

      if (candidates.isEmpty) {
        candidates.addAll(typed);
      }
    }

    final compatible = candidates
        .where((pack) => _compareVersions(appVersion, pack.minimumAppVersion) >= 0)
        .toList();

    final pool = compatible.isNotEmpty ? compatible : candidates;
    return pool.reduce((best, current) {
      return _compareVersions(current.version, best.version) > 0 ? current : best;
    });
  }

  List<String> _localeCandidates({
    required String region,
    required String locale,
  }) {
    final normalized = locale.replaceAll('_', '-').trim();
    final defaultsByRegion = {'ca': 'en', 'us': 'en'};

    final candidates = <String>[];
    if (normalized.isNotEmpty) {
      candidates.add(normalized);
      final language = normalized.split('-').first;
      if (!candidates.contains(language)) {
        candidates.add(language);
      }
      if (language == 'es' && !candidates.contains('es-419')) {
        candidates.add('es-419');
      }
    }

    final regionDefault = defaultsByRegion[region.toLowerCase()];
    if (regionDefault != null && !candidates.contains(regionDefault)) {
      candidates.add(regionDefault);
    }

    return candidates;
  }

  int _compareVersions(String left, String right) {
    final leftParts = _versionCore(left).split('.').map(int.tryParse).toList();
    final rightParts = _versionCore(
      right,
    ).split('.').map(int.tryParse).toList();

    final maxLength = leftParts.length > rightParts.length
        ? leftParts.length
        : rightParts.length;

    for (var i = 0; i < maxLength; i++) {
      final l = i < leftParts.length ? (leftParts[i] ?? 0) : 0;
      final r = i < rightParts.length ? (rightParts[i] ?? 0) : 0;
      if (l != r) {
        return l.compareTo(r);
      }
    }

    return 0;
  }

  String _versionCore(String value) {
    final plus = value.split('+').first;
    return plus.replaceAll(RegExp(r'[^0-9.]'), '');
  }
}
