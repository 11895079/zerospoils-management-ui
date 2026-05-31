library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    required ReferencePackManifestUrlProvider manifestUrlProvider,
    required ReferencePackDownloader downloader,
    String region = 'ca',
  }) async {
    _telemetry?.call('reference_pack_check_started', {
      'pack_type': ReferencePackType.barcodeCatalog.wireName,
      'region': region,
    });

    final manifestUrl = await manifestUrlProvider.getManifestUrl();
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
      manifestJson = await downloader.downloadJson(manifestUrl);
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

    ReferencePackDescriptor? descriptor;
    for (final pack in manifest.packs) {
      if (pack.type == ReferencePackType.barcodeCatalog &&
          pack.region == region) {
        descriptor = pack;
        break;
      }
    }

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
      packJson = await downloader.downloadJson(descriptor.downloadUrl);
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

  static List<Map<String, dynamic>> activeBarcodeCatalogRecords(
    SharedPreferences prefs,
  ) {
    final raw = prefs.getString(ReferencePackKeys.activeBarcodePackRecordsJson);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return const [];
      }
      final schemaVersion = decoded['schema_version'];
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

  String? _validateBarcodePack(String packJson) {
    try {
      final decoded = jsonDecode(packJson);
      if (decoded is! Map<String, dynamic>) {
        return 'invalid_pack_json';
      }
      final schemaVersion = decoded['schema_version'];
      if (schemaVersion is! int || schemaVersion <= 0) {
        return 'invalid_schema_version';
      }
      final records = decoded['records'];
      if (records is! List) {
        return 'records_missing';
      }

      for (final record in records) {
        if (record is! Map<String, dynamic>) {
          return 'invalid_record';
        }
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
    } catch (_) {
      return 'invalid_pack_json';
    }
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
