# Wave A Seed Barcode Catalog (M3/199)

## Purpose
Provide a reproducible, offline-first starter barcode catalog for Wave A regions (Canada and United States) so packaged-item fast add has useful cold-start coverage without network lookup.

## Approved Source Inputs
- OpenFoodFacts top-scanned country-filtered subsets, licensed under ODbL.
- Manual curation overlay maintained in this repository for quality corrections and region-priority categories.

## License and Attribution
- Upstream source attribution must be retained in release notes and docs when OpenFoodFacts-derived rows are included.
- ODbL obligations apply to derivative databases; legal/compliance review is required before publishing final production pack.
- Curated overlay rows added by the ZeroSpoils team are tracked with source metadata.

## Normalized Schema
Each record in the seed artifact uses:
- `barcode`
- `product_name`
- `brand`
- `category_hint`
- `quantity_hint`
- `unit_hint`
- `region`
- `source`
- `last_curated_at`

Artifact metadata includes:
- `schema_version`
- `region`
- `dataset_version`
- `generated_at`
- `record_count`

## Curation Pipeline
Scripts:
- `scripts/fetch_canada_top_catalog.py` (region-aware API fetch using `--country-query`)
- `scripts/curate_canada_seed_catalog.py` (normalization, dedupe, metadata/report output)
- `scripts/generate_wave_a_barcode_seed_artifacts.py` (config-driven orchestration)
- `scripts/reference_pack_barcode_sources.wave_a.json` (Wave A region source matrix)

Input:
- CSV source rows with `barcode`, `product_name`, `brand`, `category_hint`, `quantity_hint`, `unit_hint`.

Validation and normalization:
- Barcodes normalized to digits only.
- Reject malformed barcode values (must be 8-14 digits).
- Reject rows missing required fields: `barcode`, `product_name`, `category_hint`.

Deduplication tie-break rules:
1. Collapse to one record per normalized barcode.
2. Prefer the row with higher completeness across `product_name`, `brand`, `category_hint`, `quantity_hint`, `unit_hint`.
3. If completeness ties, keep the first row encountered in the curated input order.

Output:
- App-ready JSON artifact with metadata + records.
- Size report JSON with rejection and dedupe counters.

## Packaging and Reuse
- Wave A seed artifact paths:
  - `app/assets/reference-data/barcode_seed_ca.wave_a.json`
  - `app/assets/reference-data/barcode_seed_us.wave_a.json`
- Wave A size report paths:
  - `app/assets/reference-data/barcode_seed_ca.wave_a.report.json`
  - `app/assets/reference-data/barcode_seed_us.wave_a.report.json`
- Wave A source CSVs:
  - `app/assets/reference-data/source/canada_top_ca_wave_a.csv`
  - `app/assets/reference-data/source/united_states_top_us_wave_a.csv`
- Runtime currently consumes the configured local seed asset path in app code; generated artifacts follow the same normalized schema and are designed for M3/206 update-pack reuse.

## Install Size Budget
- MVP seed-pack max budget: **1.5 MB** compressed JSON payload target.
- Build should fail when generated artifact exceeds configured `--max-bytes` threshold.

## Coverage Goals (Wave A)
Prioritize high-frequency packaged categories per region:
- Dairy
- Pantry staples
- Beverages
- Frozen foods
- Bakery

## Refresh Cadence and Ownership
- Cadence: monthly curated refresh or on-demand after major catalog quality findings.
- Owner: mobile platform/data curation workflow owner for M3 OCR/barcode stream.
- Every refresh must produce:
  - regenerated artifact
  - refreshed size report
  - source/license review note

## Wave A Generation Command
```bash
python3 scripts/generate_wave_a_barcode_seed_artifacts.py \
  --config scripts/reference_pack_barcode_sources.wave_a.json \
  --dataset-version YYYY-MM-DD
```

Optional regional run:
```bash
python3 scripts/generate_wave_a_barcode_seed_artifacts.py \
  --config scripts/reference_pack_barcode_sources.wave_a.json \
  --regions us \
  --dataset-version YYYY-MM-DD
```

## Full Dump Local-Split Workflow (Recommended)
To avoid API throttling/server-busy responses, generate Wave A artifacts from the nightly full CSV dump and split locally by country tags.

Official data export page: https://world.openfoodfacts.org/data

Full CSV dump URL:
- `https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz`

Download once locally:
```bash
mkdir -p data/off && \
curl -L --retry 5 --retry-delay 5 \
  -o data/off/en.openfoodfacts.org.products.csv.gz \
  https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz
```

Generate both Wave A regions from local dump:
```bash
python3 scripts/generate_wave_a_barcode_seed_artifacts.py \
  --config scripts/reference_pack_barcode_sources.wave_a.json \
  --dump-gz data/off/en.openfoodfacts.org.products.csv.gz \
  --dataset-version YYYY-MM-DD
```

Generate only US from local dump:
```bash
python3 scripts/generate_wave_a_barcode_seed_artifacts.py \
  --config scripts/reference_pack_barcode_sources.wave_a.json \
  --dump-gz data/off/en.openfoodfacts.org.products.csv.gz \
  --regions us \
  --dataset-version YYYY-MM-DD
```

## Telemetry and Reporting Requirements
For runtime hit-rate visibility (implemented in app telemetry layer):
- `barcode_lookup_completed` with source (`learned` | `seed` | `manual`) and hit/miss.
- Periodic internal report slicing seed-hit rate by category to guide refresh priorities.

## Offline-First Verification
Seed artifact must remain fully usable without network access; learned mappings continue to override seed rows at runtime.
