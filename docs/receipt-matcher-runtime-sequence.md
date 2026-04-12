# Receipt Matcher Runtime Sequence

This document shows the runtime sequence for shopping-batch receipt processing from capture through review.

## Why this exists

The architecture diagram explains the component layout. This sequence diagram explains runtime order, ownership, and handoff between OCR, goods-photo analysis, matching, and review shaping.

## UML sequence diagram

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant Capture as ReceiptBatchCaptureScreen
    participant OCR as ML Kit Text Recognition
    participant Parser as Receipt Parser
    participant Goods as BatchGoodsPhotoService
    participant Merger as ReceiptReviewItemMerger
    participant Matcher as ReceiptGoodsMatcher
    participant Corpus as ReceiptAliasCorpus
    participant Review as ReceiptBatchReviewScreen

    User->>Capture: Add receipt photos
    User->>Capture: Add goods photos
    User->>Capture: Tap Review Batch

    loop For each receipt photo
        Capture->>OCR: processImage(photo)
        OCR-->>Capture: recognized text
    end

    loop For each OCR text block
        Capture->>Parser: parse(text)
        Parser-->>Capture: parsed receipt items
    end

    alt Goods photos provided
        Capture->>Goods: analyzePhotoPaths(paths)
        Goods-->>Capture: goods suggestions
    else No goods photos
        Capture-->>Capture: use empty suggestion list
    end

    Capture->>Merger: merge(parsedItems, goodsSuggestions)

    loop For each parsed receipt item
        Merger->>Matcher: bestMatch(receiptName, goodsSuggestions)
        Matcher->>Corpus: normalize aliases and tokens
        Corpus-->>Matcher: token aliases and phrase aliases
        Matcher-->>Merger: best goods match or null
    end

    Merger-->>Capture: merged review item list
    Capture->>Review: open review screen with merged items
    Review-->>User: editable batch review UI
```

## Notes

- `ReceiptBatchCaptureScreen` is the orchestration point.
- `ReceiptGoodsMatcher` decides best candidate per OCR line.
- `ReceiptReviewItemMerger` shapes the final review list and suppresses near-duplicate sibling goods suggestions.
- `ReceiptAliasCorpus` is used at runtime by the matcher, but its contents originate from the grouped seed data.