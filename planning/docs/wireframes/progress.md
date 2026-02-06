# Wireframe: Progress Screen

## Purpose
Show a holistic view of progress using local stats and telemetry-derived aggregates (regardless of opt-in). Includes streak badge, inventory summaries, waste insights, value impact, and badge progress.

## Screen Layout (Mobile Portrait)

```
┌─────────────────────────────────┐
│  Progress                       │ ← Header
├─────────────────────────────────┤
│  🔥 5-day streak    [Level up]  │ ← Streak badge card
│  No Waste Week                   │
│  Log 2 more saves to level up    │
│  [progress bar]                  │
├─────────────────────────────────┤
│  Summary                         │
│  Total | Available | Consumed    │
│  Wasted                           │
├─────────────────────────────────┤
│  Expiry Health                   │
│  Today | This Week | Expired     │
│  Expiring Soon | No Expiry       │
├─────────────────────────────────┤
│  Value Impact                    │
│  Total | Consumed | Wasted | Saved
├─────────────────────────────────┤
│  Categories / Locations / Types  │
│  [chips or list breakdowns]      │
├─────────────────────────────────┤
│  Badges & Achievements           │
│  [badge progress list]           │
├─────────────────────────────────┤
│  Telemetry (Local Aggregation)   │
│  Events, Added by source,        │
│  Wasted by reason, Reminders     │
└─────────────────────────────────┘
```

## Interaction Details
- **Streak card** opens badge detail sheet (future).
- **Telemetry section** always shown (local aggregation only; no network required).
- **Badges list** uses progress bars and earned state.

## Accessibility
- Section headers are semantic headings.
- Cards and chips have readable labels and contrast.
- Progress bars include text equivalents.

## Related Docs
- See `docs/design-tokens.md` for spacing and typography.
- See `docs/telemetry.md` for event properties used in local aggregation.
- See issue `M3/300` for badge UI expansion.

## Status
🚧 **PLACEHOLDER** - To be expanded in Figma during M1.
