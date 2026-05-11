---
name: sdlc-keystone-update
description: >
  Rewrites a Horus keystone project page in Anvil to conform to the standard template.
  Re-sorts the work item tracker (in-progress first, done last, priority-ordered within
  each group) and ensures all required sections are present.

  Use when: a keystone page has drifted from the template, stories have changed status,
  a phase has advanced, or the project scope has changed.
  Trigger phrases: "update the keystone for X", "reformat the Forge V3 page",
  "re-sort the tracker for Horus UI", "bring this project page up to template",
  "keystone is out of date", "sync the project page".
---

# sdlc-keystone-update

Reads a Horus keystone project page from Anvil, applies the standard template, re-sorts
the work item tracker, and saves the result back via `anvil_update_entity`.

## Input

One of:
- Project name (e.g. "Forge V3", "Horus UI")
- Project Anvil note ID (UUID)

## Process

### 1. Resolve the project note
- Name given → `anvil_search` with `type: project` and name as query. Take the top match.
- ID given → `anvil_get_note` directly.

### 2. Read the template
Read Anvil note `df98e5da` — [[Horus Keystone Project Page — Template & Authoring Guide]].
This is the authoritative source for section names, formatting rules, and sort order.
Re-read it if anything is uncertain — do not rely on memory.

### 3. Fetch current work items
Call `anvil_query_view`:
```
view: "list"
filters: { type: "story", project: "<noteId>" }
```
Capture per story: `title`, `status`, `priority`, `noteId`, `modified`.

### 4. Sort work items

**Active block (top of tracker):**
1. `in-progress` — by priority (P0 → P1 → P2 → P3)
2. `open` / `ready` — by priority
3. `blocked` — by priority

**Separator row:** `| — | — | — | — |`

**Done block (bottom):**
4. `done` — most recent first (by `modified` desc)
5. `cancelled` — after done

### 5. Rebuild the note body

Rewrite all required sections using the fetched project data and sorted work items:

| Section | Rule |
|---------|------|
| **What is this?** | Preserve if ≤2 sentences and clear. Flag if missing or bloated. |
| **Repositories** | Preserve existing rows. Flag if section is missing entirely. |
| **Current Phase** | Preserve. Flag if vague (e.g. just "design phase" with no next step). |
| **Phases** | Preserve table structure. Update status icons from story statuses. |
| **Work Item Tracker** | Rebuild entirely from fetched + sorted stories. |
| **Resources** | Preserve. Flag if empty. |

**Never invent content.** Write `[TODO: fill in]` for missing sections and list them
in the output summary.

**Never delete existing content.** If rich content doesn't fit the template cleanly,
preserve it under the correct heading rather than cutting it.

### 6. Save
Call `anvil_update_entity` with the `noteId` and the rewritten body content.

## Output

Report back:
- Which sections were updated vs preserved
- Number of work items re-sorted, and their final order
- List of `[TODO]` items that need human input

## Edge Cases

- **No stories yet:** Leave tracker with one placeholder row (`[TODO: add stories]`), note in output.
- **Project not found by name:** Report candidates from search and ask user to confirm.
- **Template note unavailable:** Halt and report — do not proceed without the template.
