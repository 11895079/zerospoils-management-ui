```markdown
**STATUS: Informal feedback received** — Structured user research deferred to post-MVP validation (M4). Current feedback confirms core flows are viable.

## Context
Validate whether the MVP flows are intuitive and low-friction, **especially the shopping list → inventory conversion workflow**. Use an interactive HTML prototype with a comprehensive onboarding flow to prime users with WHY they're using the app and HOW the core workflows operate before asking them to complete tasks.

## Goal
Run 5 moderated user walkthroughs (15-20 min each) with target users, capturing feedback on task completion, UX friction points, and comprehension of the shopping list → inventory flow.

## Expected behavior
- Users can add an item, find expiring items, and add shopping items with minimal guidance
- Users understand the shopping list → inventory workflow after seeing onboarding (Screen 5: Shopping List Workflow)
- Users are primed on the app's value (WHY) before attempting tasks

## Acceptance criteria (Definition of Done)
- [ ] **Onboarding flow** (8 screens) implemented and deployed in prototype
  - Screen 1: Welcome splash
  - Screen 2: Problem statement (food waste context)
  - Screen 3: Solution benefits (track, plan, reduce)
  - Screen 4: Inventory management walkthrough
  - **Screen 5: Shopping List → Inventory conversion** (KEY - step-by-step visual flow)
  - Screen 6: Reduce waste workflow
  - Screen 7: Permissions request
  - Screen 8: Get started
- [ ] **Onboarding explicitly clarifies shopping flow** (checkout → marked purchased → add to inventory with expiry → tracked in inventory tab)
- [ ] **Facilitator script** (`docs/research/facilitator-script.md`) includes:
  - Pre-session: Have participant watch onboarding (4 min)
  - Post-onboarding check: "What happens when you buy something and check it off the shopping list?" (validate comprehension)
  - Task scenarios (7 tasks)
  - Post-test survey (10-12 questions including shopping flow clarity)
- [ ] **Recruit 5 participants** (target: 2-3 meal planners, 2-3 casual users, diverse ages/tech comfort)
- [ ] **Conduct 5 moderated sessions** (20-25 min each):
  1. Onboarding + comprehension check (5 min)
  2. Task scenarios with observations (10 min)
  3. Post-test survey (5 min)
- [ ] **Create `docs/research/round1.md`** with:
  - Participants (anonymized: P1-P5 with profile notes)
  - Onboarding feedback (% understood shopping flow, comprehension quotes)
  - Task completion rates (table: X/5 completed independently, Y/5 needed help, Z/5 failed)
  - **Top friction point:** Shopping list → inventory clarity (did onboarding help? any remaining confusion?)
  - Top 3-5 UX issues (critical/major/minor) with verbatim quotes
  - Proposed fixes ranked by priority
  - Next steps / follow-up issues for M2
- [ ] **Update wireframes** or file issues for improvements
- [ ] **Share findings** with team in sync meeting
- [ ] [N/A] Unit/widget/integration tests (user research only)
- [ ] [N/A] Telemetry instrumentation (research documentation only)

## Out of scope
- Not defined

## Implementation notes

### Onboarding Flow Strategy (NEW)
The onboarding flow addresses user feedback on unclear shopping list → inventory conversion by:
1. **Answer WHY first** (Screens 2-3): Establishes the problem (food waste) and solution (track, plan, reduce)
2. **Teach core flows visually** (Screens 4-6): Uses emoji and step-by-step breakdowns to teach each workflow
3. **Shopping flow is explicit** (Screen 5): Step-by-step walkthrough showing:
   - Before shop: Check inventory, add to shopping list
   - After shop: Mark as purchased → Add to inventory with expiry date
   - Result: Item moves to Inventory tab for tracking
4. **Progressive disclosure**: Users learn before being asked to do

### Prototype Structure (for easy deployment)

## Test plan
**Automated:**
- Verify `docs/research/round1.md` exists and contains required sections (participants, findings, recommendations)
- Script counts findings entries (minimum 3 required)

**Manual:**
1. Recruit 5 participants matching target user profile
2. Conduct moderated walkthrough: add item → view expiring → add to shopping list
3. Record observations and quotes in `docs/research/round1.md`
4. Identify top 3 UX friction points
5. Propose fixes and update wireframes if needed
6. Share findings with team in sync meeting

## Dependencies
- None

```
