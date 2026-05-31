library;

import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:http/http.dart' as http;

abstract class ReferencePackManifestUrlProvider {
  Future<Uri?> getManifestUrl();
}

abstract class ReferencePackDownloader {
  Future<String> downloadJson(Uri url);
}

class ReferencePackRemoteConfigKeys {
  static const manifestUrl = 'reference_pack_manifest_url';
}

class FirebaseRemoteConfigManifestUrlProvider
    implements ReferencePackManifestUrlProvider {
  FirebaseRemoteConfigManifestUrlProvider({
    FirebaseRemoteConfig? remoteConfig,
    this.configKey = ReferencePackRemoteConfigKeys.manifestUrl,
    this.fetchBeforeRead = true,
  }) : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _remoteConfig;
  final String configKey;
  final bool fetchBeforeRead;

  @override
  Future<Uri?> getManifestUrl() async {
    if (fetchBeforeRead) {
      try {
        await _remoteConfig.fetchAndActivate();
      } catch (_) {
        // Best-effort refresh only; fall back to cached value.
      }
    }

    final value = _remoteConfig.getString(configKey).trim();
    if (value.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) {
      return null;
    }

    return uri;
  }
}

class ReferencePackDownloadException implements Exception {
  ReferencePackDownloadException(this.message);

  final String message;

  @override
  String toString() => 'ReferencePackDownloadException: $message';
}

class HttpReferencePackDownloader implements ReferencePackDownloader {
  HttpReferencePackDownloader({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<String> downloadJson(Uri url) async {
    final response = await _client.get(url);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ReferencePackDownloadException(
        'HTTP ${response.statusCode} while downloading ${url.toString()}',
      );
    }
    return response.body;
  }
}
