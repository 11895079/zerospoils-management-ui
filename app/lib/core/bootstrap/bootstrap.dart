// Core bootstrap services for ZeroSpoils app initialization.
//
// Exports all bootstrap services that should be called during app startup.
// Order of initialization is important:
// 1. Firebase (telemetry, crash reporting, remote config)
// 2. Supabase (backend auth, entitlements)
// 3. Feature flags (depends on Firebase Remote Config)

export 'firebase_bootstrap_service.dart';
export 'supabase_bootstrap_service.dart';
