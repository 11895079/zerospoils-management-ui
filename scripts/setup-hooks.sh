#!/usr/bin/env bash
# Setup script to install Git hooks for ZeroSpoils project
# Run this after cloning the repository

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
HOOKS_DIR="$REPO_ROOT/.git/hooks"
SOURCE_HOOKS="$REPO_ROOT/scripts/hooks"

echo "🔧 Setting up Git hooks for ZeroSpoils..."

# Ensure hooks directory exists
mkdir -p "$HOOKS_DIR"

# Copy pre-commit hook
if [ -f "$SOURCE_HOOKS/pre-commit" ]; then
    cp "$SOURCE_HOOKS/pre-commit" "$HOOKS_DIR/pre-commit"
    chmod +x "$HOOKS_DIR/pre-commit"
    echo "✅ Installed pre-commit hook"
else
    echo "❌ Error: pre-commit hook not found at $SOURCE_HOOKS/pre-commit"
    exit 1
fi

# Copy pre-push hook
if [ -f "$SOURCE_HOOKS/pre-push" ]; then
    cp "$SOURCE_HOOKS/pre-push" "$HOOKS_DIR/pre-push"
    chmod +x "$HOOKS_DIR/pre-push"
    echo "✅ Installed pre-push hook"
else
    echo "❌ Error: pre-push hook not found at $SOURCE_HOOKS/pre-push"
    exit 1
fi

echo ""
echo "✨ Git hooks installed successfully!"
echo ""
echo "The following checks will run before each commit:"
echo "  • Dart formatting (dart format lib test integration_test)"
echo "  • Flutter analyzer (flutter analyze)"
echo ""
echo "To bypass hooks in rare cases, use: git commit --no-verify"
