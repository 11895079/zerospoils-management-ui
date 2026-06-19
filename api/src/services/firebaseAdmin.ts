/**
 * Firebase Admin SDK initialisation
 *
 * Initialises the default Firebase app exactly once using credentials from env:
 *   FIREBASE_PROJECT_ID   — required to enable live mode
 *   FIREBASE_SERVICE_ACCOUNT — optional JSON string of the service account key.
 *                              Omit to use Application Default Credentials
 *                              (Cloud Run / GKE / local `gcloud auth`).
 *
 * If FIREBASE_PROJECT_ID is absent the module returns null and callers fall
 * back to the in-process mock so local dev/tests work with no credentials.
 */

import * as admin from 'firebase-admin';
import type { App } from 'firebase-admin/app';

let _app: App | null = null;
let _initialised = false;

export type FirebaseMode = 'live' | 'mock';

function init(): App | null {
  if (_initialised) return _app;
  _initialised = true;

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const serviceAccountRaw = process.env.FIREBASE_SERVICE_ACCOUNT;

  if (!projectId) {
    console.warn('[firebase] FIREBASE_PROJECT_ID not set — using local mock');
    return null;
  }

  try {
    let credential: admin.credential.Credential;

    if (serviceAccountRaw) {
      // Inline JSON string of the service account key
      const serviceAccount = JSON.parse(serviceAccountRaw) as admin.ServiceAccount;
      credential = admin.credential.cert(serviceAccount);
    } else {
      // Application Default Credentials (Cloud Run, GKE, local gcloud auth)
      credential = admin.credential.applicationDefault();
    }

    if (admin.apps.length === 0) {
      _app = admin.initializeApp({ credential, projectId });
    } else {
      _app = admin.apps[0] ?? null;
    }

    console.info(`[firebase] Initialised — project: ${projectId}`);
    return _app;
  } catch (err) {
    console.error('[firebase] Initialisation failed — falling back to mock:', err);
    return null;
  }
}

export function getFirebaseApp(): App | null {
  return init();
}

export function getFirebaseMode(): FirebaseMode {
  return getFirebaseApp() !== null ? 'live' : 'mock';
}

export function getRemoteConfigClient(): admin.remoteConfig.RemoteConfig | null {
  const app = getFirebaseApp();
  if (!app) return null;
  return admin.remoteConfig(app);
}
