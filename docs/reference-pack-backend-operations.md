# Reference Pack Backend Operations (M3/206)

## Scope
This runbook covers backend operations for downloadable reference packs used by M3/206.

Client contract (already in app):
- Remote Config key: `reference_pack_manifest_url`
- Manifest lists pack descriptors and URLs
- Pack JSON is downloaded over HTTPS and validated client-side (checksum, schema, min app version)

## Required Firebase Setup

### 1. Storage Paths
Use immutable, versioned pack paths plus a mutable manifest pointer:

- `reference-packs/barcode_catalog/ca/v1.0.0.json`
- `reference-packs/barcode_catalog/us/v1.0.0.json`
- `reference-packs/barcode_catalog/mx/v1.0.0.json`
- `reference-packs/categories/ca/en/v1.0.0.json`
- `reference-packs/categories/ca/fr-CA/v1.0.0.json`
- `reference-packs/locations/us/en/v1.0.0.json`
- `reference-packs/locations/mx/es-419/v1.0.0.json`
- `reference-packs/manifests/prod/latest.json`

Recommended environments:
- `reference-packs/manifests/dev/latest.json`
- `reference-packs/manifests/stage/latest.json`
- `reference-packs/manifests/prod/latest.json`

### 2. Remote Config Key
Set parameter:
- Key: `reference_pack_manifest_url`
- Value: HTTPS URL to the current manifest (for each environment)

Example:
- `https://storage.googleapis.com/<bucket>/reference-packs/manifests/prod/latest.json`

### 3. Access Controls
- Reads: app clients can read pack + manifest URLs
- Writes: only CI/release maintainers can upload artifacts

## Publish Workflow

### Canonical Publish Command
The repo includes a one-step publisher for Wave A reference packs (barcode catalog, categories, and locations). It **requires a Firebase service account JSON** — there is no default path, and a fresh checkout has no `distribution/` directory:

```bash
node firebase/functions/scripts/publish_reference_packs.js \
  --service-account-json ./path/to/service-account.json \
  --remote-config-auth service-account
```

> Most maintainers should publish via the GitHub Action instead (see below). The Action injects the service account from the `FIREBASE_SERVICE_ACCOUNT_JSON` secret, so no local credentials are required.

That command uploads versioned pack JSON files to the project Storage bucket, writes the manifest, makes the objects publicly readable, and updates `reference_pack_manifest_url` in Remote Config.

### GitHub Action Publish Path
Manual publish is also available via workflow dispatch:

- Workflow: `.github/workflows/publish-reference-packs.yml`
- Required secret: `FIREBASE_SERVICE_ACCOUNT_JSON`
- Supports dry-run mode, minimum app version override, barcode version override, and localized pack version override.

### Inputs
- New pack JSON file (example: `barcode_catalog_ca.v1.0.0.json`)
- Hosted pack URL
- Version metadata (`type`, `region`, `version`, `minimum_app_version`)
- Locale metadata when applicable (`locale`, examples: `en`, `fr-CA`, `es-419`, `pt-BR`)

### Step 1: Upload Pack Artifact
Example with `gsutil`:

```bash
gsutil cp ./dist/barcode_catalog_ca.v1.0.0.json \
  gs://<bucket>/reference-packs/barcode_catalog/ca/v1.0.0.json
```

### Step 2: Generate/Update Manifest
Use script:

```bash
python3 scripts/generate_reference_pack_manifest.py \
  --pack-type barcode_catalog \
  --region ca \
  --version 1.0.0 \
  --minimum-app-version 1.0.0 \
  --pack-json ./dist/barcode_catalog_ca.v1.0.0.json \
  --download-url https://storage.googleapis.com/<bucket>/reference-packs/barcode_catalog/ca/v1.0.0.json \
  --base-manifest ./dist/latest.manifest.json \
  --manifest-output ./dist/latest.manifest.json
```

Example for locale-scoped category pack:

```bash
python3 scripts/generate_reference_pack_manifest.py \
  --pack-type categories \
  --region ca \
  --version 1.0.0 \
  --minimum-app-version 1.0.0 \
  --pack-json ./dist/categories_ca_en.v1.0.0.json \
  --download-url https://storage.googleapis.com/<bucket>/reference-packs/categories/ca/en/v1.0.0.json \
  --base-manifest ./dist/latest.manifest.json \
  --manifest-output ./dist/latest.manifest.json
```

### Step 3: Upload Manifest

```bash
gsutil cp ./dist/latest.manifest.json \
  gs://<bucket>/reference-packs/manifests/prod/latest.json
```

### Step 4: Point Remote Config
Set `reference_pack_manifest_url` to the uploaded manifest URL and publish Remote Config.

### Step 5: Verify
- Open app with network enabled
- Trigger update check path
- Confirm diagnostics shows active version and updated time
- Confirm fallback still works when URL is blank/unreachable

## Rollback Workflow

### Fast rollback option A (preferred)
Point `reference_pack_manifest_url` to last known-good manifest URL and publish Remote Config.

### Fast rollback option B
Replace `latest.json` manifest with one that points to previous known-good pack version.

### Post-rollback checks
- Confirm `reference_pack_activation_rolled_back` and/or failure telemetry events
- Confirm app still uses cached or bundled defaults

## Manifest Example

```json
{
  "schema_version": 1,
  "generated_at": "2026-05-30T12:00:00Z",
  "packs": [
    {
      "type": "barcode_catalog",
      "region": "ca",
      "version": "1.0.0",
      "checksum": "<sha256-of-pack-json>",
      "minimum_app_version": "1.0.0",
      "download_url": "https://storage.googleapis.com/<bucket>/reference-packs/barcode_catalog/ca/v1.0.0.json"
    },
    {
      "type": "categories",
      "region": "ca",
      "locale": "en",
      "version": "1.0.0",
      "checksum": "<sha256-of-pack-json>",
      "minimum_app_version": "1.0.0",
      "download_url": "https://storage.googleapis.com/<bucket>/reference-packs/categories/ca/en/v1.0.0.json"
    }
  ]
}
```

## Operational Guardrails
- Keep pack files immutable by version
- Keep manifests short-cache and packs long-cache
- Never edit pack JSON in-place at an existing version path
- Require two-person review for prod manifest changes
- Keep release notes with pack version, checksum, and operator
