import 'package:firebase_core/firebase_core.dart';

const String _firebaseApiKey = String.fromEnvironment(
  'FIREBASE_API_KEY',
  defaultValue: '',
);
const String _firebaseAppId = String.fromEnvironment(
  'FIREBASE_APP_ID',
  defaultValue: '',
);
const String _firebaseMessagingSenderId = String.fromEnvironment(
  'FIREBASE_MESSAGING_SENDER_ID',
  defaultValue: '',
);
const String _firebaseProjectId = String.fromEnvironment(
  'FIREBASE_PROJECT_ID',
  defaultValue: '',
);
const String _firebaseAuthDomain = String.fromEnvironment(
  'FIREBASE_AUTH_DOMAIN',
  defaultValue: '',
);
const String _firebaseStorageBucket = String.fromEnvironment(
  'FIREBASE_STORAGE_BUCKET',
  defaultValue: '',
);
const String _firebaseMeasurementId = String.fromEnvironment(
  'FIREBASE_MEASUREMENT_ID',
  defaultValue: '',
);
const String _firebaseIosBundleId = String.fromEnvironment(
  'FIREBASE_IOS_BUNDLE_ID',
  defaultValue: '',
);

final bool firebaseIntegrationConfigAvailable =
    _firebaseApiKey.isNotEmpty &&
    _firebaseAppId.isNotEmpty &&
    _firebaseMessagingSenderId.isNotEmpty &&
    _firebaseProjectId.isNotEmpty;

Future<bool> ensureFirebaseInitializedForIntegrationTests() async {
  if (!firebaseIntegrationConfigAvailable) {
    return false;
  }

  if (Firebase.apps.isNotEmpty) {
    return true;
  }

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: _firebaseApiKey,
      appId: _firebaseAppId,
      messagingSenderId: _firebaseMessagingSenderId,
      projectId: _firebaseProjectId,
      authDomain: _firebaseAuthDomain.isEmpty ? null : _firebaseAuthDomain,
      storageBucket: _firebaseStorageBucket.isEmpty
          ? null
          : _firebaseStorageBucket,
      measurementId: _firebaseMeasurementId.isEmpty
          ? null
          : _firebaseMeasurementId,
      iosBundleId: _firebaseIosBundleId.isEmpty ? null : _firebaseIosBundleId,
    ),
  );

  return true;
}
