# Wireframe: Batch Receipt Capture Flow

## Purpose
Capture up to 5 receipt photos, extract items, review/edit, and save in one batch.

## Screen Layout (Capture)

```
┌─────────────────────────────────┐
│  Batch Receipt Capture          │ ← Header
├─────────────────────────────────┤
│  Photos (3/5)                   │
│  ┌───────┐ ┌───────┐ ┌───────┐   │
│  │ 📷 1  │ │ 📷 2  │ │ 📷 3  │   │ ← thumbnails
│  └───────┘ └───────┘ └───────┘   │
│  ┌───────┐ ┌───────┐             │
│  │ +     │ │ +     │             │ ← add photo slots (max 5)
│  └───────┘ └───────┘             │
│                                 │
│  Tip: Capture clear photos of   │
│  each receipt section.          │
│                                 │
│  ┌─────────────────────────────┤
│  │ Process Receipts            │ │ ← Primary CTA
│  └─────────────────────────────┘│
└─────────────────────────────────┘
```

## Screen Layout (Review)

```
┌─────────────────────────────────┐
│  Review Items                   │
├─────────────────────────────────┤
│  ☐ Milk              $4.99      │
│  ☐ Apples            $3.49      │
│  ☐ Chicken Breast    $11.20     │
│                                 │
│  Edit item details on tap       │
│                                 │
│  ┌─────────────────────────────┤
│  │ Save to Shopping List       │ │
│  └─────────────────────────────┘│
│  ┌─────────────────────────────┤
│  │ Save to Inventory           │ │
│  └─────────────────────────────┘│
└─────────────────────────────────┘
```

## Interaction Details
- **Limit:** 5 photos; 6th shows limit message
- **Edit:** Tap item to edit name/quantity/price
- **Save:** Choose destination (Shopping List or Inventory)

## Accessibility
- [ ] Photo slots labeled with index
- [ ] Selection state announced for items

## Related Docs
- See issue `190-batch-receipt-capture-mvp.md` for acceptance criteria

## Status
🚧 **PLACEHOLDER** - To be expanded in Figma during M1.
