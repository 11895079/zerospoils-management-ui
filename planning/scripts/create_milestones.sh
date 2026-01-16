#!/usr/bin/env bash
set -euo pipefail

# Creates milestones if missing.
# Requires: gh auth login
# Run from repo root.

milestones=(
  "M1 Foundations in place|||Repo, architecture, offline storage, notifications skeleton."
  "M2 MVP complete|||Manual inventory, expiring views, reminders, basic shopping list."
  "M3 Beta release|||TestFlight/Play internal, feedback loop, crash reporting."
  "M4 Public launch|||Store listings, privacy/terms, release checklist, monitoring."
  "M5 Pro & IoT ready|||Receipt scanning, household sync, advanced insights, IoT hooks."
)
for m in "${milestones[@]}"; do
  IFS="|||" read -r title description <<< "$m"
  existing=$(gh api repos/{owner}/{repo}/milestones --paginate -q '.[] | select(.title=="'"$title"'") | .number' 2>/dev/null || true)
  if [ -z "$existing" ]; then
    echo "Creating milestone: $title"
    gh api -X POST repos/{owner}/{repo}/milestones -f title="$title" -f description="$description" >/dev/null
  else
    echo "Milestone exists: $title"
  fi
done
echo "Done."
