```markdown
## Context
Vision mentions recipe suggestions that prioritise soon‑to‑expire items; this is a post‑MVP feature.

## Goal
Design and implement a full recipe suggestion feature that recommends recipes using expiring items and integrates with Pro/analytics features.

## Expected behavior
- Suggest 3–5 recipes that use items expiring soon; allow users to mark used ingredients and add missing items to shopping list.

## Acceptance criteria (Definition of Done)
- [ ] Backend or local recipe matcher that scores recipes by match to expiring items.
- [ ] UI to surface suggestions on inventory & item detail screens.
- [ ] Integration with recipes API or managed recipe DB and sync mechanisms (if needed).
- [ ] Tests for matching logic and UI integration.

## Out of scope
- Full nutrition calculations and multi‑provider recipe aggregation in the first iteration.

## Implementation notes
- Prefer a staged rollout: POC → local matcher → API integration.

## Test plan
- Unit tests for matcher; UX test with sample inventory sets; A/B test variants for placement and conversion.

## Dependencies
- `080-define-v1-data-model-item-category-location-events.md`

```
