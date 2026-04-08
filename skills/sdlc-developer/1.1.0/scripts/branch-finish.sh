#!/usr/bin/env bash
# branch-finish.sh — Push the current branch to remote
# Usage: branch-finish.sh
# Env: SDLC_BASE_BRANCH
set -euo pipefail

BASE_BRANCH="${SDLC_BASE_BRANCH:-main}"
CURRENT_BRANCH=$(git branch --show-current)

if [[ "$CURRENT_BRANCH" == "$BASE_BRANCH" ]]; then
    echo "Error: Cannot finish from base branch '$BASE_BRANCH'" >&2
    exit 1
fi

echo "=== SDLC Branch Finish ==="
echo "Pushing branch: $CURRENT_BRANCH"

# Push to remote with upstream tracking
git push -u origin "$CURRENT_BRANCH"

echo "=== Branch pushed to origin/$CURRENT_BRANCH ==="
echo "Ready for PR creation"
