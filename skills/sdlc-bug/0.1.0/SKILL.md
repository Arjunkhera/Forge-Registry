---
name: sdlc-bug
description: >
  Reports and tracks bugs in Anvil using the "bug" type, moving them through a
  structured lifecycle: open → investigating → fix-ready → in-progress → fixed →
  verified (or wont-fix). Each bug has 9 independently updatable sections.

  Use when: logging a new bug, updating root cause findings, recording a fix,
  verifying a fix worked, or closing a bug as won't-fix.
  Trigger phrases: "log a bug", "report a bug in X", "file a bug for X",
  "update root cause for X", "mark X as fixed", "add fix details for X",
  "verify the fix for X", "close X as won't fix", "what's the status of bug X",
  "move X to investigating".
---

# sdlc-bug

Reports and tracks bugs in Anvil through their full lifecycle — from first observation
to verified fix (or explicit won't-fix). Nine independently updatable sections keep
each stage of the investigation clean and navigable.

## Input

One of:
- Bug title + description → **report** a new bug
- Bug title or note ID + section name + content → **update** a section
- Bug title + new status → **advance** lifecycle status
- Bug title only → **read** current state

## Anvil Note Type

Use type `bug`. Call `anvil_list_types` first to confirm it exists.
If absent, call `anvil_create_type` (see Edge Cases).

## Process

### 1. Resolve Mode

Search: `anvil_search(query: "{title}", type: "bug")`.

| Result | Content | Mode |
|--------|---------|------|
| No match | — | **Report** |
| Match + section + content | Yes | **Update section** |
| Match + new status | — | **Advance status** |
| Match | Nothing | **Read** |

### 2. Report (Create)

Ask for severity if not provided — default `medium`. Then:

```
anvil_create_entity(
  type: "bug",
  title: "{Bug Title}",
  fields: {
    type: "bug",
    severity: "medium",
    status: "open"
  },
  body: <full template below>
)
```

Optionally link to a parent project:
```
anvil_create_edge(sourceId: "<project-id>", targetId: "<bug-id>", intent: "parent_of")
```

### 3. Update Section

Each section has a stable H2 header. To update one:
1. `anvil_get_note` → read full body
2. Locate section by its H2 header
3. Replace that section's content only
4. `anvil_update_entity(noteId: "...", body: <revised body>)`

**Stable section headers — never rename:**
- `## Summary`
- `## Environment`
- `## Steps to Reproduce`
- `## Expected`
- `## Actual`
- `## Impact`
- `## Root Cause`
- `## Fix`
- `## Verification`

**Common update patterns:**
| User says | Section to update | Also advance to |
|-----------|------------------|-----------------|
| "root cause is X" | Root Cause | `investigating` or `fix-ready` |
| "fix is X, PR is Y" | Fix | `in-progress` or `fixed` |
| "verified — works" | Verification | `verified` |
| "won't fix because X" | Root Cause | `wont-fix` |

### 4. Advance Status

```
anvil_update_entity(
  noteId: "...",
  fields: { type: "bug", status: "fixed" }
)
```

Also update the `> **Severity:** … | **Status:** …` header line in the body to match.

**Lifecycle:**
```
open → investigating → fix-ready → in-progress → fixed → verified
                                                        ↘ wont-fix (from any active state)
```

**Won't fix:** Add rationale to the Root Cause section before closing.
Never delete content when closing — the investigation record is valuable.

## Template

Use this body exactly when creating a new bug:

```markdown
> **Severity:** Medium | **Status:** Open

## Summary
[TODO: one-line description — what goes wrong]

## Environment
- **Component:** [TODO: which part of the system]
- **Version / Branch:** [TODO]
- **Runtime / OS:** [TODO]
- **Reproducibility:** always / sometimes / once

## Steps to Reproduce
1. [TODO]
2.
3.

## Expected
[TODO: what should happen]

## Actual
[TODO: what actually happens instead]

## Impact
**Who is affected:** [TODO]
**Workaround:** [TODO or none]

## Root Cause
[TODO: fill in during investigation — what in the code causes this]

## Fix
**PR / Branch:** [TODO]

[TODO: describe what was changed and why]

## Verification
- [ ] [TODO: step to confirm the fix works]
- [ ] Regression — existing behaviour not broken
```

## Severity Guide

| Severity | When to use |
|----------|------------|
| `critical` | System down, data loss, security vulnerability, no workaround |
| `high` | Major feature broken, no usable workaround |
| `medium` | Feature impaired, workaround exists |
| `low` | Cosmetic, minor inconvenience, edge case |

## Output

Report: bug title, severity, current status, what was created or updated, what
section needs attention next.

## Edge Cases

- **Type `bug` missing:** `anvil_list_types` → `anvil_create_type` if absent.
- **Bug not found by title:** List search candidates, ask user to confirm.
- **Duplicate bug:** If a very similar bug exists, surface it and ask whether to
  update the existing one or file a new report.
- **Severity not provided:** Default to `medium`, note it in output so user can
  correct if needed.
