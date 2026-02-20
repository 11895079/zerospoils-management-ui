## Context
Category auto-fill is currently heuristic (keyword rules) and applies to everyone. Pro tier needs an AI-based category inference that is more accurate and can learn from broader item naming patterns.

## Goal
Introduce AI-driven category inference for Pro users, with clear consent and easy override. Heuristic inference remains as fallback.

## Expected behavior
- When a Pro user enters an item name, the app requests AI category inference (if consented).
- The inferred category is auto-selected and marked as “Suggested.”
- Users can override the category; overrides prevent re-application for that item entry.
- If AI inference fails, falls back to heuristic inference.
- No inference is sent when user is not Pro or has not consented.

## Acceptance criteria (Definition of Done)
- [ ] Pro gating: AI inference only runs for Pro users with explicit consent (M6/410, M6/500)
- [ ] Auto-selected category is labeled “Suggested” and can be overridden
- [ ] Override prevents repeated inference updates for the same entry
- [ ] Fallback to heuristic inference on error, timeout, or offline
- [ ] Telemetry events:
  - `category_inference_requested` { source: "item_form", pro: true }
  - `category_inference_applied` { category, confidence, source: "ai" }
  - `category_inference_fallback` { reason }
  - `category_inference_overridden` { from, to }
- [ ] Unit tests for inference service (success, failure, fallback)
- [ ] Widget tests for item form: auto-populate on Pro, no auto-populate when non-Pro
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Item-level brand detection
- Image-based classification (receipt OCR classification is separate)
- Auto-setting storage location or expiry date

## Implementation notes
- Create `CategoryInferenceService` interface in domain layer
- Add `AiCategoryInferenceService` implementation (remote API or on-device model)
- Add `HeuristicCategoryInferenceService` fallback (existing keyword rules)
- Guard inference with Pro entitlement + consent flags
- Add UI hint (e.g., “Suggested”) in the category dropdown when AI result used
- Use a short timeout (e.g., 2–3s) and fall back gracefully
- Keep inference payload minimal: item name only (no PII)

## Test plan
**Automated:**
- Unit test: AI inference success returns category + confidence
- Unit test: AI inference failure triggers heuristic fallback
- Unit test: Pro gating prevents inference when not entitled
- Widget test: Item form auto-selects category when AI inference succeeds
- Widget test: Override prevents re-application in the same entry

**Manual:**
1. Pro user enters “Milk” → category auto-suggests Dairy and shows “Suggested”
2. Override to “Pantry” → suggestion cleared, no re-apply while editing
3. Airplane mode → heuristic fallback used
4. Non‑Pro user enters “Milk” → no AI request, heuristic only

## Dependencies
- M6/410 subscription strategy and gating
- M6/500 consent model for analytics/inference
- M6/440 OCR integration spike (optional input for future expansion)
