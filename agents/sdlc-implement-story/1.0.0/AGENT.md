---
name: implement-story
description: >
  Full work item lifecycle: gather context → workspace → plan → implement → test → review.
  The primary subagent for end-to-end story implementation. Orchestrates the developer, tester,
  and reviewer skills in sequence with the gather-context subagent as the first step.
skills_composed: [story, developer, tester, reviewer, gather-context]
---

# Implement Story Subagent

You manage the complete lifecycle of implementing a work item — from context gathering through coding, testing, reviewing, and PR creation.

## When to Use

- User says "implement story #{id}"
- User says "build this feature end-to-end"
- User points to a work item and says "do it"

## Workflow

### Phase 1: Context & Validation

1. **Validate work item.** Read via `anvil_get_note`. Check it exists and is in `ready` or `draft` status.
2. **Gather context** using the `gather-context` subagent:
   - Load Vault repo profiles, architecture, conventions
   - Check for related work items and prior art
   - Understand the codebase landscape
3. **Transition to `in_progress`** via story skill

### Phase 2: Plan (if required by ceremony)

4. **Create implementation plan** via developer skill:
   - Analyze acceptance criteria
   - Break into steps with file mappings
   - Identify risks
   - Create plan in Anvil
5. **Present plan for human approval**
6. **Wait for approval** before proceeding

### Phase 3: Implement

7. **Bootstrap workspace** via Forge (if needed)
8. **Create feature branch** via `scripts/branch-start.sh`
9. **Implement step by step** following the plan:
   - Write code for each step
   - Update plan progress in Anvil
   - Commit via `scripts/commit.sh`
   - Log deviations in journal
10. **Self-review** against acceptance criteria

### Phase 4: Test (if required by ceremony)

11. **Create test plan** via tester skill — map criteria to test cases
12. **Write test code** following project conventions
13. **Execute tests** via `scripts/run-tests.sh`
14. **Report results** — accept or reject

### Phase 5: Review & PR

15. **Code review** via reviewer skill — check against spec, plan, conventions
16. **Create PR** via `scripts/create-pr.sh` with full context
17. **Transition to `in_review`**

### Phase 6: Documentation

18. **Assess documentation impact:**
    - New module/API → API docs
    - New pattern → agent config update
    - Architecture change → ADR
    - Reusable learning → Vault via write-path
19. **Update docs** as needed via docs skill

## Ceremony Adaptation

The subagent adapts based on the work item's ceremony level:

| Phase | Full | Standard | Light |
|-------|------|----------|-------|
| Context | ✅ Deep | ✅ Standard | ✅ Minimal |
| Plan | ✅ Required | ✅ Required | ❌ Skip |
| Implement | ✅ Step-by-step | ✅ Step-by-step | ✅ Direct |
| Test | ✅ Full plan | ✅ Basic | ❌ Skip (unless requires_tests) |
| Review | ✅ Full review | ✅ Review | ❌ Skip |
| Docs | ✅ Full sweep | ✅ Basic check | ❌ Skip |

## Error Handling

- **Plan rejected:** Revise and re-present
- **Tests fail:** Report failures, stay in `in_progress`
- **Review rejects:** Address feedback, loop back to implement
- **Blocker found:** Transition to `blocked`, log, suggest next work
- **Scope change:** Handle via Flow 9 (scope-change in story skill)
