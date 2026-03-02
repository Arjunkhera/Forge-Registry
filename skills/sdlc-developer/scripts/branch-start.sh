#!/usr/bin/env bash
# branch-start.sh — Create a feature branch for a work item
# Usage: branch-start.sh <subtype> <id> <slug>
# Env: SDLC_BRANCH_PATTERN, SDLC_BASE_BRANCH, SDLC_STASH_BEFORE_CHECKOUT
set -euo pipefail

SUBTYPE="${1:?Usage: branch-start.sh <subtype> <id> <slug>}"
ID="${2:?Usage: branch-start.sh <subtype> <id> <slug>}"
SLUG="${3:?Usage: branch-start.sh <subtype> <id> <slug>}"

BRANCH_PATTERN="${SDLC_BRANCH_PATTERN:-{subtype}/{id}-{slug}}"
BASE_BRANCH="${SDLC_BASE_BRANCH:-main}"
STASH="${SDLC_STASH_BEFORE_CHECKOUT:-true}"

# Resolve branch name from pattern
BRANCH_NAME="${BRANCH_PATTERN}"
BRANCH_NAME="${BRANCH_NAME//\{subtype\}/$SUBTYPE}"
BRANCH_NAME="${BRANCH_NAME//\{id\}/$ID}"
BRANCH_NAME="${BRANCH_NAME//\{slug\}/$SLUG}"

echo "=== SDLC Branch Start ==="
echo "Base branch: $BASE_BRANCH"
echo "New branch:  $BRANCH_NAME"

# Stash uncommitted changes if configured
if [[ "$STASH" == "true" ]]; then
    STASH_OUTPUT=$(git stash 2>&1) || true
    if [[ "$STASH_OUTPUT" != *"No local changes"* ]]; then
        echo "Stashed uncommitted changes"
    fi
fi

# Fetch latest from remote
git fetch origin "$BASE_BRANCH" 2>/dev/null || echo "Warning: could not fetch from origin"

# Checkout base branch and pull latest
git checkout "$BASE_BRANCH" 2>/dev/null || git checkout -b "$BASE_BRANCH" "origin/$BASE_BRANCH"
git pull origin "$BASE_BRANCH" 2>/dev/null || true

# Create and checkout the feature branch
if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME" 2>/dev/null; then
    echo "Branch '$BRANCH_NAME' already exists, checking out"
    git checkout "$BRANCH_NAME"
else
    git checkout -b "$BRANCH_NAME"
    echo "Created branch '$BRANCH_NAME' from '$BASE_BRANCH'"
fi

echo "=== Ready to implement ==="
