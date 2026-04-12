# Receipt Matcher Seed Sources

This note captures safe public sources for building a receipt line-item normalization corpus for shopping-batch matching.

## Public sample sources

### SROIE / ICDAR 2019
- URL: https://rrc.cvc.uab.es/?ch=13
- Use: scanned receipt OCR and key information extraction samples
- Notes: public competition dataset intended for receipt OCR research; useful for noisy line-item strings and OCR-style abbreviations

### CORD v2
- URL: https://huggingface.co/datasets/naver-clova-ix/cord-v2
- Use: receipt image + text samples with a browsable dataset viewer
- Notes: dataset page shows image/text rows and a CC-BY-4.0 license; useful for building and validating canonical item-name mappings

### Kaggle receipt datasets
- URL: https://www.kaggle.com/datasets
- Use: supplemental samples only after manual review
- Notes: quality and licensing vary by uploader. Use only datasets with clear reuse terms and avoid mixing unlabeled or ambiguous sources into the seed corpus.

## Safe ingestion workflow

1. Prefer public OCR datasets over scraping retailer websites.
2. Extract only product line items and harmless shorthand patterns.
3. Do not import customer-identifying fields, payment details, or addresses.
4. Normalize line items into alias-to-canonical mappings.
5. Record source metadata so entries can be reviewed or removed later.
6. Add regression tests from real samples before expanding production matching logic.

## Suggested corpus schema

Use a structured entry for each alias, even if the matcher currently only consumes the alias and canonical value.

```text
alias: raw shorthand or OCR-normalized phrase
canonical: expected normalized product name or token
source: dataset or review bucket, e.g. sroie, cord-v2, manual-seed
store: optional retailer or style family when known
notes: optional rationale, ambiguity, or review comment
```

## Initial seed cases

The current app seed corpus covers these shorthand examples:

- `BNS` -> `banana`
- `BAN` -> `banana`
- `APL` -> `apple`
- `APLS` -> `apple`
- `AVOC` -> `avocado`
- `BROC` -> `broccoli`
- `CUKE` -> `cucumber`
- `ROM LETT` -> `romaine lettuce`
- `TOM` -> `tomato`
- `TMTO SOUP` -> `tomato soup`
- `SWT POT` -> `sweet potato`
- `CHK BRST` -> `chicken breast`
- `CHK THGHS` -> `chicken thighs`
- `CHKN THGS` -> `chicken thighs`
- `PK` -> `pork`
- `SALM` -> `salmon`
- `MLK` -> `milk`
- `ORG MLK` -> `milk`
- `WMLK` -> `whole milk`
- `GRK YGT` -> `greek yogurt`
- `WMLK YOG` -> `whole milk yogurt`
- `YGRT` -> `yogurt`
- `STRWB` -> `strawberry`

## Next expansion step

When we have a vetted batch of real public receipt samples, the next step is to move this seed corpus from handwritten entries to a reviewed data file grouped by store style, then widen regression coverage from single-name matches to full review-list merge scenarios.

## Current implementation status

The app now keeps the reviewed seed aliases in a grouped data file under:

- `app/lib/core/vision/receipt_alias_seed_data.dart`

The normalization layer in `app/lib/core/vision/receipt_alias_corpus.dart` flattens those groups into lookup maps for matcher use. Current grouping is by store style family rather than named retailer:

- `generic-grocery-produce`
- `generic-grocery-protein`
- `generic-grocery-dairy`
- `generic-grocery-packaged`

This is intentional until we ingest a vetted set of real public examples with retailer-specific patterns.

## Reviewed sample fixtures

The current reviewed public sample fixtures live in:

- `app/test/fixtures/receipt_public_sample_review.dart`

These fixtures are normalized examples, not raw receipt exports. Each case records:

- dataset review bucket
- style bucket
- normalized receipt line
- expected canonical goods name or merge outcome

Use these fixtures to add new public-sample regressions before expanding the production alias corpus. Production data should only be updated after a reviewed sample is covered by tests.

## Current ranking policy

For ambiguous receipt lines, the matcher currently uses this order of preference:

1. Better normalized text similarity wins.
2. If similarity is effectively tied, higher goods-photo confidence wins.
3. During review-list merge, sibling goods suggestions close to the winning score are suppressed so one OCR line does not create multiple near-duplicate goods rows.

This keeps ranking behavior deterministic while reducing duplicate review noise from overlapping goods-photo suggestions.