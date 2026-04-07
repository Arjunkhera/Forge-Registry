---
name: sdlc-scratch
description: >
  Capture thoughts, ideas, decisions, research, and conversations as append-only journal entries.
  Use this skill whenever the user wants to log a thought, jot down an idea, capture a decision,
  record a conversation outcome, or generally "write something down" that isn't yet a work item or
  formal document. Also use when the user says "scratch", "note", "log this", "jot this down",
  "I had an idea", or similar capture-intent phrases.

  Scratches exist at three levels: global (unattached to any project), project-level (the project
  journal), and work-item-level (drift/deviation tracking). This skill handles all three.

  Scratches are APPEND-ONLY. Entries are never edited or deleted. Each entry is timestamped and
  tagged. Scratches can be searched across all levels, and individual entries can be promoted to
  work items via the story skill.
---

# Scratch Skill

You manage the scratch/journal system for the SDLC. Scratches are the working memory — a continuous, append-only log of thoughts, decisions, research, and conversations. All scratch state lives in Anvil as `journal` type notes.

## Core Principle

**Scratches are append-only.** Never edit or delete an existing entry. Every entry gets a timestamp and optional tags. The scratch is a permanent record.

## MCP Tools Used

| Tool | Purpose |
|------|---------|
| `anvil_create_note` | Create new journal entries |
| `anvil_search` | Search across all journals by tags, content, project |
| `anvil_get_note` | Read specific journal entries |
| `anvil_update_note` | Append to existing journal (body append for journal type) |

## Conversation State

Conversation-state notes store **metadata in frontmatter fields** and **content in the markdown body**. The body uses `## Decided`, `## Open Questions`, and `## Handoff Note` sections. Never write decided, open, or handoff content to frontmatter fields.

On entry, read the current `conversation-state` note for this workspace:
- Search: `anvil_search` type=conversation-state, workspace=current
- If `status=paused`: parse the `## Handoff Note` section from the note body, present to user, confirm continuation
- If `status=active`: parse `## Decided` and `## Open Questions` sections from the body; read `last_skill`, `work_items` from fields. Use these to inform your work.
- If not found: create new conversation-state (topic inferred, status=active, body with empty `## Decided`, `## Open Questions`, `## Handoff Note` sections)

On exit, update conversation-state body via `anvil_update_note` with `body:` containing the full updated markdown:
- Append decisions under `## Decided`
- Remove resolved items from `## Open Questions`
- Add new work item IDs to `work_items` field
- Set `last_skill` field to `sdlc-scratch`
- If user pauses: write handoff summary under `## Handoff Note`, set `status` field to `paused`

## Scratch Levels

| Level | How It's Stored | Purpose |
|-------|----------------|---------|
| **Global** | Journal note with no project tag | Free-floating ideas, cross-project thoughts |
| **Project** | Journal note tagged with project reference | Project-level decisions, research |
| **Work Item** | Journal note tagged with work-item reference | Deviation tracking, implementation notes |

## Operations

### `log` — Capture a New Entry (Flow 17: Capture Learning)

1. **Determine the level:**
   - If the user mentions a work item ID → work-item-level journal, tagged with the work item reference
   - If the user mentions a project name → project-level journal, tagged with the project reference
   - If neither → global journal entry
   - If ambiguous → ask the user

2. **Create journal entry via `anvil_create_note`:**
   - Type: `journal`
   - Title: brief descriptive title
   - Tags: user-specified + auto-suggested from content
   - Body: timestamped entry content

3. **Auto-suggest tags** based on content:
   - Mentions of decisions → `#decision`
   - Mentions of problems/blockers → `#blocker`
   - Mentions of alternatives/trade-offs → `#learning`
   - Mentions of changes from plan → `#deviation`
   - Mentions of things to avoid → `#gotcha`

4. **If the learning is reusable across projects:**
   - Suggest updating project agent config "Learned Mistakes" if project-specific
   - Suggest promoting to Vault via write-path MCP if cross-project

5. **Confirm** what was logged and where.

### `search` — Find Entries Across Scratches

Search across all journal entries at all levels:

1. Call `anvil_search` with query text across type `journal`
2. Optionally filter by tags: `anvil_search` with `tags: ["decision"]`
3. Group results by level: global, project, work-item
4. Present with timestamps, tags, and context

### `promote` — Turn a Scratch Entry into a Work Item

When the user wants to promote a scratch entry to a work item:

1. Read the journal entry via `anvil_get_note`
2. Ask which project the work item should belong to (if not obvious)
3. Hand off to the **story skill** with the journal content as the seed
4. Append a note to the original journal: "Promoted to work item #{id} on {date}"

### `review` — Summarize Recent Activity

Generate a summary of recent journal entries:

1. `anvil_search` for journal entries from the last N days (default: 7)
2. Group by level and project
3. Highlight entries tagged with `#decision`, `#blocker`, `#idea`, `#learning`
4. Present as a concise summary

## Standard Tags

| Tag | When to Use |
|-----|------------|
| `#learning` | Reusable insight or knowledge gained |
| `#gotcha` | Trap or pitfall to avoid |
| `#deviation` | Change from original plan (work-item level) |
| `#blocker` | Something blocking progress |
| `#scope-change` | Requirements changed mid-flight |
| `#pivot` | Major change in approach |
| `#decision` | A decision was made |
| `#idea` | New concept or approach to explore |
| `#question` | Open question to resolve |
| `#research` | Findings from investigation |
| `#conversation` | Outcome of a discussion |
| `#pattern` | Recurring pattern identified |
| `#edge-case` | Edge case discovered |
