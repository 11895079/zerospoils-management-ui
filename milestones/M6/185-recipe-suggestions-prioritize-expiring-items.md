```markdown
## Context
Vision mentions recipe suggestions that prioritise soon‑to‑expire items; no implementation task exists.

## Goal
Design and implement a recipe suggestion feature that recommends recipes using expiring items.

## Expected behavior
- Suggest 3–5 recipes that use items expiring soon; allow users to mark used ingredients and add missing items to shopping list.

## Acceptance criteria (Definition of Done)
- [ ] Backend or local recipe matcher that scores recipes by match to expiring items.
- [ ] UI to surface suggestions on inventory & item detail screens.
- [ ] Tests for matching logic and UI integration.

## Out of scope
- Full recipe import/parsing pipelines and nutrition calculations for MVP.

## Implementation notes
- Start with a simple local recipe database or third‑party API and fuzzy matching on ingredient names.

## Test plan
- Unit tests for matcher; UX test with sample inventory sets.

## Dependencies
- `080-define-v1-data-model-item-category-location-events.md`

```
