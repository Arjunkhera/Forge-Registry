#!/usr/bin/env bash
# run-tests.sh — Run the project's test suite
# Usage: run-tests.sh [--lint] [--coverage]
# Env: SDLC_TEST_CMD, SDLC_LINT_CMD
set -euo pipefail

TEST_CMD="${SDLC_TEST_CMD:-}"
LINT_CMD="${SDLC_LINT_CMD:-}"
RUN_LINT=false
RUN_COVERAGE=false

# Parse flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        --lint)
            RUN_LINT=true
            shift
            ;;
        --coverage)
            RUN_COVERAGE=true
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

EXIT_CODE=0

echo "=== SDLC Test Runner ==="

# Run linter first if requested
if [[ "$RUN_LINT" == "true" ]]; then
    if [[ -n "$LINT_CMD" ]]; then
        echo "--- Running linter: $LINT_CMD ---"
        if eval "$LINT_CMD"; then
            echo "✅ Lint passed"
        else
            echo "❌ Lint failed"
            EXIT_CODE=1
        fi
    else
        echo "⚠️  No SDLC_LINT_CMD configured, skipping lint"
    fi
fi

# Run tests
if [[ -n "$TEST_CMD" ]]; then
    echo "--- Running tests: $TEST_CMD ---"

    # Add coverage flag if supported and requested
    FULL_CMD="$TEST_CMD"
    if [[ "$RUN_COVERAGE" == "true" ]]; then
        # Attempt to add coverage flags based on common test runners
        case "$TEST_CMD" in
            *pytest*)
                FULL_CMD="$TEST_CMD --cov --cov-report=term-missing"
                ;;
            *jest*)
                FULL_CMD="$TEST_CMD --coverage"
                ;;
            *vitest*)
                FULL_CMD="$TEST_CMD --coverage"
                ;;
            *)
                FULL_CMD="$TEST_CMD"
                echo "⚠️  Coverage flag not auto-detected for this test runner"
                ;;
        esac
    fi

    echo "Command: $FULL_CMD"
    if eval "$FULL_CMD"; then
        echo "✅ Tests passed"
    else
        echo "❌ Tests failed"
        EXIT_CODE=1
    fi
else
    echo "⚠️  No SDLC_TEST_CMD configured"
    echo "Set SDLC_TEST_CMD in your workspace config or Vault repo profile"
    EXIT_CODE=1
fi

echo "=== Test run complete (exit code: $EXIT_CODE) ==="
exit $EXIT_CODE
