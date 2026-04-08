# Wireframe: Receipt Batches Screen

## Purpose
List past receipt batches with spend totals, item counts, and quick access to batch detail for trend review.

## Screen Layout (Mobile Portrait)

```
┌─────────────────────────────────┐
│  Receipt Batches                │ ← Header
├─────────────────────────────────┤
│  This week                       │
│  ┌─────────────────────────────┤
│  │ Feb 9 • 5 receipts           │ │
│  │ 18 items • $112.40           │ │
│  │ Consumed $64 • Wasted $8     │ │
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┤
│  │ Feb 3 • 3 receipts           │ │
│  │ 12 items • $76.20            │ │
│  │ Consumed $41 • Wasted $12    │ │
│  └─────────────────────────────┘│
│                                 │
│  Older                            │
│  ┌─────────────────────────────┤
│  │ Jan 28 • 4 receipts          │ │
│  │ 15 items • $98.10            │ │
│  │ Consumed $55 • Wasted $6     │ │
│  └─────────────────────────────┘│
│                                 │
└─────────────────────────────────┘
```

## Interaction Details
- **Drawer entry:** “Receipt Batches”
- **Tap batch card:** Opens Batch Detail screen
- **Sort:** Default by date (newest first)

## Accessibility
- [ ] Batch cards announce: date, item count, total spend
- [ ] Section headers use semantic headings

## Related Docs
- See issue `198-shopping-batch-receipt-capture.md` for acceptance criteria

## Status
🚧 **PLACEHOLDER** - To be expanded in Figma during M1.
