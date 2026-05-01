#!/usr/bin/env bash
set -euo pipefail

# Configure Android signing secrets for GitHub Actions with local validation.
# Usage:
#   scripts/configure_android_signing_secrets.sh --keystore ~/keystores/zerospoils-release-key.jks --alias zerospoils
# Optional:
#   --repo OWNER/REPO   (defaults to current gh repo)
#   --out-b64 /tmp/keystore.b64

usage() {
  cat <<'EOF'
Configure Android signing secrets for GitHub Actions.

Required:
  --keystore <path>    Path to release keystore (.jks/.keystore)
  --alias <name>       Keystore alias (case-sensitive)

Optional:
  --repo <owner/repo>  Target GitHub repository for secrets
  --out-b64 <path>     Output base64 file path (default: /tmp/keystore.b64)

Example:
  scripts/configure_android_signing_secrets.sh \
    --keystore "$HOME/keystores/zerospoils-release-key.jks" \
    --alias zerospoils \
    --repo 11895079/zerospoils
EOF
}

REPO=""
KEYSTORE_PATH=""
KEY_ALIAS=""
OUT_B64="/tmp/keystore.b64"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --keystore)
      KEYSTORE_PATH="${2:-}"
      shift 2
      ;;
    --alias)
      KEY_ALIAS="${2:-}"
      shift 2
      ;;
    --out-b64)
      OUT_B64="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$KEYSTORE_PATH" || -z "$KEY_ALIAS" ]]; then
  echo "Error: --keystore and --alias are required." >&2
  usage
  exit 1
fi

if [[ ! -f "$KEYSTORE_PATH" ]]; then
  echo "Error: keystore not found: $KEYSTORE_PATH" >&2
  exit 1
fi

if ! command -v keytool >/dev/null 2>&1; then
  echo "Error: keytool is required but not found." >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "Error: gh CLI is required but not found." >&2
  exit 1
fi

if [[ -z "$REPO" ]]; then
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
fi

echo "Target repo: $REPO"
echo "Keystore: $KEYSTORE_PATH"
echo "Alias: $KEY_ALIAS"

read -r -s -p "Enter ANDROID_KEYSTORE_PASSWORD: " STORE_PASS
echo
if [[ -z "$STORE_PASS" ]]; then
  echo "Error: ANDROID_KEYSTORE_PASSWORD cannot be empty." >&2
  exit 1
fi

# Validate store password and alias first.
if ! keytool -list -keystore "$KEYSTORE_PATH" -storepass "$STORE_PASS" >/dev/null 2>&1; then
  echo "Error: ANDROID_KEYSTORE_PASSWORD does not unlock this keystore." >&2
  exit 1
fi

if ! keytool -list -keystore "$KEYSTORE_PATH" -storepass "$STORE_PASS" -alias "$KEY_ALIAS" >/dev/null 2>&1; then
  echo "Error: ANDROID_KEY_ALIAS '$KEY_ALIAS' was not found in this keystore." >&2
  echo "Hint: alias is case-sensitive." >&2
  exit 1
fi

read -r -s -p "Enter ANDROID_KEY_PASSWORD (press Enter to reuse keystore password): " KEY_PASS
echo
if [[ -z "$KEY_PASS" ]]; then
  KEY_PASS="$STORE_PASS"
fi

# Try to validate key password against the alias entry.
if ! keytool -list -v \
  -keystore "$KEYSTORE_PATH" \
  -storepass "$STORE_PASS" \
  -alias "$KEY_ALIAS" \
  -keypass "$KEY_PASS" >/dev/null 2>&1; then
  echo "Error: ANDROID_KEY_PASSWORD does not match key entry '$KEY_ALIAS'." >&2
  exit 1
fi

base64 < "$KEYSTORE_PATH" | tr -d '\n' > "$OUT_B64"

echo "Generated base64 keystore: $OUT_B64"
echo "Setting GitHub Actions secrets..."

# Use stdin to avoid exposing secret values in process lists.
gh secret set ANDROID_KEYSTORE_BASE64 --repo "$REPO" < "$OUT_B64"
printf '%s' "$STORE_PASS" | gh secret set ANDROID_KEYSTORE_PASSWORD --repo "$REPO" -b-
printf '%s' "$KEY_ALIAS" | gh secret set ANDROID_KEY_ALIAS --repo "$REPO" -b-
printf '%s' "$KEY_PASS" | gh secret set ANDROID_KEY_PASSWORD --repo "$REPO" -b-

echo "Done. Secrets updated:"
echo "  - ANDROID_KEYSTORE_BASE64"
echo "  - ANDROID_KEYSTORE_PASSWORD"
echo "  - ANDROID_KEY_ALIAS"
echo "  - ANDROID_KEY_PASSWORD"

echo "Next: push your workflow changes and run a new beta tag build."
