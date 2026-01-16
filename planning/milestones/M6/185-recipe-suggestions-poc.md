```markdown
## Context
Create a small POC for recipe suggestions that demonstrates value while keeping scope limited for MVP (M2).

## Goal
Implement a lightweight local matcher that suggests simple recipes based on 1–3 expiring items.

## Expected behavior
- On Inventory or Item Detail, surface 1–3 simple recipe suggestions that use the most urgent expiring items.
- Suggestions are generated locally from a small built‑in recipe list (no external API).

## Acceptance criteria (Definition of Done)
- [ ] Implement local matcher that scores recipes by ingredient overlap with expiring items.
- [ ] UI card on Inventory screen shows up to 3 recipe suggestions with a "Use this" action that marks ingredients used.
- [ ] Tests for matching logic and UI integration exist.
- [ ] Telemetry events emitted: `insights_recipe_impression`, `insights_recipe_use`.

## Out of scope
- Recipe import, nutrition, remote recipe APIs, and personalization.

## Implementation notes
- Use a tiny recipe JSON bundled in the app (10–20 recipes) and simple fuzzy matching on names.

## Test plan
- Unit tests for matcher; manual UX test with sample inventories covering edge cases.

## Dependencies
- `080-define-v1-data-model-item-category-location-events.md`

```
