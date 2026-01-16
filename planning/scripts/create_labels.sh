#!/usr/bin/env bash
set -euo pipefail

# Creates labels if missing.
# Requires: gh auth login
# Run from repo root.

labels=(
  "epic|||0b7285|||Epic / umbrella work"
  "mvp|||2f9e44|||MVP scope"
  "pro|||845ef7|||Pro / subscription scope"
  "iot|||1971c2|||IoT integrations"
  "ux|||f08c00|||UX/UI work"
  "mobile|||228be6|||Mobile app (Flutter)"
  "backend|||5c7cfa|||Backend / services"
  "analytics|||15aabf|||Analytics/insights/telemetry"
  "security|||e03131|||Security/privacy"
  "ci-cd|||0c8599|||CI/CD"
  "release|||343a40|||Release management"
  "docs|||495057|||Documentation"
  "qa|||adb5bd|||Quality / testing"
  "priority:P0|||d00000|||Must do"
  "priority:P1|||f48c06|||Should do"
  "priority:P2|||ffba08|||Could do"
  "size:S|||74c0fc|||Small"
  "size:M|||4dabf7|||Medium"
  "size:L|||1c7ed6|||Large"
  "triage|||ced4da|||Needs triage"
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
