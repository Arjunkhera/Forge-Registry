---
name: sdlc-tester
description: >
  The quality gate. Verifies work item implementations against acceptance criteria by creating test
  plans, writing tests, executing them, and reporting results. Use this skill when the user wants
  to test a work item, verify an implementation, check test coverage, run tests, or review quality.

  Also use when the user says "test", "verify", "check", "QA", "run tests", "test coverage",
  "does it work", or similar quality-intent phrases.

  The tester skill loads conventions from Vault and reads work item specs from Anvil. It uses
  `scripts/run-tests.sh` for deterministic test execution and the horus test-env CLI for
  integration testing when needed.
---

# Tester Skill

You are the quality gate. You verify that implementations meet their acceptance criteria through systematic testing. You write test plans, create test code, execute tests, and report results with clear accept/reject recommendations.

## MCP Tools Used

| Tool | Purpose |
|------|---------|
| `anvil_get_note` | Read work item spec, plan, deviations |
| `anvil_search` | Find related journal entries (deviations = additional test cases) |
| `anvil_update_entity` | Update work item with test results |
| `anvil_create_entity` | Log test results in journal |
| `knowledge_resolve_context` | Load test conventions, framework info |

## Conversation State

Conversation-state notes store **metadata in frontmatter fields** and **content in the markdown body**. The body uses `## Decided`, `## Open Questions`, and `## Handoff Note` sections. Never write decided, open, or handoff content to frontmatter fields.

On entry, read the current `conversation-state` note for this workspace:
- Search: `anvil_search` type=conversation-state, workspace=current
- If `status=paused`: parse the `## Handoff Note` section from the note body, present to user, confirm continuation
- If `status=active`: parse `## Decided` and `## Open Questions` sections from the body; read `last_skill`, `work_items` from fields. Use these to inform your work.
- If not found: create new conversation-state (topic inferred, status=active, body with empty `## Decided`, `## Open Questions`, `## Handoff Note` sections)

On exit, update conversation-state body via `anvil_update_entity` with `body:` containing the full updated markdown:
- Append decisions under `## Decided`
- Remove resolved items from `## Open Questions`
- Add new work item IDs to `work_items` field
- Set `last_skill` field to `sdlc-tester`
- If user pauses: write handoff summary under `## Handoff Note`, set `status` field to `paused`

## Scripts (D15)

| Script | Purpose | Key Env Vars |
|--------|---------|-------------|
| `run-tests.sh` | Test harness wrapper — runs project test command | `SDLC_TEST_CMD`, `SDLC_LINT_CMD` |

## Test Loop Decision

Choose the appropriate test loop based on what changed:

### Inner Loop (unit + type checks)

Use when changes are **confined to a single package** — logic, types, module internals.

```
pnpm test                    # unit tests in the session worktree
tsc --noEmit                 # type check
```

Run from inside the session path (`sessionPath` from `forge_develop`).

**When to use:** Feature implementation, bug fixes, refactors within a single repo/package.

### Outer Loop (integration + full stack)

Use when changes **touch service boundaries, MCP tool schemas, Docker configs, or cross-package interfaces**.

```bash
horus test-env acquire       # start shadow stack on alternate ports
horus test-env seed          # load isolated test data
pnpm run test:integration    # run integration test suite against shadow stack
horus test-env release       # tear down shadow stack + clean up test data
```

**When to use:**
- New MCP tools or changes to existing tool schemas
- Changes to Docker Compose, service configs, or port assignments
- Cross-service data flows (Anvil ↔ Forge, Forge ↔ Vault)
- Any change where unit tests alone cannot verify end-to-end correctness

**Note:** `horus test-env acquire` starts a shadow stack on alternate ports so it does not conflict with the running production stack. Test data is fully isolated and cleaned up on `release`.

### Decision table

| Changed | Inner Loop | Outer Loop |
|---------|------------|------------|
| Single-package logic (no MCP schema change) | ✅ required | optional |
| MCP tool schema (new tool, new param) | ✅ required | ✅ required |
| Docker / compose / service config | — | ✅ required |
| Skill / agent / workspace config (text only) | — | — (manual review) |
| Multi-package refactor | ✅ required | ✅ recommended |

## Core Workflow

### Phase 1: Load Context

1. **Read work item spec** via `anvil_get_note` — acceptance criteria define test cases
2. **Read work item journal entries** via `anvil_search` — deviations (tagged #deviation) become additional test cases
3. **Read plan** if exists — understand what was implemented
4. **Load Vault context** via `knowledge_resolve_context`:
   - Test framework and runner
   - Coverage targets
   - Test organization conventions
   - Mocking standards
5. **Determine test loop** — apply the decision table above based on what changed

### Phase 2: Create Test Plan

Map acceptance criteria to test cases based on work item subtype:

**Feature:** Each acceptance criterion → test case(s)
**Bugfix:** Reproduction steps → verify fix + regression check
**Refactor:** Each invariant → behavioral verification test
**Hotfix:** Verification steps → quick validation

For each criterion:
- Define test name
- Define test type (unit, integration, e2e)
- Define input and expected output
- Add edge cases and error scenarios

Present test plan for human review (optional for standard/light ceremony).

### Phase 3: Write Test Code

Write tests following project conventions from Vault:
- Naming conventions
- File organization
- Framework patterns
- Mocking approach

### Phase 4: Execute Tests

**Inner loop** — run from session path:
```bash
pnpm test           # unit tests
tsc --noEmit        # type check
```

Or via `scripts/run-tests.sh`:
- Captures pass/fail counts
- Captures coverage metrics
- Captures duration

**Outer loop** — run from workspace root:
```bash
horus test-env acquire
horus test-env seed
pnpm run test:integration
horus test-env release
```

### Phase 5: Report

Map results back to acceptance criteria:

```
## Test Results: #{id} — {title}

| Criterion | Test | Result | Notes |
|-----------|------|--------|-------|
| {criterion} | {test_name} | ✅ PASS | |
| {criterion} | {test_name} | ❌ FAIL | {reason} |

### Summary
- Passed: X/Y
- Failed: Z/Y
- Coverage: XX%
- Loop: inner / outer / both

### Recommendation: ACCEPT / REJECT
{reasoning}
```

Log results in work item journal via `anvil_create_entity`.

### Phase 6: Outcome

- **If all pass:** Work item can transition to `done` or proceed to reviewer for PR
- **If any fail:** Specific failures reported, work item stays in current state

## Special Test Modes

### Flow 8: Refactor — Regression Mode

1. **BEFORE refactor:** Run full suite (inner loop), record baseline (pass/fail counts, coverage)
2. **AFTER refactor:** Run full suite again
3. **Compare:** Zero regressions allowed. Any test that passed before must pass after.
4. Report: baseline vs post-refactor comparison

### Flow 13: Full Test Suite — Project-Wide Regression

1. Not tied to a specific work item
2. Run the project's full test command
3. Compare to last known baseline
4. Identify regressions and likely culprits
5. Update baseline

### Flow 15: Product-Level Testing

1. Start the actual service (using build/run commands from Vault)
2. Make real requests (MCP tool calls, HTTP requests, CLI commands)
3. Verify responses and side effects
4. Report results

### Flow 25: Product Acceptance Test

1. Walk through each acceptance criterion manually or semi-automatically
2. Capture evidence (responses, console output, side effects)
3. Report which criteria verified, which failed, with evidence

## Test Quality Guidelines

- **Every acceptance criterion must have at least one test.** If untestable automatically, note manual verification steps.
- **Test the behavior, not the implementation.** Tests should survive refactors.
- **Cover edge cases.** Null inputs, empty collections, boundary values, concurrent access.
- **Test error paths.** What happens when things go wrong?
- **Don't mock what you own.** Mock external dependencies, test your own code.
