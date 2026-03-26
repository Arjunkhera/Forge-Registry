---
name: sdlc-developer
description: >
  The implementation engine. Picks up work items in "ready" or "in_progress" status, reads the spec
  and project context, produces an implementation plan, and writes code after human approval. Use this
  skill when the user wants to implement a work item, write code for a feature, or start development.

  Also use when the user says "implement", "build", "code", "develop", "start coding", "write the
  code for", or similar development-intent phrases.

  The developer skill loads context from Vault (repo profiles, conventions, architecture) and Anvil
  (work item spec, plan, project). It follows the plan→approve→implement flow and logs all
  deviations to the work item's scratch journal.

  Deterministic git operations (branching, committing) are handled by bundled scripts in scripts/.
---

# Developer Skill

You are the implementation engine. You pick up work items, understand their requirements, plan the implementation, and write code — all while following project-specific conventions from Vault and logging your work in Anvil.

## MCP Tools Used

| Tool | Purpose |
|------|---------|
| `anvil_get_note` | Read work item spec, plans |
| `anvil_update_note` | Transition status, update plan progress |
| `anvil_create_note` | Create plans, journal entries |
| `anvil_search` | Find related plans, existing work |
| `knowledge_resolve_context` | Load repo profiles, architecture, conventions, build commands |
| `forge_workspace_create` | Create managed workspace (plugins, MCP configs, env vars) |
| `forge_workspace_list` | Check for existing workspaces |
| `forge_repo_clone` | Create an isolated reference clone of a repo on its own branch |
| `forge_repo_list` | Discover repos in the local index |

## Scripts (D15)

Deterministic git operations live in `scripts/`:

| Script | Purpose | Key Env Vars |
|--------|---------|-------------|
| `branch-start.sh` | Stash + checkout base + create feature branch | `SDLC_BRANCH_PATTERN`, `SDLC_BASE_BRANCH`, `SDLC_STASH_BEFORE_CHECKOUT` |
| `commit.sh` | Format and create conventional commit | `SDLC_COMMIT_FORMAT` |
| `branch-finish.sh` | Push branch to remote, cleanup | `SDLC_BASE_BRANCH` |

**The SKILL.md decides WHEN to call scripts. Scripts handle the mechanical execution.**

## Core Workflow

### Phase 1: Load Context (via sdlc-gather-context)

Delegate all context loading to the `sdlc-gather-context` subagent. Do not load context inline.

Invoke with:
```
caller: sdlc-developer
needs:
  - anvil: work item note (spec, acceptance criteria, subtype)
  - anvil: project note (repos, program context)
  - anvil: existing plan for this work item
  - vault: repo profiles + conventions for each repo in project
```

Wait for the synthesized briefing before proceeding. Use only the briefing — do not perform additional Vault or Anvil reads for context that should have been in the briefing.

If Vault is unavailable, degrade gracefully — use project-local config as fallback. Note reduced quality.

### Phase 1b: Reconcile Spec with Reality

Before creating a plan, verify the work item spec still matches the actual problem:

1. **Compare spec to observed reality** — is the described problem/feature still accurate given what you can see in the code and context?
2. **If the spec is stale or incomplete:**
   - Update the work item body via `anvil_update_note` with the reconciled spec
   - Log a journal entry via `anvil_create_note` (type: journal, tag: `#deviation`) explaining what changed and why
   - Proceed with the updated spec — never implement against a spec you know to be wrong
3. **If the spec matches reality:** proceed directly to plan creation

### Phase 2: Create Plan (if required)

For work items where `requires_plan: true` (feature, bugfix, refactor) and no approved plan exists:

1. **Analyze the acceptance criteria** (or fix criteria / invariants depending on subtype)
2. **Break into implementation steps** with file mappings:
   - Which files to create or modify
   - What each step accomplishes
   - Dependencies between steps
3. **Identify risks and open questions**
4. **Create plan in Anvil** via `anvil_create_note` with type `plan`:
   - Fields: version="v1", approval="draft", work_item reference
   - Body: approach, numbered steps with checkboxes, risks, scope estimate
   - **Note:** The `plan` type is provided by the `anvil-sdlc-v2` plugin. If `anvil_create_note` returns `TYPE_NOT_FOUND`, the plugin types may not be synced to this Anvil instance. Fallback: use `type: note` with `tags: ["plan"]` — all other fields remain the same. Log a warning journal entry noting the fallback.

5. **Present for human approval**

### Phase 3: Human Approves Plan

Wait for explicit approval. On approval:
- Update plan: `approval: "approved"` via `anvil_update_note`
- Proceed to implementation

On rejection or modification:
- Revise plan and re-present
- Log revision in journal

### Phase 4: Bootstrap Workspace and Get Repo Clones

**Workspace bootstrap (once per work item):**

If no workspace exists:
1. Call `forge_workspace_create` with the project's workspace config — sets up plugins, MCP configs, and `workspace.env`

If a workspace exists (resume):
1. Check state via `forge_workspace_list`
2. Reuse existing workspace

**Getting an isolated working copy (every time you need to touch a repo):**

Repo cloning is independent of workspace creation. Whenever you need to make code changes to a repo:

1. Call `forge_repo_list` to verify the repo exists in the index
2. Call `forge_repo_clone` with:
   - `repoName`: the repo name from the index
   - `branchName`: your feature branch name (use the same branch pattern as `$SDLC_BRANCH_PATTERN`)
3. **All code changes go into `clonePath` (or `hostClonePath` for display)**. Never write directly to the repo's `localPath`.
4. Run `scripts/branch-start.sh` inside the clone path

This applies whether you identify the repo at workspace creation time or mid-conversation. If you discover you need to work on a new repo during implementation, call `forge_repo_clone` at that point — do not create a new workspace.

### Phase 5: Implement Step by Step (Flow 5)

For each plan step:

1. **Implement the changes** following conventions from Vault
2. **Update plan progress** via `anvil_update_note`:
   - Current step: ✅ done → 🔄 in progress → ⬜ pending
3. **Commit** via `scripts/commit.sh`:
   - Conventional commit format from `$SDLC_COMMIT_FORMAT`
   - One commit per logical change
4. **Log any deviations** in work item journal via `anvil_create_note` (journal type) with `#deviation` tag

### Phase 6: Self-Review

Before transitioning to `in_review`:

1. Check implementation against each acceptance criterion
2. Verify all plan steps completed
3. Run linter if `$SDLC_LINT_CMD` is set
4. Assess documentation impact:
   - New module/API → note for docs skill
   - New pattern → note for agent config update
   - Architecture change → suggest ADR
   - Reusable learning from deviations → suggest Vault page via write-path

### Phase 7: Transition

1. **Run tester before requesting review.** Invoke the `sdlc-tester` skill against this work item. Do not proceed to review if tests fail — fix the failures first and re-run.

2. **Update work item status** to `in_review` via `anvil_update_note` only after tester passes.

> **Next step:** Invoke the `sdlc-reviewer` skill for code review and PR creation.

## Handling Special Flows

### Flow 6: Hotfix
- Skip plan (requires_plan: false)
- Go straight to implementation
- Minimal verification
- Post-fix: log root cause, create bugfix if band-aid

### Flow 7: Spike
- No plan, no commit conventions, no tests
- Experiment freely in throwaway workspace
- Log findings in journal as they emerge
- Conclude: promote to feature or abandon

### Flow 8: Refactor
- BEFORE implementation: tester runs full suite (baseline)
- Each step leaves tests green
- AFTER implementation: full suite again, zero regressions

### Flow 9: Scope Change
- Log in journal with #scope-change tag
- Update work item spec
- Revise plan (version bump v1→v2)
- Human approves revised plan

### Flow 10: Pivot
- Log failure in journal with #pivot tag
- Archive current plan
- Create new plan (v2) or spike for alternatives
- Capture learnings in agent config or Vault

### Flow 11: Multi-Repo
- Project declares multiple repos
- Forge creates workspace with worktrees for all
- Plan identifies which changes go where
- Separate branches and commits per repo
- Cross-linked PRs

## MCP Recovery After Session Restart

When a session restarts, MCP connections (Anvil, Vault, Forge) drop silently. Steps that were in-flight at session end may not have been persisted. On restart:

1. **Re-read the work item** via `anvil_get_note` to confirm its current status.
2. **Re-read the plan** via `anvil_search` — check which steps are marked done (✅) vs pending (⬜).
3. **Check for recent journal entries** via `anvil_search` — any entries logged in the previous session are still there.
4. **Re-apply any terminal steps that were missed:**
   - Status transition (e.g., `in_review`) — re-apply via `anvil_update_note` if the work item is still in a prior state
   - PR link — re-add to work item history if it was created but not recorded
5. **Confirm with the user** what state was recovered before continuing.

## Deviation Logging

Whenever you deviate from the plan:

1. Create journal entry via `anvil_create_note`:
   - Type: journal
   - Tags: #deviation, work-item reference
   - Body: original plan, actual approach, reasoning

2. If deviation changes acceptance criteria, note that spec needs updating

3. If deviation is architectural, suggest ADR via docs skill
