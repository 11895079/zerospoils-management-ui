library;

import 'dart:convert';

enum ReferencePackType {
  barcodeCatalog('barcode_catalog'),
  categories('categories'),
  locations('locations'),
  referenceList('reference_list');

  const ReferencePackType(this.wireName);
  final String wireName;

  static ReferencePackType? tryParse(String value) {
    for (final type in ReferencePackType.values) {
      if (type.wireName == value) {
        return type;
      }
    }
    return null;
  }
}

class ReferencePackDescriptor {
  const ReferencePackDescriptor({
    required this.type,
    required this.region,
    required this.version,
    required this.checksum,
    required this.minimumAppVersion,
    required this.downloadUrl,
  });

  final ReferencePackType type;
  final String region;
  final String version;
  final String checksum;
  final String minimumAppVersion;
  final Uri downloadUrl;
}

class ReferencePackManifest {
  const ReferencePackManifest({
    required this.schemaVersion,
    required this.packs,
    this.generatedAt,
  });

  final int schemaVersion;
  final DateTime? generatedAt;
  final List<ReferencePackDescriptor> packs;

  static ReferencePackManifest parse(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Manifest must be a JSON object');
    }

    final schemaVersion = decoded['schema_version'];
    if (schemaVersion is! int) {
      throw const FormatException('schema_version must be an integer');
    }

    final generatedAtValue = decoded['generated_at'];
    DateTime? generatedAt;
    if (generatedAtValue is String && generatedAtValue.isNotEmpty) {
      generatedAt = DateTime.tryParse(generatedAtValue);
      if (generatedAt == null) {
        throw const FormatException('generated_at must be ISO-8601');
      }
    }

    final rawPacks = decoded['packs'];
    if (rawPacks is! List) {
      throw const FormatException('packs must be an array');
    }

    final packs = <ReferencePackDescriptor>[];
    for (final raw in rawPacks) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('pack entry must be an object');
      }

      final typeString = raw['type'];
      final type = typeString is String
          ? ReferencePackType.tryParse(typeString)
          : null;
      if (type == null) {
        throw const FormatException('pack.type is missing or unsupported');
      }

      final region = raw['region'];
      final version = raw['version'];
      final checksum = raw['checksum'];
      final minimumAppVersion = raw['minimum_app_version'];
      final downloadUrlRaw = raw['download_url'];

      if (region is! String || region.isEmpty) {
        throw const FormatException('pack.region is required');
      }
      if (version is! String || version.isEmpty) {
        throw const FormatException('pack.version is required');
      }
      if (checksum is! String || checksum.isEmpty) {
        throw const FormatException('pack.checksum is required');
      }
      if (minimumAppVersion is! String || minimumAppVersion.isEmpty) {
        throw const FormatException('pack.minimum_app_version is required');
      }
      if (downloadUrlRaw is! String || downloadUrlRaw.isEmpty) {
        throw const FormatException('pack.download_url is required');
      }

      final downloadUrl = Uri.tryParse(downloadUrlRaw);
      if (downloadUrl == null || !downloadUrl.hasScheme) {
        throw const FormatException('pack.download_url must be absolute');
      }

      packs.add(
        ReferencePackDescriptor(
          type: type,
          region: region,
          version: version,
          checksum: checksum,
          minimumAppVersion: minimumAppVersion,
          downloadUrl: downloadUrl,
        ),
      );
    }

    return ReferencePackManifest(
      schemaVersion: schemaVersion,
      generatedAt: generatedAt,
      packs: packs,
    );
  }
}
