---
name: horus-anvil
description: >
  Anvil MCP reference. Use when you need to create, read, update, search, or
  query notes in Anvil. Covers the dynamic type system with inheritance, field
  validation, search patterns, view rendering, sync, and error recovery.
---

# Horus Anvil — MCP Tool Reference

Anvil is the live state system. All structured data (tasks, notes, journals, stories, etc.) lives here as markdown files with YAML frontmatter, indexed by an embedded SQLite database with FTS5 full-text search.

## Tools

| Tool | Purpose | Key Parameters |
|------|---------|---------------|
| `anvil_create_entity` | Create a new note | `type` (required), `title` (required), `fields` (type-specific), `content` (markdown body), `use_template` (default: true) |
| `anvil_get_note` | Retrieve a note by ID with relationships | `noteId` (UUID) |
| `anvil_update_entity` | Update a note (PATCH semantics) | `noteId` (required), `fields` (partial), `content` (replaces body; appends for journals) |
| `anvil_search` | Free-text + filtered search | `query`, `type`, `tags` (AND), `status`, `priority`, `due`, `assignee`, `project`, `scope`, `limit`, `offset` |
| `anvil_query_view` | Structured query with rendered output | `view` (required: list/table/board), `filters`, `orderBy`, `columns` (table), `groupBy` (required for board), `limit`, `offset` |
| `anvil_list_types` | List all available note types with full schema | (none) |
| `anvil_get_edges` | Get forward links and backlinks for a note | `noteId` (UUID) |
| `anvil_sync_pull` | Pull latest from remote git repo | `remote` (default: origin), `branch` |
| `anvil_sync_push` | Stage .md + type files, commit, and push | `message` (required) |

## Type System

**Always call `anvil_list_types` before creating notes.** Never guess types or field names.

The type system is dynamic and supports single inheritance (max 3 levels deep). Every type implicitly extends `_core`.

```
_core (implicit base — noteId, type, title, created, modified, tags, related, scope)
  ├── note       (generic note)
  ├── task       (status, priority, due, effort, assignee, project)
  │   └── story  (acceptance_criteria, story_points — extends task)
  ├── journal    (append-only behavior)
  ├── project    (project container)
  ├── person     (contact)
  ├── service    (external service)
  └── meeting    (meeting record)
```

### Core Fields (on every note)

| Field | Type | Description |
|-------|------|-------------|
| `noteId` | string | UUID, auto-generated, immutable |
| `type` | string | Type ID, immutable |
| `title` | string | 1-300 characters |
| `created` | datetime | Auto-set, immutable |
| `modified` | datetime | Auto-updated on every change |
| `tags` | tags | String array, no duplicates |
| `related` | reference_list | Wiki-links `[[Note Title]]` |
| `scope` | object | `{ context: personal|work, team, service }` |

### Field Types

| Type | Description | Constraints |
|------|-------------|-------------|
| `string` | Free text | `min_length`, `max_length`, `pattern` |
| `text` | Long text | `min_length`, `max_length` |
| `url` | URL string | — |
| `enum` | One of fixed values | `values[]` (required) |
| `date` | ISO date string | — |
| `datetime` | ISO datetime | — |
| `number` | Numeric value | `min`, `max`, `integer` |
| `boolean` | True/false | — |
| `tags` | Array of strings | `no_duplicates` |
| `reference` | Link to a note | `ref_type` (target type constraint) |
| `reference_list` | Multiple links | — |
| `object` | Nested fields | Sub-field definitions |

### Field Behaviors

| Behavior | Description |
|----------|-------------|
| `required` | Must be set on creation |
| `immutable` | Cannot change after creation (`noteId`, `created` always immutable) |
| `auto` | Auto-populate: `uuid` (generate) or `now` (current timestamp) |
| `default` | Default value if not provided |

## Creating Notes

1. Call `anvil_list_types` to discover available types and their fields
2. Pick the correct type based on what the user wants to create
3. Call `anvil_create_entity` with:
   - `type`: The type ID from step 1
   - `title`: User-provided title
   - `fields`: Only fields that are valid for this type (from step 1)
   - `use_template`: `true` to apply the type's body template (default)
   - `content`: Optional markdown body (overrides template if provided)

**Do NOT** pass fields that aren't defined in the type — this will cause a validation error.

## Searching Notes

### `anvil_search` — Free-text + filters

Best for: finding notes by keyword, filtering by type/status/tags. Uses SQLite FTS5 with BM25 ranking + recency boost.

```json
{
  "query": "authentication bug",
  "type": "task",
  "status": "in-progress",
  "tags": ["backend"],
  "limit": 20
}
```

**All parameters are flat top-level fields**, not nested in a `filters` object. Tags use AND semantics — a note must have ALL specified tags.

**For an unfiltered search, omit `query` entirely** — passing `"*"` is invalid FTS5 syntax and will error.

**Three search modes:**
- Query + Filters: FTS candidates → structured filter → recency boost
- Query only: FTS with BM25 ranking
- Filters only: Structured query (no free-text)

### `anvil_query_view` — Structured views

Best for: dashboards, kanban boards, sorted lists, tabular reports.

**`view` is required.** Use `filters` (not `filter`) for criteria. Use `orderBy` (not `sort`) for sorting.

**List format:**
```json
{
  "view": "list",
  "filters": { "type": "task", "status": "in-progress" },
  "orderBy": { "field": "modified", "direction": "desc" },
  "limit": 50
}
```

**Table format** (specify columns):
```json
{
  "view": "table",
  "filters": { "type": "task" },
  "columns": ["title", "status", "priority", "due"],
  "orderBy": { "field": "priority", "direction": "asc" }
}
```

**Board format** (kanban-style, `groupBy` required):
```json
{
  "view": "board",
  "filters": { "type": "task" },
  "groupBy": "status"
}
```

Board creates a column for each enum value of the groupBy field. Auto-detects columns by type if not specified.

## Updating Notes

Updates use **PATCH semantics** — only send fields you want to change:

```json
{
  "noteId": "uuid-here",
  "fields": { "status": "done", "priority": "P1-high" }
}
```

- Omitted fields are preserved
- `modified` timestamp always updated automatically
- `content` replaces the body for most types
- **Journals are append-only** — `content` is appended, not replaced
- Immutable fields (`noteId`, `created`, `type`) cannot be changed

## Relationships

Notes link to each other through:
- **`related` field**: Explicit wiki-links `[[Note Title]]`
- **Body wiki-links**: `[[mentions]]` extracted from markdown body (skipping code blocks)
- **Typed reference fields**: e.g., `assignee` → person, `project` → project

Use `anvil_get_edges` to discover:
- **Forward links**: References this note makes (grouped by relation type)
- **Reverse links / backlinks**: Notes that reference this one

Forward references can be unresolved (target doesn't exist yet) — they resolve automatically when the target note is created.

## Sync

### anvil_sync_pull
Fetches from remote and merges. Prefers fast-forward; falls back to regular merge. Detects conflict markers (`<<<<<<<`) in changed files.

### anvil_sync_push
**Selective staging:** Only stages `.md` files and `.anvil/types/*.yaml`. Never stages `.anvil/.local/` (local SQLite index, runtime state). This prevents syncing machine-specific data.

## Storage Details

- **Location**: `~/Horus/horus-data/notes/`
- **File format**: Markdown with YAML frontmatter
- **Organization**: Flat or by-type subdirectories
- **Slugification**: `"Fix Auth Bug"` → `fix-auth-bug.md` (collision: `-1`, `-2`)
- **Atomic writes**: Write to `.tmp`, rename to final path
- **Index**: SQLite at `.anvil/.local/index.db`, rebuilt from files on startup
- **Type definitions**: `.anvil/types/*.yaml`, hot-reloaded on change

## Error Recovery

| Error | Cause | Fix |
|-------|-------|-----|
| `TYPE_NOT_FOUND` | Used a type that doesn't exist | Call `anvil_list_types` and use a valid type |
| `VALIDATION_ERROR` | Invalid field name or value | Check the type's field definitions from `anvil_list_types` |
| `NOT_FOUND` | Invalid noteId | Verify the UUID via `anvil_search` |
| `APPEND_ONLY` | Tried to replace journal body | Content is appended for journal types |
| `IMMUTABLE_FIELD` | Tried to change a read-only field | Remove that field from the update payload |
| `CONFLICT` | Merge conflict on sync pull | Resolve conflict markers manually |
| `SYNC_ERROR` | Git operation failed | Check remote connectivity |

## Known Gotchas

These mistakes have been observed in practice — avoid them:

| # | Mistake | Correct behaviour |
|---|---------|------------------|
| 1 | Guessing status values (e.g., `draft`, `ready`, `in_progress`) | **Always call `anvil_list_types` first.** Status enums are type-specific. Tasks/stories use `open`, `in-progress`, `blocked`, `done`. |
| 2 | Passing `query: "*"` for an unfiltered search | **Omit `query` entirely.** FTS5 rejects bare `*` — leaving the field out returns all notes matching other filters. |
| 3 | Passing `filters: { status: "..." }` as a nested object to `anvil_search` | **`anvil_search` takes flat top-level params** (`status`, `type`, `priority`, `tags`). Only `anvil_query_view` uses a nested `filters` object. |
| 4 | Using `format`, `filter`, or `sort` with `anvil_query_view` | **The correct field names are `view` (required), `filters`, and `orderBy`.** |
| 5 | Passing `content` to update a journal expecting replacement | **Journals are append-only.** New content is appended to the existing body, never replaced. |
