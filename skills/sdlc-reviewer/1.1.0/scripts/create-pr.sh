#!/usr/bin/env bash
# create-pr.sh — Create a pull request via gh CLI
# Usage: create-pr.sh <title> <body_file> [--base <branch>] [--draft]
# Env: SDLC_PR_TEMPLATE, SDLC_BASE_BRANCH
set -euo pipefail

TITLE="${1:?Usage: create-pr.sh <title> <body_file> [--base <branch>] [--draft]}"
BODY_FILE="${2:?Usage: create-pr.sh <title> <body_file>}"

BASE_BRANCH="${SDLC_BASE_BRANCH:-main}"
PR_TEMPLATE="${SDLC_PR_TEMPLATE:-}"
DRAFT=false

# Parse optional flags
shift 2
while [[ $# -gt 0 ]]; do
    case "$1" in
        --base)
            BASE_BRANCH="$2"
            shift 2
            ;;
        --draft)
            DRAFT=true
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

echo "=== SDLC PR Creation ==="
echo "Title: $TITLE"
echo "Base:  $BASE_BRANCH"

# Verify gh CLI is available
if ! command -v gh &>/dev/null; then
    echo "Error: gh CLI not found. Install from https://cli.github.com/" >&2
    exit 1
fi

# Verify we're authenticated
if ! gh auth status &>/dev/null; then
    echo "Error: gh CLI not authenticated. Run 'gh auth login'" >&2
    exit 1
fi

# Read body from file
if [[ ! -f "$BODY_FILE" ]]; then
    echo "Error: Body file '$BODY_FILE' not found" >&2
    exit 1
fi

BODY=$(cat "$BODY_FILE")

# Build gh pr create command
CMD="gh pr create --title \"$TITLE\" --body \"$BODY\" --base \"$BASE_BRANCH\""

if [[ "$DRAFT" == "true" ]]; then
    CMD="$CMD --draft"
fi

echo "Creating PR..."
eval "$CMD"

echo "=== PR created ==="
