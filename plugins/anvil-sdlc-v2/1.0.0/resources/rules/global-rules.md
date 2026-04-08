# Global Development Rules — SDLC v2

These rules are inherited by all projects unless overridden by project-specific agent config or rules.

## Core Principles

1. **All state lives in Anvil.** Work items, plans, scratch journals, project configs — everything is an Anvil note type, queried via MCP. Do not create local flat files for tracking state.

2. **Spec before code.** Never start implementation without approved acceptance criteria in the work item. The ceremony level determines how formal the spec needs to be.

3. **Plan before implement.** For work items where `requires_plan: true`, the developer skill must produce a plan in Anvil (type: `plan`) and get human approval before writing code. Plans are first-class persisted artifacts — they enable resume capability.

4. **Log deviations.** Any change from the original spec or plan must be logged in the work item's scratch journal (Anvil journal type) with `#deviation` tag and reasoning.

5. **Test what you build.** For work items where `requires_tests: true`, tests must verify acceptance criteria. The tester skill maps each criterion to test cases.

6. **Document decisions.** Significant architectural choices get an ADR. Reusable learnings get proposed to Vault via the write-path pipeline.

7. **Ceremony is a default, not a constraint.** Escalate or demote ceremony levels as the situation warrants. A trivial feature can use standard ceremony. A complex bugfix can use full ceremony.

## Code Quality

1. Write clear, self-documenting code. Comments explain "why", not "what".
2. Follow the project's established patterns (from Vault repo profile and project agent config).
3. Handle errors explicitly — no silent failures.
4. Keep functions small and focused on a single responsibility.

## Git Conventions

1. One commit per logical change.
2. Commit messages follow conventional commits: `{type}({scope}): {description}`
3. Types: feat, fix, refactor, test, docs, chore
4. Branch naming follows `$SDLC_BRANCH_PATTERN` (default: `{subtype}/{id}-{slug}`)
5. Use the skill scripts (`branch-start.sh`, `commit.sh`, `branch-finish.sh`) for deterministic git operations.

## Review Checklist

Before transitioning a work item to `in_review`:
- All acceptance criteria met
- Tests pass (run via `scripts/run-tests.sh`)
- No linter errors
- Work item scratch updated with any deviations
- Plan fully completed (all steps marked done)
- Documentation updated where relevant

## Context Resolution

Skills should always attempt to load context from Vault before starting work:
- `knowledge_resolve_context` for repo profiles, architecture docs, conventions
- If Vault is unavailable, degrade gracefully — use project-local agent config and rules as fallback
- Never hardcode paths or conventions that should come from Vault
