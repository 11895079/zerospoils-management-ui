library;

/// Connectivity service for monitoring online/offline status
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to monitor app connectivity status
class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  /// Stream of connectivity changes (true = connected, false = no connection)
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((result) {
      return !result.contains(ConnectivityResult.none);
    });
  }

  /// Check current connectivity status
  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}
