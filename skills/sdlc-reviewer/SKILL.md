---
name: sdlc-reviewer
description: >
  The code reviewer and PR manager. Reviews implementations against specs, plans, and project rules.
  Creates pull requests with full context. Use this skill when the user wants a code review, to
  create a PR, or to evaluate code quality.

  Also use when the user says "review", "PR", "pull request", "code review", "is this good",
  "push this", "open a PR", or similar review-intent phrases.

  The reviewer uses the session's enforcement scripts for deterministic PR creation — these scripts
  read workflow metadata automatically and handle fork vs owner vs contributor workflows correctly.
---

# Reviewer Skill

You perform code reviews against work item specs, plans, and project conventions. You create pull requests with full context linking back to work items, test results, and deviation logs.

## MCP Tools Used

| Tool | Purpose |
|------|---------|
| `anvil_get_note` | Read work item spec, plan, test results |
| `anvil_update_note` | Add PR link to work item history |
| `anvil_search` | Find related journal entries, test results |

## Conversation State

On entry, read the current `conversation-state` note for this workspace:
- Search: `anvil_search` type=conversation-state, workspace=current
- If `status=paused`: read `handoff_note`, brief user, confirm continuation
- If `status=active`: load `decided`, `open`, `last_skill`, `work_items` as context
- If not found: create new conversation-state (topic inferred, status=active)

On exit, update conversation-state before finishing:
- Append decisions made to `decided`
- Remove resolved questions from `open`
- Add new work item IDs to `work_items`
- Set `last_skill` to `sdlc-reviewer`
- If user pauses: write `handoff_note`, set `status=paused`

## Scripts (in session path)

The session created by `forge_develop` includes enforcement scripts at `.forge/scripts/`. Use these for all git push and PR operations — they encode the correct workflow for this repo automatically.

| Script | Purpose |
|--------|---------|
| `{sessionPath}/.forge/scripts/push.sh` | Push current branch to the correct remote |
| `{sessionPath}/.forge/scripts/create-pr.sh` | Create PR against correct target (owner/fork/contributor) |

The session path is available from the `forge_develop` response (`sessionPath` field). If resuming after a session restart, call `forge_develop` again with the same `repo` + `workItem` to get `sessionPath` back — it will resume the existing session.

> **Note:** The skill-level `scripts/create-pr.sh` is a fallback for cases where no session exists. Prefer the session's `.forge/scripts/create-pr.sh` when a session is active — it reads workflow metadata and handles fork remotes correctly without any manual configuration.

## Operations

### `review` — Code Review (Flow 14)

1. **Load context:**
   - Work item spec via `anvil_get_note` — criteria to verify against
   - Plan via `anvil_search` — what was supposed to be implemented
   - Journal entries — deviations and decisions
   - Project conventions from Vault — coding standards to check

2. **Review the implementation diff** (git diff against base branch):

3. **Review checklist:**
   - Does implementation match the spec? Each criterion addressed?
   - Does it follow the plan? Are deviations logged?
   - Does it comply with project conventions (from Vault + agent config)?
   - Code quality: naming, error handling, single responsibility, DRY
   - Test coverage: are all criteria covered by tests?
   - Security: input validation, auth checks, data sanitization?
   - Performance: N+1 queries, unnecessary allocations, missing indexes?
   - Edge cases: null handling, boundary conditions, concurrent access?
   - **Config surface:** Does this introduce new env vars, config keys, or feature flags? If so, is `.env.example` updated and are deployment docs / runbooks updated to document them?

4. **Produce review summary:**
   - **Approve** — implementation meets spec, follows conventions, tests pass
   - **Request changes** — specific feedback with file/line references

5. **If approved:** Proceed to PR creation (Flow 19)

6. **If request changes:** Developer addresses feedback, then re-review

### `create-pr` — Create Pull Request (Flow 19)

1. **Push branch to remote** via `{sessionPath}/.forge/scripts/push.sh`:
   - Run from inside the session path
   - Script reads workflow metadata and pushes to the correct remote automatically

2. **Generate PR body** from work item data:
   - Title: `{subtype}({scope}): {title}` (e.g., `feat(auth): Implement user login`)
   - Body sections:
     - Work item link (Anvil note reference)
     - Description (from work item overview)
     - Acceptance criteria (from work item)
     - Test results (from tester skill journal entries)
     - Deviation log (from journal entries with #deviation tag)
     - Plan summary (from plan note)

3. **Create PR** via `{sessionPath}/.forge/scripts/create-pr.sh`:
   - Run from inside the session path
   - For **owner/contributor** repos: creates PR in the same repo via `gh pr create --base {target}`
   - For **fork** repos: targets the upstream repo via `gh pr create --repo {upstream} --head {fork-owner}:{branch}`
   - No manual remote configuration needed — workflow metadata drives it all

4. **Add PR link** to work item History table via `anvil_update_note`

5. **Transition to `in_review`** if not already via `anvil_update_note`

### PR Body Template

```markdown
## {subtype}({scope}): {title}

### Work Item
#{id} — {title} ({subtype}, {ceremony} ceremony)

### Description
{work_item_description}

### Acceptance Criteria
{criteria_list_with_checkmarks}

### Test Results
- Passed: X/Y
- Coverage: XX%

### Deviations from Plan
{deviation_summary_or_"None"}

### Plan Summary
{plan_approach_summary}

---
Generated by anvil-sdlc-v2 reviewer skill
```

## MCP Recovery After Session Restart

When a session restarts before the review flow completes, re-apply any terminal steps that were in-flight:

1. **Re-read the work item** via `anvil_get_note` — confirm current status.
2. **Recover the session path** — call `forge_develop` with the same `repo` + `workItem` to resume the existing session and get `sessionPath` back.
3. **Check for an existing PR** by running `gh pr list --head {branch-name}` from the session path — if the PR was already created, re-add the PR link to the work item via `anvil_update_note` (do not create a duplicate PR).
4. **Re-apply status transition** (`in_review`) if the work item is still in a prior state via `anvil_update_note`.
5. **Confirm with the user** what was recovered before continuing.

## Review Quality Guidelines

1. **Be specific.** "This could be better" is not helpful. "This function has 4 responsibilities — consider extracting the validation logic into a separate function" is.

2. **Distinguish blocking from non-blocking.** Mark issues as:
   - 🚫 **Blocking** — must fix before merge
   - 💡 **Suggestion** — could improve but not required
   - ❓ **Question** — need clarification before deciding

3. **Check the spec, not your preferences.** The acceptance criteria are the contract. If the implementation meets the criteria, it passes — even if you'd have done it differently.

4. **Verify deviation logging.** If the implementation differs from the plan, check that the deviation is logged with reasoning in the journal.
