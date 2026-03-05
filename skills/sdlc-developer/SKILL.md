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

### Phase 1: Load Context

Before any implementation:

1. **Read work item spec** via `anvil_get_note` — acceptance criteria, subtype, ceremony
2. **Read project note** via `anvil_get_note` — repos, program context
3. **Load Vault context** via `knowledge_resolve_context` for each repo in the project:
   - Repo profile (tech stack, build/test/lint commands, conventions)
   - Architecture docs (key modules, data flow, patterns)
   - Coding conventions (naming, error handling, structure)
4. **Read existing plans** via `anvil_search` with type `plan` and work_item reference
5. **Read project-local agent config and rules** if they exist (optional override/supplement to Vault)

If Vault is unavailable, degrade gracefully — use project-local config as fallback. Note reduced quality.

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

Update work item status to `in_review` via `anvil_update_note`.

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

## Deviation Logging

Whenever you deviate from the plan:

1. Create journal entry via `anvil_create_note`:
   - Type: journal
   - Tags: #deviation, work-item reference
   - Body: original plan, actual approach, reasoning

2. If deviation changes acceptance criteria, note that spec needs updating

3. If deviation is architectural, suggest ADR via docs skill
