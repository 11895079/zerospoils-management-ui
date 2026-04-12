# Shopping Batch Architecture

This document places the receipt matcher work inside the broader shopping-batch feature.

## Scope

This architecture covers:

- batch capture entry and user flow
- receipt-photo OCR processing
- goods-photo suggestion pipeline
- receipt-to-goods matching and merge behavior
- review, confirmation, and persistence into receipt batches

This document does not cover unrelated inventory editing, recipe generation, or subscription/entitlement enforcement details.

## System diagram

```mermaid
flowchart TD
    subgraph EntryPoints[Entry points]
        A[Inventory screen]
        B[Receipt batches list]
        C[Shopping-related CTA]
    end

    subgraph CaptureFlow[Capture and review flow]
        D[ReceiptBatchCaptureScreen]
        E[Receipt photo intake]
        F[Goods photo intake]
        G[ReceiptBatchReviewScreen]
    end

    subgraph VisionPipelines[Vision pipelines]
        H[ML Kit Text Recognition]
        I[Receipt Parser]
        J[BatchGoodsPhotoService]
        K[Fresh item CV service]
    end

    subgraph MatchingLayer[Matching and review shaping]
        L[ReceiptAliasSeedData]
        M[ReceiptAliasCorpus]
        N[ReceiptGoodsMatcher]
        O[ReceiptReviewItemMerger]
    end

    subgraph Persistence[Persistence and history]
        P[ReceiptBatch domain model]
        Q[ReceiptBatch adapter]
        R[Receipt batches history and detail screens]
    end

    subgraph Quality[Verification]
        S[Reviewed public sample fixtures]
        T[Matcher and merger unit tests]
        U[Widget regressions]
    end

    A --> D
    B --> D
    C --> D

    D --> E
    D --> F
    E --> H
    H --> I
    F --> J
    J --> K

    I --> O
    J --> O
    L --> M
    M --> N
    N --> O
    O --> G

    G --> P
    P --> Q
    Q --> R

    S --> T
    N --> T
    O --> T
    D --> U
    G --> U
```

## Architecture notes

### 1. Capture is intentionally split into two input lanes
- Receipt photos exist to extract structured shopping evidence from OCR.
- Goods photos exist to suggest likely purchased items and disambiguate short receipt lines.
- These lanes are related, but not the same problem, and the architecture keeps them separate until merge time.

### 2. Matching is a dedicated sub-layer, not UI glue
- `ReceiptAliasSeedData` stores reviewed shorthand and style-bucket data.
- `ReceiptAliasCorpus` exposes matcher-friendly lookups.
- `ReceiptGoodsMatcher` ranks candidate goods suggestions.
- `ReceiptReviewItemMerger` shapes the final review list shown to the user.

### 3. Review is the product control point
- The system does not auto-import raw OCR blindly.
- Users see the merged result in the review screen before batch persistence.
- This reduces risk from OCR noise and keeps the experience editable.

### 4. Persistence is batch-first
- The saved object is the receipt batch, not just isolated imported items.
- This preserves shopping context such as store, date, totals, receipt images, and goods-photo attachments.

## Related docs

- [docs/receipt-matcher-architecture.md](docs/receipt-matcher-architecture.md)
- [docs/receipt-matcher-runtime-sequence.md](docs/receipt-matcher-runtime-sequence.md)
- [docs/receipt-matcher-system-diagram.md](docs/receipt-matcher-system-diagram.md)
- [docs/receipt-matcher-sources.md](docs/receipt-matcher-sources.md)

## Current implementation status

Implemented:

- receipt-photo OCR path
- goods-photo suggestion path
- reviewed alias corpus and grouped seed data
- matcher scoring, tie-breaks, and sibling suppression
- review-list merge helper
- reviewed public fixture-driven regressions

Still heuristic / not final:

- store-style weighting is not implemented yet
- alias corpus breadth is still limited
- ambiguity explanation is not surfaced in the review UI
- retailer-specific modeling is not yet present