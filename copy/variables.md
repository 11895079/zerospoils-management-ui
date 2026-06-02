# Copy Variables — Single Source of Truth

Every marketing artifact references these tokens instead of literal values.
When the publishing org (or any contact detail) changes, **edit this file only.**

> **Note:** The product name **ZeroSpoils** is stable and is written literally
> everywhere. Only the *publisher identity* and contact details are variables.

| Token | Current value | Used in |
|-------|---------------|---------|
| `{{ORG_NAME}}` | _TBD_ | App Store / Play developer name, social bios, "from" name |
| `{{ORG_LEGAL}}` | _TBD_ | Press boilerplate, copyright footers, ToS / privacy references |
| `{{SUPPORT_EMAIL}}` | _TBD_ | Store listings, email signatures, press contact |
| `{{WEBSITE}}` | _TBD_ | All CTAs, footers, store listings |
| `{{SOCIAL_HANDLE}}` | _TBD_ | Social posts, press, footers (use per-platform if they differ) |
| `{{PRESS_EMAIL}}` | _TBD_ (defaults to `{{SUPPORT_EMAIL}}`) | Press one-pager contact line |
| `{{APP_STORE_URL}}` | _TBD_ | Launch posts, email, press (post-listing) |
| `{{PLAY_STORE_URL}}` | _TBD_ | Launch posts, email, press (post-listing) |

## How to use

- In any copy doc, write the token verbatim: `Built by {{ORG_NAME}}.`
- Do **not** paraphrase or hardcode the value inline.
- Before anything ships, do a final find for `{{` to confirm no token is left
  unresolved in published copy.

## Verified-facts tokens (claims pass)

Statistics live here too, each with its source, so a number is never repeated
unsourced across artifacts. Filled during the verification pass.

| Token | Value | Source | Status |
|-------|-------|--------|--------|
| `{{STAT_HOUSEHOLD_WASTE_USD}}` | ~$1,500 / household / yr | _to source: USDA ERS / ReFED_ | ⚠️ unverified |
| `{{STAT_FOOD_WASTE_EMISSIONS}}` | _TBD_ | _to source_ | ⚠️ unverified |
