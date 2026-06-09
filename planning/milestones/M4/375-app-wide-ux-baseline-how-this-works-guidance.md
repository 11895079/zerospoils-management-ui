# 375: App-Wide UX Baseline + "How This Works" Guidance Model

**Epic:** UX Polish & Launch Readiness  
**Milestone:** M4 (Beta Testing)  
**Priority:** P1  
**Size:** L  
**Dependencies:** 198 (shopping batch capture), 201 (receipt AR extraction), 202 (fresh produce recognition), 210 (shopping list), 220 (shopping->inventory conversion), 204 (onboarding polish)

---

## Context

ZeroSpoils now contains strong feature depth (inventory, expiring, shopping list, receipt batch capture/review, progress insights), but the end-to-end user journey is harder than it should be for new and infrequent users.

The highest-friction areas are:
- understanding when to use Shopping List vs Receipt Batch vs Add Item
- understanding how receipt capture links to item creation and progress insights
- understanding how to recover when OCR/review is imperfect
- understanding where to go next after completing one workflow

Before implementing onboarding polish in M4/204, we need a locked UX baseline for the full app flow so onboarding teaches the real, final behavior instead of a moving target.

---

## Goal

Define and implement a canonical cross-screen UX model for "how the app works," including in-context micro-guidance ("How this works" entry points) and a first-use handoff model, so users can reliably complete key workflows without confusion.

---

## Expected behavior

- A single canonical user journey is documented and implemented for:
  - Add Item (manual / scan)
  - Shopping List planning and purchase conversion
  - Shopping Batch + receipt capture/review
  - Progress insights interpretation and next action
- Each major screen includes a lightweight, non-blocking help entry point (e.g., "How this works") that explains:
  - what this screen is for
  - when to use it
  - what to do next
- Guidance is contextual and short (3-5 bullets), not long tutorials
- Guidance is dismissible and does not block primary actions
- Screen-level CTAs reinforce cross-feature flow (example: from receipt batch save -> prompt to review Progress tab)
- First-use path is explicit: user can choose a preferred starting workflow (manual add, shopping list first, receipt batch first)
- Telemetry measures where users get stuck and whether guidance improves completion

---

## Acceptance criteria (Definition of Done)

### Baseline flow definition
- [ ] Canonical flow map is documented and approved for all 4 tabs plus receipt-batch subflow
- [ ] For each major workflow, entry and exit points are explicit (including "what next" destination)
- [ ] Ambiguous decisions are resolved with clear UX rules (e.g., when to recommend Shopping List vs Batch Capture)

### In-context guidance system
- [ ] Inventory screen has "How this works" help entry point with concise guidance
- [ ] Shopping List screen has "How this works" help entry point with concise guidance
- [ ] Receipt batch capture/review screens have "How this works" help entry point with concise guidance
- [ ] Progress screen has "How this works" help entry point that explains interpretation + next action
- [ ] Guidance content is localized and uses plain language
- [ ] Guidance is keyboard/screen-reader accessible and dismissible

### Cross-feature UX improvements
- [ ] Shopping List includes clear connection text to receipt batch and inventory conversion
- [ ] Receipt batch review includes clear explanation of how accepted lines become tracked items
- [ ] Progress section includes direct pathway to corrective action (inventory, shopping list, or batch history)
- [ ] Empty states include action-oriented copy with one primary CTA

### Telemetry and measurement
- [ ] Events added for help entry open/close and workflow completion after help usage
- [ ] Events added for cross-feature handoff steps (e.g., shopping list -> inventory conversion)
- [ ] Event naming/schema documented in telemetry taxonomy notes

### Testing
- [ ] Widget tests for visibility and interaction of "How this works" entry points
- [ ] Widget tests for help open/dismiss behavior and accessibility semantics
- [ ] Widget tests for key handoff CTAs between tabs/workflows
- [ ] Integration test for at least one canonical end-to-end path (shopping list -> purchase -> inventory -> progress)

### Readiness gate for M4/204
- [ ] M4/204 dependency gate is satisfied: onboarding copy/steps align to this baseline model

---

## Out of scope

- Full visual redesign of every screen
- New AI assistant/chat guidance
- Long-form onboarding replacement (handled by M4/204)
- Recipe recommendation or meal-planning flows

---

## Implementation notes

- Prefer a reusable guidance pattern:
  - top-right icon action or inline info row opening a bottom sheet
  - consistent title: "How this works"
  - 3 sections max: Purpose, Steps, Next
- Keep guidance data-driven where possible to ease localization updates
- Ensure guidance can be surfaced by onboarding later (shared copy source where practical)
- Avoid introducing modal fatigue; never block primary action unless required for safety/privacy

Proposed canonical user flow model:
1. Plan with Shopping List (optional)
2. Capture purchases via Shopping Batch + receipt review OR quick Add Item
3. Confirm inventory state (locations, expiry)
4. Use Progress for feedback loop and corrective action

---

## Test plan

**Automated:**
- Widget test: each target screen renders "How this works" entry point
- Widget test: tapping help opens guidance sheet with expected sections
- Widget test: guidance dismiss works via close button and backdrop
- Widget test: guidance semantics labels read correctly for screen reader
- Widget test: post-action handoff CTA appears after receipt batch review save
- Integration test: shopping list -> mark purchased -> convert to inventory -> progress reflects changes
- Telemetry test: help open/close and handoff events emitted with expected properties

**Manual:**
1. New user lands on each tab and can answer "what this is for" within 10 seconds using in-context help
2. User adds items through both manual and receipt batch paths and understands differences
3. User can move from Shopping List to Inventory without confusion
4. User can interpret Progress and identify one next action from the screen
5. Screen reader announces help controls and sheet content correctly

---

## Dependencies

- M3 feature set completion (receipt and shopping flows)
- M4/204 onboarding polish (consumes this baseline as source of truth)
- Localization strategy for new guidance strings
- Telemetry schema governance for new guidance/handoff events
