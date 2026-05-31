#!/usr/bin/env node

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const admin = require('firebase-admin');

function parseArgs(argv) {
  const args = {
    dryRun: false,
  };

  for (let index = 2; index < argv.length; index += 1) {
    const token = argv[index];
    if (token === '--dry-run') {
      args.dryRun = true;
      continue;
    }

    const next = argv[index + 1];
    switch (token) {
      case '--config':
        args.config = next;
        index += 1;
        break;
      case '--service-account-json':
        args.serviceAccountJson = next;
        index += 1;
        break;
      case '--bucket':
        args.bucket = next;
        index += 1;
        break;
      case '--project-id':
        args.projectId = next;
        index += 1;
        break;
      case '--manifest-object-path':
        args.manifestObjectPath = next;
        index += 1;
        break;
      case '--minimum-app-version':
        args.minimumAppVersion = next;
        index += 1;
        break;
      case '--version':
        args.version = next;
        index += 1;
        break;
      case '--generated-at':
        args.generatedAt = next;
        index += 1;
        break;
      default:
        throw new Error(`Unknown argument: ${token}`);
    }
  }

  return args;
}

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function sha256Hex(data) {
  return crypto.createHash('sha256').update(data).digest('hex');
}

function utcNowIso() {
  return new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
}

async function uploadPublicJson(bucket, objectPath, payload) {
  const file = bucket.file(objectPath);
  await file.save(Buffer.from(JSON.stringify(payload, null, 2) + '\n', 'utf8'), {
    resumable: false,
    metadata: {
      contentType: 'application/json; charset=utf-8',
      cacheControl: objectPath.includes('/manifests/')
        ? 'public, max-age=300, must-revalidate'
        : 'public, max-age=31536000, immutable',
    },
  });
  await file.makePublic();
  return file.publicUrl();
}

function readFirebaseCliAccessToken() {
  const tokenPath = path.join(process.env.HOME, '.config', 'configstore', 'firebase-tools.json');
  const cache = readJson(tokenPath);
  const accessToken = cache.tokens && cache.tokens.access_token;
  const expiresAt = cache.tokens && cache.tokens.expires_at;

  if (!accessToken) {
    throw new Error('Firebase CLI access token is missing from configstore');
  }

  if (expiresAt && Number(expiresAt) <= Date.now() + 60_000) {
    throw new Error('Firebase CLI access token is expired; run `firebase login` again');
  }

  return accessToken;
}

async function readRemoteConfigTemplate(projectId, accessToken) {
  const response = await fetch(`https://firebaseremoteconfig.googleapis.com/v1/projects/${projectId}/remoteConfig`, {
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
  });

  if (!response.ok) {
    throw new Error(`Remote Config GET failed: ${response.status} ${await response.text()}`);
  }

  return {
    etag: response.headers.get('etag'),
    template: await response.json(),
  };
}

async function publishRemoteConfigTemplate(projectId, accessToken, etag, template) {
  const response = await fetch(`https://firebaseremoteconfig.googleapis.com/v1/projects/${projectId}/remoteConfig`, {
    method: 'PUT',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json; charset=utf-8',
      'If-Match': etag || '*',
    },
    body: JSON.stringify(template),
  });

  if (!response.ok) {
    throw new Error(`Remote Config PUT failed: ${response.status} ${await response.text()}`);
  }

  return response.json();
}

async function main() {
  const repoRoot = path.resolve(__dirname, '../..', '..');
  const defaults = {
    config: path.join(repoRoot, 'scripts/reference_pack_barcode_sources.wave_a.json'),
    serviceAccountJson: path.join(
      repoRoot,
      'distribution/zerospoils-23dae-firebase-adminsdk-fbsvc-56a6aa596d.json',
    ),
    bucket: 'zerospoils-23dae.firebasestorage.app',
    projectId: 'zerospoils-23dae',
    manifestObjectPath: 'reference-packs/manifests/prod/latest.json',
    minimumAppVersion: '1.0.0',
  };

  const args = { ...defaults, ...parseArgs(process.argv) };
  if (!args.config || !args.serviceAccountJson) {
    throw new Error('Missing required --config or --service-account-json argument');
  }

  const config = readJson(path.resolve(args.config));
  const serviceAccount = readJson(path.resolve(args.serviceAccountJson));
  const projectId = args.projectId || serviceAccount.project_id;
  const bucketName = args.bucket || `${projectId}.firebasestorage.app`;
  const generatedAt = args.generatedAt || utcNowIso();

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    storageBucket: bucketName,
    projectId,
  });

  const bucket = admin.storage().bucket();
  const regionDescriptors = [];
  let resolvedVersion = args.version;

  for (const source of config.sources || []) {
    const region = String(source.region).toLowerCase();
    const localJsonPath = path.resolve(repoRoot, source.output_json);
    const packJson = readJson(localJsonPath);
    const metadata = packJson.metadata || {};
    const version = resolvedVersion || metadata.dataset_version;

    if (!version) {
      throw new Error(`Unable to resolve version for ${localJsonPath}`);
    }

    if (!resolvedVersion) {
      resolvedVersion = version;
    } else if (resolvedVersion !== version) {
      throw new Error(`Mismatched pack versions: expected ${resolvedVersion}, got ${version} in ${localJsonPath}`);
    }

    const objectPath = `reference-packs/barcode_catalog/${region}/${version}.json`;
    const payload = Buffer.from(JSON.stringify(packJson, null, 2) + '\n', 'utf8');

    regionDescriptors.push({
      type: 'barcode_catalog',
      region,
      version,
      checksum: sha256Hex(payload),
      minimum_app_version: args.minimumAppVersion,
      download_url: `https://storage.googleapis.com/${bucketName}/${objectPath}`,
      local_path: localJsonPath,
      object_path: objectPath,
    });

    if (args.dryRun) {
      console.log(`[dry-run] upload ${localJsonPath} -> ${objectPath}`);
    } else {
      await bucket.file(objectPath).save(payload, {
        resumable: false,
        metadata: {
          contentType: 'application/json; charset=utf-8',
          cacheControl: 'public, max-age=31536000, immutable',
        },
      });
      await bucket.file(objectPath).makePublic();
      console.log(`Uploaded ${objectPath}`);
    }
  }

  if (!resolvedVersion) {
    throw new Error('No reference-pack sources were found in the config');
  }

  regionDescriptors.sort((left, right) => {
    return `${left.type}/${left.region}/${left.version}`.localeCompare(`${right.type}/${right.region}/${right.version}`);
  });

  const manifest = {
    schema_version: 1,
    generated_at: generatedAt,
    packs: regionDescriptors.map(({ local_path, object_path, ...descriptor }) => descriptor),
  };

  const manifestObjectPath = args.manifestObjectPath;
  const manifestUrl = `https://storage.googleapis.com/${bucketName}/${manifestObjectPath}`;

  if (args.dryRun) {
    console.log(`[dry-run] upload manifest -> ${manifestObjectPath}`);
  } else {
    await bucket.file(manifestObjectPath).save(
      Buffer.from(JSON.stringify(manifest, null, 2) + '\n', 'utf8'),
      {
        resumable: false,
        metadata: {
          contentType: 'application/json; charset=utf-8',
          cacheControl: 'public, max-age=300, must-revalidate',
        },
      },
    );
    await bucket.file(manifestObjectPath).makePublic();
    console.log(`Uploaded ${manifestObjectPath}`);
  }

  if (args.dryRun) {
    console.log(`[dry-run] would publish Remote Config reference_pack_manifest_url=${manifestUrl}`);
  } else {
    const accessToken = readFirebaseCliAccessToken();
    const { etag, template } = await readRemoteConfigTemplate(projectId, accessToken);
    const nextTemplate = {
      ...template,
      parameters: {
        ...(template.parameters || {}),
        reference_pack_manifest_url: {
          defaultValue: { value: manifestUrl },
          description: 'Reference pack manifest URL for barcode seed packs',
        },
      },
    };

    delete nextTemplate.version;
    delete nextTemplate.etag;

    await publishRemoteConfigTemplate(projectId, accessToken, etag, nextTemplate);
    console.log(`Published Remote Config reference_pack_manifest_url=${manifestUrl}`);
  }

  console.log(JSON.stringify({
    projectId,
    bucketName,
    resolvedVersion,
    manifestUrl,
    manifestObjectPath,
    packs: regionDescriptors.map(({ local_path, object_path, ...descriptor }) => descriptor),
  }, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});