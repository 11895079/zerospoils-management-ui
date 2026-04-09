## Context
Issue 197 defines the hybrid packaged-item fast-add flow, but that feature should be able to launch even if the barcode catalog starts empty. To improve first-run barcode hit rates for Canadian users without depending on live network lookup, the app needs a curated, reproducible Canada-first seed barcode catalog that can be bundled or later delivered as an update pack.

## Goal
Create a Canada-first seed barcode catalog artifact, curation workflow, and packaging rules so ZeroSpoils can ship a high-confidence offline starter catalog for packaged-item lookup.

## Expected behavior
- Team can build a curated Canada-first barcode catalog from approved data sources into a normalized app-ready artifact
- Catalog includes only the fields needed for fast packaged-item add: barcode, product name, brand, category hint, quantity hint, unit hint, region, source, and curated timestamp
- Catalog packaging is size-conscious and suitable for offline mobile use
- Catalog artifact can be bundled into the app for cold start or reused later by downloadable update packs
- Licensing, attribution, and refresh rules are documented before release
- Quality checks catch malformed barcodes, duplicate records, missing required fields, and oversized output packs

## Acceptance criteria (Definition of Done)
- [ ] Define approved source inputs for the Canada-first seed catalog and document their license and attribution requirements
- [ ] Define the normalized catalog schema used by the app: `barcode`, `product_name`, `brand`, `category_hint`, `quantity_hint`, `unit_hint`, `region`, `source`, `last_curated_at`
- [ ] Build a repeatable curation script or pipeline that filters source data into a Canada-first packaged-food subset
- [ ] Deduplicate conflicting barcode records and document tie-break rules for product name, quantity, and category selection
- [ ] Reject malformed UPC/EAN/GTIN values and records missing required fields
- [ ] Produce an app-ready seed artifact with version metadata and size reporting
- [ ] Document install-size budget and maximum acceptable seed-pack size for MVP
- [ ] Document how the seed artifact is bundled into the app and how it will later be reused by downloadable update packs
- [ ] Document catalog coverage goals for the first Canada release (for example, common national grocery brands and high-frequency pantry/fridge categories)
- [ ] Define a refresh cadence and ownership for future catalog rebuilds
- [ ] Unit/script validation added for schema normalization, deduplication, malformed barcode rejection, and artifact generation
- [ ] Telemetry or internal reporting requirements documented for future catalog hit-rate measurement
- [ ] Offline-first behavior verified (catalog artifact usable with no network dependency)
- [ ] Accessibility basics covered where relevant in documentation or admin tooling

## Out of scope
- Implementing live barcode scan UI or expiry OCR capture
- Mandatory online product lookup
- Cloud sync of user-learned barcode mappings
- Full North America or global product coverage in the first release
- Nutrition facts, allergens, or advanced product enrichment

## Implementation notes
- Start with Canada only; do not attempt to solve North America in the initial pack
- Favor a curated subset over a full raw export so install size remains controlled
- If OpenFoodFacts or another open dataset is used, record exact source version, attribution text, and any share-alike obligations before shipping
- Keep the artifact format simple and app-consumable, such as normalized SQLite or compact JSONL converted into app assets during build
- Design the artifact so it can be reused unchanged by the future update-pack system from issue 206
- User-confirmed learned mappings in the app must always be able to override this seed data at runtime

## Test plan
**Automated:**
- Script test: malformed and invalid barcode rows are rejected during curation
- Script test: duplicate source rows collapse to one normalized record according to documented tie-break rules
- Script test: generated artifact contains required schema fields and version metadata
- Script test: artifact size report is emitted and fails when the configured MVP budget is exceeded

**Manual:**
1. Run the curation pipeline for the Canada dataset and verify an app-ready artifact is produced
2. Review sample outputs across dairy, snacks, canned goods, beverages, and frozen foods for naming/category consistency
3. Verify license and attribution documentation exists for every upstream source used
4. Load the artifact in a local inspection tool and verify a known Canadian barcode resolves the expected basic product fields

## Dependencies
- M3/197 hybrid packaged-item fast add (consumer of the resulting catalog)
- M3/206 downloadable reference-data update packs (optional future delivery mechanism)