#!/usr/bin/env bash
set -euo pipefail

# Adds a few extra labels used by the Epics 6-8 pack (if missing).
# Requires: gh auth login
# Run from repo root.

labels=(
  "ops|||0ca678|||Operations / support / runbooks"
  "integrations|||1864ab|||External integrations (HA, OCR, etc.)"
  "payments|||9c36b5|||Subscription / billing / paywalls"
  "data|||1098ad|||Data modeling, pipelines, retention"
)
existing=$(gh label list --json name -q '.[].name' 2>/dev/null || true)

for l in "${labels[@]}"; do
  IFS="|||" read -r name color description <<< "$l"
  if echo "$existing" | grep -qx "$name"; then
    echo "Label exists: $name"
  else
    echo "Creating label: $name"
    gh label create "$name" --color "$color" --description "$description" >/dev/null
  fi
done

echo "Done."
