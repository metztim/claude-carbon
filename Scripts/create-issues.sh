#!/bin/bash
# Run this script locally to create all three GitHub issues
# Requires: gh cli authenticated (gh auth login)

set -e

echo "Creating Issue 1: Installation Date Tracking..."
gh issue create \
  --title "[Feature] Track installation date for before/after usage analysis" \
  --label "enhancement" \
  --body-file docs/INSTALLATION_TRACKING.md

echo "Creating Issue 2: Claude Code Detection..."
gh issue create \
  --title "[UX] Add empty state UI when Claude Code is not installed" \
  --label "enhancement" \
  --body-file docs/CLAUDE_CODE_DETECTION.md

echo "Creating Issue 3: App Store Distribution..."
gh issue create \
  --title "[Docs] Document App Store distribution requirements and limitations" \
  --label "documentation" \
  --body-file docs/APP_STORE_DISTRIBUTION.md

echo "Done! All issues created."
