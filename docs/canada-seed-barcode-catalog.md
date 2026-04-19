# Canada Seed Barcode Catalog (M3/199)

## Purpose
Provide a reproducible, offline-first starter barcode catalog for Canada so packaged-item fast add has useful cold-start coverage without network lookup.

## Approved Source Inputs
- OpenFoodFacts export (Canada-filtered subset), licensed under ODbL.
- Manual curation overlay maintained in this repository for quality corrections and Canada-priority categories.

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
Script: `scripts/curate_canada_seed_catalog.py`

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
- Seed artifact path: `app/assets/reference-data/barcode_seed_ca.v2.json`.
- Size report path: `app/assets/reference-data/barcode_seed_ca.v2.report.json`.
- App runtime currently consumes `app/assets/reference-data/barcode_seed_ca.v2.json` via `LocalBarcodeCatalog._assetPath`.
- The same normalized artifact format is designed to be reused by M3/206 update packs.

## Install Size Budget
- MVP seed-pack max budget: **1.5 MB** compressed JSON payload target.
- Build should fail when generated artifact exceeds configured `--max-bytes` threshold.

## Coverage Goals (Canada MVP)
Prioritize high-frequency packaged categories:
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

## Telemetry and Reporting Requirements
For runtime hit-rate visibility (implemented in app telemetry layer):
- `barcode_lookup_completed` with source (`learned` | `seed` | `manual`) and hit/miss.
- Periodic internal report slicing seed-hit rate by category to guide refresh priorities.

## Offline-First Verification
Seed artifact must remain fully usable without network access; learned mappings continue to override seed rows at runtime.
