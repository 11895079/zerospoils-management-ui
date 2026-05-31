#!/usr/bin/env node

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const admin = require('firebase-admin');

function parseArgs(argv) {
  const args = {
    dryRun: false,
    remoteConfigAuth: 'firebase-cli',
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
      case '--reference-pack-root':
        args.referencePackRoot = next;
        index += 1;
        break;
      case '--matrix-config':
        args.matrixConfig = next;
        index += 1;
        break;
      case '--localized-version':
        args.localizedVersion = next;
        index += 1;
        break;
      case '--remote-config-auth':
        args.remoteConfigAuth = next;
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

function normalizePackVersion(fileName) {
  const parsed = path.parse(fileName).name;
  return parsed.startsWith('v') ? parsed.slice(1) : parsed;
}

function utcNowIso() {
  return new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
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

function ensureFileExists(localPath) {
  if (!fs.existsSync(localPath)) {
    throw new Error(`Required pack file not found: ${localPath}`);
  }
}

function buildBarcodeDescriptors({ repoRoot, config, bucketName, explicitVersion, minimumAppVersion }) {
  const descriptors = [];
  let resolvedVersion = explicitVersion || null;

  for (const source of config.sources || []) {
    const region = String(source.region).toLowerCase();
    const localPath = path.resolve(repoRoot, source.output_json);
    ensureFileExists(localPath);

    const payload = Buffer.from(fs.readFileSync(localPath, 'utf8'), 'utf8');
    const parsed = JSON.parse(payload.toString('utf8'));
    const datasetVersion = parsed.metadata && parsed.metadata.dataset_version;

    const version = resolvedVersion || datasetVersion;
    if (!version) {
      throw new Error(`Unable to resolve barcode version for ${localPath}`);
    }
    if (!resolvedVersion) {
      resolvedVersion = version;
    }

    const objectPath = `reference-packs/barcode_catalog/${region}/${version}.json`;
    descriptors.push({
      type: 'barcode_catalog',
      region,
      locale: null,
      version,
      minimum_app_version: minimumAppVersion,
      checksum: sha256Hex(payload),
      download_url: `https://storage.googleapis.com/${bucketName}/${objectPath}`,
      object_path: objectPath,
      local_path: localPath,
      payload,
    });
  }

  return descriptors;
}

function pickLocalizedPackFile(dirPath, localizedVersion) {
  const entries = fs
    .readdirSync(dirPath)
    .filter((name) => name.endsWith('.json'))
    .sort();

  if (!entries.length) {
    throw new Error(`No JSON pack file found in ${dirPath}`);
  }

  if (!localizedVersion) {
    return entries[entries.length - 1];
  }

  const exact = `v${localizedVersion}.json`;
  if (entries.includes(exact)) {
    return exact;
  }

  throw new Error(`Expected ${exact} in ${dirPath}, found: ${entries.join(', ')}`);
}

function buildLocalizedDescriptors({ repoRoot, matrix, referencePackRoot, bucketName, localizedVersion, minimumAppVersion }) {
  const descriptors = [];
  const localizedTypes = (matrix.pack_types || [])
    .filter((packType) => packType.locale_scoped)
    .map((packType) => String(packType.type));

  for (const packType of localizedTypes) {
    for (const region of matrix.regions || []) {
      const regionCode = String(region.code).toLowerCase();
      for (const locale of region.locales || []) {
        const localeTag = String(locale);
        const localeDir = path.resolve(repoRoot, referencePackRoot, packType, regionCode, localeTag);
        if (!fs.existsSync(localeDir)) {
          throw new Error(`Missing localized pack directory: ${localeDir}`);
        }

        const packFile = pickLocalizedPackFile(localeDir, localizedVersion);
        const version = normalizePackVersion(packFile);
        const localPath = path.join(localeDir, packFile);
        const payload = Buffer.from(fs.readFileSync(localPath, 'utf8'), 'utf8');
        JSON.parse(payload.toString('utf8'));

        const objectPath = `reference-packs/${packType}/${regionCode}/${localeTag}/${version}.json`;
        descriptors.push({
          type: packType,
          region: regionCode,
          locale: localeTag,
          version,
          minimum_app_version: minimumAppVersion,
          checksum: sha256Hex(payload),
          download_url: `https://storage.googleapis.com/${bucketName}/${objectPath}`,
          object_path: objectPath,
          local_path: localPath,
          payload,
        });
      }
    }
  }

  return descriptors;
}

function toManifestDescriptor(descriptor) {
  const base = {
    type: descriptor.type,
    region: descriptor.region,
    version: descriptor.version,
    checksum: descriptor.checksum,
    minimum_app_version: descriptor.minimum_app_version,
    download_url: descriptor.download_url,
  };
  if (descriptor.locale) {
    base.locale = descriptor.locale;
  }
  return base;
}

async function uploadPackDescriptor(bucket, descriptor, dryRun) {
  if (dryRun) {
    console.log(`[dry-run] upload ${descriptor.local_path} -> ${descriptor.object_path}`);
    return;
  }

  await bucket.file(descriptor.object_path).save(descriptor.payload, {
    resumable: false,
    metadata: {
      contentType: 'application/json; charset=utf-8',
      cacheControl: 'public, max-age=31536000, immutable',
    },
  });
  await bucket.file(descriptor.object_path).makePublic();
  console.log(`Uploaded ${descriptor.object_path}`);
}

async function publishRemoteConfigWithFirebaseCliToken(projectId, manifestUrl) {
  const accessToken = readFirebaseCliAccessToken();
  const { etag, template } = await readRemoteConfigTemplate(projectId, accessToken);
  const nextTemplate = {
    ...template,
    parameters: {
      ...(template.parameters || {}),
      reference_pack_manifest_url: {
        defaultValue: { value: manifestUrl },
        description: 'Reference pack manifest URL for reference data packs',
      },
    },
  };

  delete nextTemplate.version;
  delete nextTemplate.etag;

  await publishRemoteConfigTemplate(projectId, accessToken, etag, nextTemplate);
}

async function publishRemoteConfigWithServiceAccount(projectId, manifestUrl) {
  const remoteConfig = admin.remoteConfig();
  const template = await remoteConfig.getTemplate();
  template.parameters = template.parameters || {};
  template.parameters.reference_pack_manifest_url = {
    defaultValue: { value: manifestUrl },
    description: 'Reference pack manifest URL for reference data packs',
  };
  await remoteConfig.validateTemplate(template);
  await remoteConfig.publishTemplate(template, { force: true });
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
    referencePackRoot: 'app/assets/reference-data/reference-packs',
    matrixConfig: path.join(repoRoot, 'scripts/reference_pack_wave_a_matrix.json'),
  };

  const args = { ...defaults, ...parseArgs(process.argv) };
  if (!args.config || !args.serviceAccountJson) {
    throw new Error('Missing required --config or --service-account-json argument');
  }
  if (!['firebase-cli', 'service-account'].includes(args.remoteConfigAuth)) {
    throw new Error('--remote-config-auth must be one of: firebase-cli, service-account');
  }

  const config = readJson(path.resolve(args.config));
  const matrix = readJson(path.resolve(args.matrixConfig));
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
  const descriptors = [
    ...buildBarcodeDescriptors({
      repoRoot,
      config,
      bucketName,
      explicitVersion: args.version,
      minimumAppVersion: args.minimumAppVersion,
    }),
    ...buildLocalizedDescriptors({
      repoRoot,
      matrix,
      referencePackRoot: args.referencePackRoot,
      bucketName,
      localizedVersion: args.localizedVersion,
      minimumAppVersion: args.minimumAppVersion,
    }),
  ];

  descriptors.sort((left, right) => {
    return `${left.type}/${left.region}/${left.locale || ''}/${left.version}`
      .localeCompare(`${right.type}/${right.region}/${right.locale || ''}/${right.version}`);
  });

  for (const descriptor of descriptors) {
    await uploadPackDescriptor(bucket, descriptor, args.dryRun);
  }

  const manifest = {
    schema_version: 1,
    generated_at: generatedAt,
    packs: descriptors.map(toManifestDescriptor),
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
    if (args.remoteConfigAuth === 'service-account') {
      await publishRemoteConfigWithServiceAccount(projectId, manifestUrl);
    } else {
      await publishRemoteConfigWithFirebaseCliToken(projectId, manifestUrl);
    }
    console.log(`Published Remote Config reference_pack_manifest_url=${manifestUrl}`);
  }

  console.log(JSON.stringify({
    projectId,
    bucketName,
    barcodeVersion: args.version || null,
    remoteConfigAuth: args.remoteConfigAuth,
    manifestUrl,
    manifestObjectPath,
    packs: descriptors.map(toManifestDescriptor),
  }, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});