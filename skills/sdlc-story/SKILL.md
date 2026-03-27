---
name: sdlc-story
description: >
  Create and manage work items — the atomic unit of work in the SDLC system. Use this skill when the
  user wants to create a work item, update status, define acceptance criteria, promote a scratch
  to a work item, list work items, view details, block/unblock, or manage lifecycle.

  Also use when the user says "create story", "new story", "new work item", "start story", "move story",
  "story status", "what stories", "promote this to a story", "block story", or similar work-item phrases.

  Work items follow a defined state machine: draft → ready → in_progress → in_review → done, with
  blocked and cancelled as escape states. Each transition is logged. Every work item can have its
  own scratch journal for deviation tracking.
---

# Story Skill (Work Item Manager)

You manage work items — the atomic units of work in the SDLC system. Every piece of implementable work is a work item stored in Anvil (type: `story`). Work items have a subtype that determines their shape, ceremony level, and lifecycle behavior.

## MCP Tools Used

| Tool | Purpose |
|------|---------|
| `anvil_create_note` | Create work items, plans, journal entries |
| `anvil_get_note` | Read work item details |
| `anvil_update_note` | Transition status, update fields, modify body |
| `anvil_search` | Find work items by project, status, subtype |
| `anvil_query_view` | Board views, filtered lists |

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
- Set `last_skill` to `sdlc-story`
- If user pauses: write `handoff_note`, set `status=paused`

## Work Item Subtypes

Each subtype has default ceremony and required sections:

| Subtype | Ceremony | Plan? | Tests? | Review? | Key Sections |
|---------|----------|-------|--------|---------|-------------|
| feature | full | yes | yes | yes | Acceptance Criteria, Technical Notes, Dependencies |
| bugfix | standard | yes | yes | yes | Reproduction, Fix Criteria, Root Cause, Technical Notes |
| refactor | standard | yes | yes | yes | Current State, Target State, Invariants |
| spike | light | no | no | no | Question, Time Box, Approach, Findings, Recommendation |
| hotfix | light | no | yes | no | Issue (Symptom/Impact/Urgency), Fix, Verification, Follow-up |
| task | standard | no | no | no | Deliverables, Technical Notes, Dependencies |
| chore | light | no | no | no | Deliverables |

## State Machine

```
                  ┌────────────────────────────────────────────┐
                  │                                            ▼
draft ──→ ready ──→ in_progress ──→ in_review ──→ done
  │                    │    ▲           │
  │                    ▼    │           │
  │                  blocked            │
  │                                     │
  └──────────────→ cancelled ←──────────┘
```

**Valid transitions:**
- `draft` → `ready` (spec approved)
- `draft` → `cancelled` (abandoned)
- `draft` → `in_progress` (ONLY for types with `can_skip_to: in_progress`: spike, hotfix, chore)
- `ready` → `in_progress` (work begins)
- `ready` → `cancelled`
- `in_progress` → `in_review` (implementation done)
- `in_progress` → `blocked` (dependency or blocker)
- `in_progress` → `cancelled`
- `blocked` → `in_progress` (blocker resolved)
- `blocked` → `cancelled`
- `in_review` → `done` (accepted)
- `in_review` → `in_progress` (rejected, needs rework)
- `in_review` → `cancelled`

Any other transition is invalid. If the user requests one, explain the valid options.

## Operations

### `create` — Create a New Work Item

1. **Determine the project:** Which project does this belong to? If ambiguous, ask.

2. **Determine the subtype:** What kind of work is this? Map user intent:
   - "I want to build X" → `feature`
   - "There's a bug..." → `bugfix`
   - "Clean up / restructure..." → `refactor`
   - "Can we try / is it possible..." → `spike`
   - "Production is broken..." → `hotfix`
   - "We need to do X (non-code)" → `task`
   - "Routine maintenance..." → `chore`

3. **Set ceremony level:** Use the subtype's default, or escalate/demote if the user indicates.

4. **Gather work item details based on subtype sections:**
   - Title (concise, action-oriented)
   - Description (what and why)
   - Subtype-specific sections (see table above)
   - Priority (P0-P3, default P2-medium)
   - Dependencies (other work item IDs)

5. **Create in Anvil** via `anvil_create_note`:
   - Type: `story`
   - Fields: subtype, ceremony, status=draft (or in_progress for can_skip_to types), priority, project reference
   - Body: subtype-specific sections + History table
   - Tags: project name, subtype

6. **Confirm** creation with ID, title, subtype, ceremony, and status.

### `transition` — Change Work Item Status

1. **Validate the transition** against the state machine
2. **Update via `anvil_update_note`:** Change status field, append to History table in body
3. **Log in journal:** Create a journal entry via `anvil_create_note` noting the transition and reason
4. **Trigger downstream actions** based on new state:
   - `in_progress` → Inform user the developer skill can pick this up
   - `in_review` → Inform user the tester skill can verify this
   - `done` → Inform user the docs skill should check documentation
   - `blocked` → Ask for blocker reason, suggest creating a sub-item for the blocker

### `block` — Mark as Blocked (Flow 23)

1. Transition status to `blocked` via `anvil_update_note`
2. Record blocker reason in work item body
3. Create journal entry with `#blocker` tag
4. If resolvable: suggest creating a new work item for the blocker itself
5. Suggest pausing Forge workspace via `forge_workspace_list` / pause
6. Recommend next work via orchestrator

### `list` — List Work Items for a Project

Call `anvil_query_view` with appropriate filters:
- By project: `filter: { type: "story", project: "{id}" }`
- Board format: `format: "board"`, `groupBy: "status"`
- Table format: `format: "table"`, `columns: ["title", "subtype", "status", "priority"]`

### `detail` — View Full Work Item Details

1. Read via `anvil_get_note`
2. Query related plans via `anvil_search` with type `plan` and work_item reference
3. Query related journal entries
4. Present: full spec, plan status, recent journal entries, dependencies

### `scope-change` — Handle Mid-Flight Scope Change (Flow 9)

1. Log scope change in journal with `#scope-change` tag via `anvil_create_note`
2. Update work item body with new/changed criteria via `anvil_update_note`
3. Note changes in History table
4. If plan exists: developer skill revises plan (version bump)
5. If scope grew significantly: suggest splitting into new work item

## Body Content Templates by Subtype

**Feature:**
```
## Acceptance Criteria
- [ ] {criterion_1}
- [ ] {criterion_2}

## Technical Notes
{notes}

## Dependencies
- {dependency}

## History
| Date | From | To | By | Notes |
|------|------|----|----|-------|
```

**Bugfix:**
```
## Reproduction
1. {step}
2. {step}
Expected: {expected}
Actual: {actual}

## Fix Criteria
- [ ] {criterion}

## Root Cause
{to be filled after investigation}

## Technical Notes
{notes}

## Dependencies
- {dependency}

## History
| Date | From | To | By | Notes |
```

**Refactor:**
```
## Current State
{description of the code/structure as it is}

## Target State
{what we want it to become}

## Invariants
- {invariant_1}
- {invariant_2}

## Technical Notes
{notes}

## History
| Date | From | To | By | Notes |
```

**Spike:**
```
## Question
{what are we trying to learn?}

## Time Box
{duration}

## Approach
{how will we investigate?}

## Findings
{to be filled during spike}

## Recommendation
{promote to feature / abandon / needs more investigation}

## History
| Date | From | To | By | Notes |
```

**Hotfix:**
```
## Issue
- **Symptom:** {what's broken}
- **Impact:** {who/what is affected}
- **Urgency:** {why it needs immediate attention}

## Fix
{description of the fix}

## Verification
- [ ] {verification step}

## Follow-up
- [ ] Create bugfix for proper root cause (if band-aid)

## History
| Date | From | To | By | Notes |
```

**Task:**
```
## Deliverables
- [ ] {deliverable_1}
- [ ] {deliverable_2}

## Technical Notes
{notes}

## Dependencies
- {dependency}

## History
| Date | From | To | By | Notes |
```

**Chore:**
```
## Deliverables
- [ ] {deliverable_1}
- [ ] {deliverable_2}

## History
| Date | From | To | By | Notes |
```
