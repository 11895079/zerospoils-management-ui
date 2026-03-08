```markdown
## ⚠️ DEFERRED TO M6 PRO TIER — LLM Infrastructure Required

**Decision (March 7, 2026):** Recipe suggestions deferred from M5 (public launch) to M6 (Pro tier) to enable proper LLM-powered personalization. No half-measures; if we're going to invest in recipes, they should be premium-quality with AI assistants (local on-device or cloud).

**Rationale:**
- Bundled recipes + fuzzy matching (free tier) = low differentiation, not worth effort
- LLM-powered suggestions (Pro tier) = proper personalization, justifies paywall
- M5 focuses on free-tier engagement drivers: Smart Replenishment (155) + Weekly Streaks (160)

**M6 Pro Tier Vision:**
- Chef AI assistant with meal planning
- Cloud recipe catalog (1000+ recipes, updated weekly)
- Personalized suggestions based on dietary preferences + usage patterns
- Push notifications for expiring-item recipes
- Tiered payment plan TBD (base Pro vs advanced AI features)

See M6 milestone for implementation details once Pro tier infrastructure is ready.

---

## Original Spec (Archived for M6 Planning)

## Context
Vision mentions recipe suggestions that prioritise soon‑to‑expire items; this is a post‑MVP feature. This issue defines the **full production feature** after POC validation (see M6/185-recipe-suggestions-poc.md for the initial lightweight implementation).

## Goal
Deliver a production-ready recipe suggestion feature that recommends 3–5 recipes based on expiring items, integrates with shopping list, and supports both offline (Free) and cloud-enhanced (Pro) modes.

## Staged Rollout Plan

### Stage 1: POC (M2/M3 — see M6/185-recipe-suggestions-poc.md)
- Local matcher with 10–20 bundled recipes
- Basic fuzzy matching on ingredient names
- Simple UI card on Inventory screen
- Telemetry: `insights_recipe_impression`, `insights_recipe_use`

### Stage 2: Core Feature (M5 — this issue)
- Expand local recipe DB to 100–200 recipes (curated, crowd-sourced, or licensed)
- Enhanced matcher: category awareness, quantity matching, dietary filters
- Improved UI: placement on Inventory + Item Detail screens
- "Add missing items to shopping list" action
- Confidence scoring and fallback messaging when no good match
- Telemetry: add `insights_recipe_opened`, `insights_recipe_skipped`, `insights_recipe_items_added_to_list`

### Stage 3: Pro Enhancements (M6)
- Optional cloud recipe catalog (API-backed, regularly updated)
- ML-powered personalization (user preferences, dietary restrictions, past usage)
- Scheduled push notifications ("You have 5 items expiring tomorrow — here are 3 recipes!")
- Advanced filtering (cuisine type, prep time, skill level)

## Expected behavior

**Free Tier (Offline-Only):**
- Local recipe matcher suggests 3–5 recipes using expiring items (from bundled catalog)
- User can view recipe details (ingredients, instructions)
- User can mark ingredients as "used" (updates inventory consumption events)
- User can add missing ingredients to shopping list
- All data stored locally, no internet required

**Pro Tier (Cloud-Enhanced):**
- Access to larger cloud recipe catalog (1000+ recipes, updated weekly)
- Personalized suggestions based on user preferences and dietary restrictions (opt-in telemetry)
- Push notifications for recipe suggestions when items are expiring soon
- Advanced filters and search within recipes

## Acceptance criteria (Definition of Done)

**Matching Logic:**
- [ ] Local matcher scores recipes by ingredient overlap with expiring items (weighted by urgency)
- [ ] Category-aware matching (e.g., "whole milk" matches "milk" category)
- [ ] Handles plurals/singulars and common synonyms ("tomato" = "tomatoes")
- [ ] Confidence scoring: only suggest recipes with ≥50% ingredient match
- [ ] Fallback messaging when no good matches ("Try searching recipes manually")

**UI/UX:**
- [ ] Recipe suggestions card on Inventory screen (collapsible, shows top 3)
- [ ] Recipe detail screen with ingredients list, instructions, prep time
- [ ] "Mark ingredients used" action (bulk-updates inventory consumption)
- [ ] "Add missing items to shopping list" action
- [ ] Empty state: "Add more items to get recipe suggestions"
- [ ] A/B test placement: Inventory home vs Item Detail screen

**Data & Integration:**
- [ ] Bundled recipe JSON (100–200 recipes) included in app bundle
- [ ] Recipe schema: name, ingredients[], instructions[], prepTime, cuisine, dietary tags
- [ ] When user "marks ingredients used", create consumption events for matched items
- [ ] Missing ingredients action creates shopping list items with recipe context

**Pro Tier Gating:**
- [ ] Cloud recipe catalog gated behind Pro subscription
- [ ] Personalized suggestions require opt-in telemetry + Pro
- [ ] Push notifications for recipe reminders require Pro
- [ ] Free tier limited to bundled catalog (offline-only)

**Testing:**
- [ ] Unit tests: matcher logic (fuzzy names, categories, confidence scoring, edge cases)
- [ ] Widget tests: recipe card rendering, mark-used action, add-to-list action
- [ ] Integration tests: recipe detail → inventory update flow, shopping list creation
- [ ] Manual UX test: 5 sample inventories with varied item sets

**Telemetry:**
- [ ] Events emitted: `insights_recipe_impression`, `insights_recipe_opened`, `insights_recipe_use`, `insights_recipe_skipped`, `insights_recipe_items_added_to_list`
- [ ] Properties: recipe_id, match_confidence, expiring_items_count, user_tier (free/pro)

**Accessibility:**
- [ ] Recipe cards have semantic labels
- [ ] Tap targets ≥44pt
- [ ] High-contrast text on recipe detail screen

## Out of scope
- Full nutrition calculations and calorie tracking (defer to post-launch)
- Multi-provider recipe aggregation (Spoonacular, Edamam APIs) — start with single source
- User-generated recipes and community features (M7+)
- Recipe video tutorials and step-by-step photos

## Implementation notes

**Data Sources (Options):**
1. **Bundled JSON:** Curate 100–200 recipes manually or via open-source datasets (e.g., RecipeNLG, Open Recipes)
2. **Licensed API:** Integrate with Spoonacular or Edamam for Pro tier (pay-per-request model)
3. **Community-driven:** Allow Pro users to submit recipes (moderated queue, defer to M7)

**Matching Algorithm:**
```dart
// Pseudo-code for recipe scoring
double scoreRecipe(Recipe recipe, List<InventoryItem> expiringItems) {
  int matchedIngredients = 0;
  int totalIngredients = recipe.ingredients.length;
  double urgencyWeight = 0.0;
  
  for (ingredient in recipe.ingredients) {
    for (item in expiringItems) {
      if (fuzzyMatch(ingredient, item.name) || categoryMatch(ingredient, item.category)) {
        matchedIngredients++;
        urgencyWeight += urgencyScore(item.expiryDate); // closer expiry = higher weight
      }
    }
  }
  
  double matchRatio = matchedIngredients / totalIngredients;
  return matchRatio * urgencyWeight; // Higher score = better match
}
```

**UX Patterns:**
- Use card-based layout (similar to Achievement Badges)
- Show recipe thumbnail (optional, low-res bundled image)
- Display match confidence: "Uses 4 of 5 ingredients"
- "View Recipe" button opens detail modal
- "Mark Used" confirmation dialog: "This will mark [ingredients] as consumed. Continue?"

**Offline-First:**
- All Free tier recipes bundled in app (no network required)
- Pro tier recipes cached locally after first fetch
- Graceful degradation: show cached recipes if offline

## Test plan

**Automated Tests:**

*Unit Tests (Matcher Logic):*
- Test fuzzy matching: "tomato" matches "tomatoes"
- Test category matching: "milk" matches items in "dairy" category
- Test confidence scoring: recipe with 1/5 ingredients matched scores low
- Test urgency weighting: recipe using items expiring today ranks higher than items expiring next week
- Test edge cases: empty inventory, no expiring items, all items expired

*Widget Tests:*
- Render recipe suggestions card with 3 recipes
- Tap "View Recipe" opens detail screen
- Tap "Mark Used" shows confirmation dialog and updates inventory
- Tap "Add Missing" creates shopping list items
- Empty state renders when no matches found

*Integration Tests:*
- Full flow: Inventory → Recipe suggestion → Mark used → Inventory updated with consumption events
- Shopping list flow: Recipe detail → Add missing → Shopping list contains new items

**Manual Tests:**

1. **Scenario: High Match Confidence**
   - Add items: tomatoes, onions, garlic, pasta (all expiring in 2 days)
   - Open Inventory screen
   - Verify recipe suggestions card shows "Spaghetti Marinara" with "Uses 4 of 4 ingredients"
   - Tap "View Recipe" → detail screen renders
   - Tap "Mark Used" → confirmation dialog → inventory items marked consumed

2. **Scenario: Low Match Confidence**
   - Add items: lettuce, bread (expiring soon)
   - Open Inventory screen
   - Verify no recipe suggestions or fallback message: "Not enough ingredients for recipe suggestions"

3. **Scenario: Missing Ingredients**
   - Inventory: tomatoes, garlic (expiring)
   - Recipe suggestion: "Pasta Primavera" (needs pasta, tomatoes, garlic, basil)
   - Tap "Add Missing" → shopping list contains pasta, basil

4. **Scenario: Pro Tier Cloud Recipes (M6)**
   - Upgrade to Pro
   - Verify cloud recipe catalog loads (1000+ recipes)
   - Verify personalized suggestions based on dietary preferences (vegetarian filter)

5. **Scenario: Offline Behavior**
   - Enable airplane mode
   - Verify Free tier recipes still render (bundled catalog)
   - Verify Pro tier shows cached recipes (graceful degradation)

**A/B Test Variants:**
- **Variant A:** Recipe card on Inventory home (always visible)
- **Variant B:** Recipe suggestions on Item Detail screen (contextual per item)
- **Metric:** Conversion rate (`insights_recipe_use` / `insights_recipe_impression`)

## Dependencies
- M1: `080-define-v1-data-model-item-category-location-events.md` (consumption events)
- M6: `185-recipe-suggestions-poc.md` (POC validation before full build)
- M6: `520-personalized-waste-reduction-tips-opt-in-telemetry.md` (shared telemetry infrastructure for Pro tier)
- Recipe data source: TBD (open-source dataset, licensed API, or manual curation)

```
