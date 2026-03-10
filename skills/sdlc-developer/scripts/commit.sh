#!/usr/bin/env bash
# commit.sh — Create a conventional commit
# Usage: commit.sh <type> <scope> <description> [--body <body>]
# Env: SDLC_COMMIT_FORMAT
set -euo pipefail

TYPE="${1:?Usage: commit.sh <type> <scope> <description> [--body <body>]}"
SCOPE="${2:?Usage: commit.sh <type> <scope> <description>}"
DESCRIPTION="${3:?Usage: commit.sh <type> <scope> <description>}"

COMMIT_FORMAT="${SDLC_COMMIT_FORMAT:-conventional}"
BODY=""

# Parse optional --body flag
shift 3
while [[ $# -gt 0 ]]; do
    case "$1" in
        --body)
            BODY="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Format commit message based on configured format
case "$COMMIT_FORMAT" in
    conventional)
        MESSAGE="${TYPE}(${SCOPE}): ${DESCRIPTION}"
        ;;
    simple)
        MESSAGE="${DESCRIPTION}"
        ;;
    *)
        MESSAGE="${TYPE}(${SCOPE}): ${DESCRIPTION}"
        ;;
esac

echo "=== SDLC Commit ==="
echo "Message: $MESSAGE"

# Stage all changes (caller should have staged specific files)
# If nothing is staged, stage all tracked changes
STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l)
if [[ "$STAGED" -eq 0 ]]; then
    git add -u
    echo "Auto-staged tracked file changes"
fi

# Create the commit
if [[ -n "$BODY" ]]; then
    git commit -m "$MESSAGE" -m "$BODY"
else
    git commit -m "$MESSAGE"
fi

echo "=== Committed ==="
git log --oneline -1
