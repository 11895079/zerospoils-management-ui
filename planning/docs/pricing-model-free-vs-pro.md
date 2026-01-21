# ZeroSpoils Pricing Model — Free vs Pro

**Last Updated:** January 20, 2026  
**Status:** Planning  
**Monetization Strategy:** Freemium with Pro tier subscription

---

## Pricing Tiers

### Free (Core)
- **Price:** $0/month
- **Target:** Solo users, privacy-conscious households, low-tech adopters
- **Value Prop:** Reduce waste, save money, organize kitchen — 100% offline

### Pro (Paid)
- **Price:** $2.99/month or $29.99/year (save 17%)
- **Target:** Families, tech-savvy households, multi-device users, smart home enthusiasts
- **Value Prop:** Household collaboration + cloud sync + smart home automation + advanced insights

### Future Consideration: Pro+ or Team Tier?
**Option A: Single Pro Tier (Recommended for MVP)**
- Simpler messaging ("Free or Pro — that's it")
- Easier pricing psychology (no decision paralysis)
- Focus on household value, not user limits

**Option B: Multi-Tier Pro (Post-Launch)**
- **Pro:** $2.99/month (2-4 users, 1 household)
- **Pro+:** $4.99/month (unlimited users, 3 households, priority support)
- **Enterprise:** Custom pricing (10+ households, API access, white-label)

**Recommendation:** Start with **single Pro tier** (M6 launch). Add Pro+ in M7 if data shows demand for multi-household or large family use cases.

---

## Feature Matrix

| Feature | Description | Free | Pro | Issue/Milestone |
|---------|-------------|------|-----|-----------------|
| **Core Inventory** | Add, edit, delete food items with expiry dates | ✅ | ✅ | M1: [Issue 090](../milestones/M1/090-flutter-app-skeleton-routing-theming-di.md) |
| **Shopping List** | Create shopping lists, mark purchased, convert to inventory | ✅ | ✅ | M1: [Issue 090](../milestones/M1/090-flutter-app-skeleton-routing-theming-di.md) |
| **Price Tracking (Manual)** | Capture price paid for shopping items, track monthly spending | ✅ | ✅ | M1: [Issue 090](../milestones/M1/090-flutter-app-skeleton-routing-theming-di.md) |
| **Expiring Soon** | View items expiring today/this week/expired | ✅ | ✅ | M1: [Issue 090](../milestones/M1/090-flutter-app-skeleton-routing-theming-di.md) |
| **Basic Waste Tracking** | Mark items consumed/wasted with reason + percentage | ✅ | ✅ | M1: [Issue 080](../milestones/M1/080-define-v1-data-model-item-category-location-events.md) |
| **Local Analytics** | Waste %, items saved, basic charts (offline-only) | ✅ | ✅ | M3: Progress tab |
| **Achievement Badges** | No Waste Week, savings milestones, streak tracking | ✅ | ✅ | M3: [Issue 300](../milestones/M3/300-accountability-achievement-badges-social-motivation.md) |
| **Share Progress** | Share waste % and savings as text/image (privacy-first) | ✅ | ✅ | M3: [Issue 310](../milestones/M3/310-shareable-progress-cards-privacy-first-social-proof.md) |
| **Onboarding Flow** | 8-screen educational flow + interactive tutorial | ✅ | ✅ | M1: [Issue 060](../issues/060-clickable-prototype-walkthrough-capture-feedback-5-users.md) |
| **Prepared Items** | Track cooked/leftover food with prepared date | ✅ | ✅ | M1: [Issue 090](../milestones/M1/090-flutter-app-skeleton-routing-theming-di.md) |
| **Offline-First** | All features work without internet | ✅ | ✅ | M1-M3 |
| **Single Device** | Data stored locally (Hive/sqflite) | ✅ | ✅ | M1: [Issue 090](../milestones/M1/090-flutter-app-skeleton-routing-theming-di.md) |
| | | | | |
| **Multi-Device Sync** | Cloud backup + sync across iOS/Android/Web | ❌ | ✅ | M6: [Issue 470](../issues/470-pro-household-accounts-auth-shared-household-model.md) |
| **Household Sharing** | Share inventory/shopping with family (role-based access) | ❌ | ✅ | M6: [Issue 470](../issues/470-pro-household-accounts-auth-shared-household-model.md) |
| **Receipt OCR (Batch/Single)** | Scan receipts to auto-extract items, prices, and expiry dates | ❌ | ✅ | M6: [Issue 430](../issues/430-pro-receipt-capture-ux-photo-import-with-consent-messaging.md) |
| **Batch Photo Capture** | Take fridge photo, detect multiple items at once | ❌ | ✅ | M6: [Issue 430](../milestones/M6/430-batch-item-detection-poc.md) |
| **Advanced Analytics** | Money saved trends, waste by category over time, environmental impact | ❌ | ✅ | M6: [Issue 490](../issues/490-pro-advanced-insights-dashboard-money-saved-items-saved-trends.md) |
| **Recipe Suggestions (Basic)** | Local recipe suggestions using expiring items (bundled catalog) | ✅ | ✅ | M6: [POC 185](../milestones/M6/185-recipe-suggestions-poc.md) → M5: [Full 185](../milestones/M5/185-recipe-suggestions-prioritize-expiring-items.md) |
| **Recipe Suggestions (Cloud)** | Cloud recipe catalog (1000+ recipes) + personalized suggestions + push notifications | ❌ | ✅ | M5: [Issue 185](../milestones/M5/185-recipe-suggestions-prioritize-expiring-items.md) (Pro tier enhancements) |
| **Smart Home: Alexa** | Voice-enabled shopping list ("Alexa, add milk to ZeroSpoils") | ❌ | ✅ | M6: [Issue 500](../milestones/M6/500-smart-home-integrations-nest-alexa-google-home.md) |
| **Smart Home: Google Home** | Display expiry tab on Nest Hub, morning reminders | ❌ | ✅ | M6: [Issue 500](../milestones/M6/500-smart-home-integrations-nest-alexa-google-home.md) |
| **Smart Home: Nest** | Temperature alerts (impact on food preservation) | ❌ | ✅ | M6: [Issue 500](../milestones/M6/500-smart-home-integrations-nest-alexa-google-home.md) |
| **Data Export** | Export inventory/waste data as CSV/JSON | ✅ | ✅ | M3: [Issue 240](../milestones/M3/240-mvp-data-export-delete-privacy-baseline.md) (privacy baseline for all) |
| **Priority Support** | Email support with 24-hour response SLA | ❌ | ✅ | M6: Issue TBD (Pro-only, requires support infrastructure) |
| **Personalized Tips** | Waste reduction tips based on YOUR data (opt-in telemetry) | ❌ | ✅ | M6: [Issue 520](../milestones/M6/520-personalized-waste-reduction-tips-opt-in-telemetry.md) (NEW) |

---

## Feature Deep Dive: Recipe Suggestions (Free vs Pro)

### Recipe Suggestions — Free Tier (Basic Local)

**What It Is:**
- Local recipe matcher suggests 3–5 recipes using expiring items
- Bundled catalog of 100–200 curated recipes (included in app)
- Fuzzy matching on ingredient names and categories
- Works 100% offline (no internet required)

**Why Free Tier:**
- Core value prop: reduce waste by using expiring items
- Low implementation cost (bundled JSON, no backend)
- Drives user engagement and habit formation
- Foundation for Pro tier upsell

**User Flow:**
1. Open Inventory screen
2. Recipe suggestions card appears (if items expiring soon)
3. View suggested recipes ("Spaghetti Marinara uses 4 of your ingredients")
4. Tap recipe → see ingredients list + instructions
5. Mark ingredients as "used" → inventory updated with consumption events
6. Add missing ingredients to shopping list

**Limitations (Free Tier):**
- Limited catalog size (100–200 recipes vs Pro's 1000+)
- No personalization (everyone gets same suggestions)
- No dietary filters or advanced search
- No push notifications for recipe reminders

### Recipe Suggestions — Pro Tier (Cloud-Enhanced)

**What It Is:**
- All Free tier features PLUS:
- Cloud recipe catalog (1000+ recipes, updated weekly via API)
- Personalized suggestions based on dietary preferences (vegetarian, vegan, gluten-free, etc.)
- ML-powered recommendations learn from your usage patterns
- Push notifications: "You have 5 items expiring tomorrow — try these 3 recipes!"
- Advanced filters: cuisine type, prep time, skill level, allergen exclusions

**Why Pro Tier:**
- Backend API costs (recipe catalog hosting, updates)
- ML model inference for personalization
- Push notification infrastructure
- Telemetry required for personalization (opt-in)
- Value justification: saves time, reduces decision fatigue

**User Flow (Pro-Specific Features):**
1. First-time Pro setup: select dietary preferences (vegetarian, nut allergy, etc.)
2. Receive push notification: "Recipe suggestions ready for your expiring items"
3. Open app → personalized recipes prioritized based on past usage
4. Filter recipes by cuisine ("Show me Italian recipes only")
5. Search full catalog ("Find pasta recipes")
6. Opt-in to telemetry for better personalization over time

**Implementation:**
- Cloud catalog via API (Spoonacular, Edamam, or proprietary)
- Local cache for offline access (Pro recipes cached after first fetch)
- Graceful degradation: show cached recipes if offline
- Telemetry events: `insights_recipe_cloud_fetch`, `insights_recipe_personalized`

**Privacy Model:**
- Free tier: Zero telemetry, fully local matching
- Pro tier: Opt-in telemetry for personalization ("Enable personalized recipes? We'll analyze your usage patterns.")
- User can disable personalization anytime (Settings → Privacy → Personalized Recipes: OFF)

---

## Feature Deep Dive: Price Tracking & Receipt OCR

### Price Tracking (Free Tier)

**What It Is:**
- Manual price entry when adding items to shopping list
- Price field is optional (supports currency formatting, user's locale)
- Enables basic budget tracking ("I spent $45 this week")
- Prices transferred to inventory when converting shopping items

**Why Free Tier:**
- Low cost to implement (just a text input field)
- Drives core value: know what you're spending on food
- No backend processing required (local-only storage)
- Foundation for advanced budget features (Pro tier)

**Data Model:**
```dart
ShoppingItem {
  id: uuid,
  name: String,
  quantity: int,
  unit: String,
  category: String,
  price: double?,           // NEW: optional, user input
  isPurchased: bool,
  createdAt: DateTime,
  convertedAt: DateTime?
}

InventoryItem {
  ...existing fields...,
  purchasePrice: double?,   // Inherited from shopping item
  purchaseDate: DateTime?
}
```

**User Flow:**
1. Open shopping list
2. Add item (name, quantity, category)
3. Optionally enter price: "$3.99" (auto-formats to currency)
4. Mark as purchased
5. Convert to inventory (price preserved)
6. Analytics dashboard shows "Total spent: $45 this month"

### Receipt OCR (Pro Tier)

**What It Is:**
- Scan receipts (batch or single) to auto-extract items, prices, and expiry dates
- Reduces friction of manual entry
- Provides accurate pricing from actual purchases

**Single Receipt Flow:**
1. Tap "Scan Receipt" in shopping list or inventory
2. Camera opens with receipt frame overlay
3. User aligns receipt in frame
4. System extracts: item name, price, category
5. User reviews and approves items
6. Items added to shopping list or inventory

**Batch Receipt Flow (Pro Feature):**
1. Tap "Upload Receipts" in settings
2. Select multiple receipt images from gallery (or take multiple photos)
3. All receipts processed in parallel
4. Consolidated view shows all extracted items
5. User can group by receipt, review prices, adjust as needed
6. Bulk-add to shopping list or inventory

**Why Pro Tier:**
- Backend OCR service (Google Vision API, Tesseract, or proprietary model)
- API costs per request ($0.10-0.50 per receipt)
- Scalability: needs infrastructure for high-volume requests
- Accuracy improvements: ML model training, confidence scoring
- Value justification: saves 5+ minutes per grocery trip

**Implementation Details:**
- Detect receipt text with OCR engine
- Parse structured data: item, price, category, (optional) barcode
- Normalize prices (remove currency symbols, handle formatting)
- Confidence scoring: flag uncertain extractions for user review
- Store receipt images + extracted data (complies with privacy policy)

---

## Feature Deep Dive: Personalized Tips (Pro Tier)

**What It Is:**
- AI-powered recommendations based on user's waste patterns
- Example: "You've wasted dairy 3 times this month. Try buying smaller quantities or freezing."
- Requires opt-in telemetry (anonymized, aggregated waste data)

**Why Pro Tier:**
- Requires backend processing (pattern analysis across user history)
- Telemetry collection (sensitive, requires explicit consent)
- Value justifies paid tier (actionable, personalized insights)

**Privacy Model:**
- **Free Tier:** No telemetry, no tips (fully local, zero tracking)
- **Pro Tier:** Opt-in prompt: "Enable personalized tips? We'll analyze your waste patterns (locally + cloud) to suggest improvements. No personal data shared."
- User can disable anytime (Settings → Privacy → Personalized Tips: OFF)

**Implementation:**
- M6: [Issue 520](../milestones/M6/520-personalized-waste-reduction-tips-opt-in-telemetry.md) (full spec)
- Backend analyzes waste events (anonymized: category, reason, frequency)
- Weekly tip delivered via notification or in-app banner
- Example tips:
  - "You waste produce most often. Consider meal planning on Sundays."
  - "Dairy expires faster in warm weather. Check your fridge temp (20°C is too high)."
  - "You've saved $12 by using items before expiry this week! Keep it up."

---

## Multi-Tier Pricing Considerations

### Question: Should we have multiple paid levels?

**Factors to Consider:**

1. **Household Size**
   - Single Pro tier: Unlimited household members (simpler, better UX)
   - Multi-tier: Pro (2-4 users), Pro+ (unlimited) — adds complexity

2. **Monthly Budget Tracking**
   - Could gate advanced budgeting behind Pro+ (e.g., "Set monthly food budget, get alerts")
   - But: Budget tracking is a core value prop → include in base Pro

3. **Storage Limits**
   - Single Pro tier: Unlimited items (no artificial limits)
   - Multi-tier: Pro (500 items), Pro+ (unlimited) — feels punitive

**Recommendation: Single Pro Tier (M6 Launch)**

**Rationale:**
- **Messaging simplicity:** "Free for solo use, Pro for families" (clear value prop)
- **No decision paralysis:** Users either need Pro features or they don't (no tiering confusion)
- **Household-focused:** Pro = collaboration + sync, not arbitrary limits
- **Competitive:** Most competitors have single paid tier ($3-7/month)

**When to Add Pro+:**
- **M7 or later:** If data shows demand for:
  - Multi-household support (e.g., vacation home + primary residence)
  - API access for developers
  - White-label for enterprises (grocery stores, meal kit services)
  - Priority support with phone/chat (not just email)

---

## Pricing Experiments (Post-Launch)

**Test 1: Annual Discount**
- Current: $29.99/year (17% savings)
- Test: $24.99/year (30% savings) — does this increase annual conversions?

**Test 2: Household Size Messaging**
- Variant A: "Pro: Perfect for families" (emphasis on sharing)
- Variant B: "Pro: Sync across all your devices" (emphasis on convenience)
- Variant C: "Pro: Smart home automation included" (emphasis on tech)

**Test 3: Free Trial**
- 14-day free trial → Does this increase conversions vs immediate paywall?
- Risk: Users forget to cancel → refund requests

**Test 4: Usage-Based Limits (Not Recommended)**
- Free: 50 items max
- Pro: Unlimited
- Problem: Feels punitive, contradicts "reduce waste" mission

---

## Revenue Model Projections

### Conservative Estimate (Year 1)

**Assumptions:**
- 10,000 free users
- 5% conversion to Pro (500 paid users)
- $2.99/month average (mix of monthly + annual)

**Annual Revenue:**
- 500 users × $2.99/month × 12 months = **$17,940/year**
- Minus app store fees (30%) = **$12,558/year**

### Optimistic Estimate (Year 2)

**Assumptions:**
- 50,000 free users
- 8% conversion to Pro (4,000 paid users)
- Smart home integrations drive higher perceived value

**Annual Revenue:**
- 4,000 users × $2.99/month × 12 months = **$143,520/year**
- Minus app store fees (30%) = **$100,464/year**

---

## Competitive Pricing Comparison

| App | Free Tier | Paid Tier | Price | Notes |
|-----|-----------|-----------|-------|-------|
| **ZeroSpoils** (Ours) | ✅ Core inventory + waste tracking | ✅ Pro: Household sync + smart home + insights | $2.99/mo | Best value for families |
| **NoWaste** | ✅ Basic inventory | ✅ Pro: Receipt OCR, unlimited items | $4.99/mo | More expensive, no smart home |
| **FreshBox** | ✅ 50 items max | ✅ Premium: Unlimited items + cloud sync | $6.99/mo | Expensive, punitive item limits |
| **Pantry Check** | ❌ No free tier | — | $3.99/mo | Paywall upfront (high friction) |

**ZeroSpoils Advantage:**
- Lower price than competitors ($2.99 vs $4-7/mo)
- No artificial item limits (generous free tier)
- Unique smart home integrations (Alexa, Google Home, Nest)
- Privacy-first (offline-only for free tier)

---

## Feature Gate Messaging (In-App)

**When Free User Taps Pro Feature:**

```
🔒 Upgrade to Pro

[Feature Name] is available with ZeroSpoils Pro.

✓ Household sharing
✓ Multi-device sync  
✓ Smart home automation
✓ Advanced analytics
✓ Personalized tips

Try Pro free for 14 days, then $2.99/month.

[Start Free Trial]  [Maybe Later]
```

---

## Issue Mapping: Personalized Tips Feature

**Created:** [Issue 520 - Personalized Waste Reduction Tips (Pro Tier)](../milestones/M6/520-personalized-waste-reduction-tips-opt-in-telemetry.md)

**Key Details:**
- **Milestone:** M6 (Pro Tier Features)
- **Priority:** P2 (Enhancement, not core Pro launch)
- **Effort:** M (Medium — backend analysis + ML model)
- **Labels:** `pro-tier`, `analytics`, `personalization`, `telemetry-required`
- **Privacy:** Opt-in required, user controls data collection
- **Implementation:** 
  - Backend analyzes waste events (category, reason, frequency patterns)
  - Weekly tip delivered via push notification or in-app banner
  - Tips stored locally (user can review history)
  - User can disable in Settings → Privacy

**Example Tips Generated:**
- "You waste dairy most often. Try buying smaller quantities."
- "Produce expires fastest for you. Meal plan Sundays to use it all."
- "Great job! You've reduced waste by 5% this month."

**Full Specification:** See [Issue 520](../milestones/M6/520-personalized-waste-reduction-tips-opt-in-telemetry.md) for complete implementation details.

---

## Summary

✅ **Single Pro Tier Recommended** for M6 launch ($2.99/month)  
✅ **Generous Free Tier** to drive adoption (no item limits, full offline functionality)  
✅ **Pro Differentiators** are household value (sync, sharing, smart home, insights)  
✅ **Personalized Tips** live in Pro tier (requires telemetry opt-in)  
✅ **Multi-tier pricing** deferred to M7+ (test market demand first)  
✅ **Competitive pricing** ($2.99 vs $4-7/mo competitors) with superior features
