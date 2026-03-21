---
name: horus-anvil
description: >
  Anvil MCP reference. Use when you need to create, read, update, search, or
  query notes in Anvil. Covers the dynamic type system, field validation,
  search patterns, and error recovery.
---

# Horus Anvil — MCP Tool Reference

Anvil is the live state system. All structured data (tasks, notes, journals, stories, etc.) lives here.

## Tools

| Tool | Purpose | Key Parameters |
|------|---------|---------------|
| `anvil_create_note` | Create a new note | `type` (required), `title` (required), `fields` (type-specific), `content` (markdown body), `use_template` (default: true) |
| `anvil_get_note` | Retrieve a note by ID | `noteId` (UUID) |
| `anvil_update_note` | Update a note (PATCH) | `noteId` (required), `fields` (partial), `content` (replaces body, except journals which append) |
| `anvil_search` | Free-text + filtered search | `query` (Typesense; FTS5 fallback), `type`, `tags` (AND), `status`, `priority`, `due` (range), `limit`, `offset` |
| `anvil_query_view` | Structured query with rendering | `view` (required: list/table/board), `filters` (object), `orderBy`, `columns` (for table), `groupBy` (required for board), `limit`, `offset` |
| `anvil_list_types` | List all available note types | (none) |
| `anvil_get_related` | Get links and backlinks for a note | `noteId` (UUID) |
| `anvil_sync_pull` | Pull latest from remote | `remote` (default: origin), `branch` |
| `anvil_sync_push` | Commit and push changes | `message` (required) |

## Type System

**Always call `anvil_list_types` before creating notes.** Never guess types or field names.

The type system is dynamic — the vault owner defines types. Each type has:
- **name**: Type identifier (e.g., `task`, `note`, `journal`, `story`)
- **parent**: Inheritance (usually `_core`)
- **fields**: Typed field definitions
- **template**: Default body content

### Field Types

| Type | Description | Example |
|------|-------------|---------|
| `string` | Free text | `title`, `description` |
| `enum` | One of fixed values | `status: [draft, ready, done]` |
| `boolean` | True/false | `is_archived` |
| `number` | Numeric value | `story_points` |
| `date` | ISO date string | `due_date` |
| `datetime` | ISO datetime | `created_at` |
| `reference` | UUID link to another note | `project`, `parent` |
| `tags` | Array of strings | `tags: [frontend, urgent]` |
| `array` | Array of values | `assignees` |
| `object` | Nested object | `metadata` |
| `markdown` | Markdown content | `body` |
| `url` | URL string | `link` |

## Creating Notes

1. Call `anvil_list_types` to discover available types
2. Pick the correct type based on what the user wants to create
3. Call `anvil_create_note` with:
   - `type`: The type ID from step 1
   - `title`: User-provided title
   - `fields`: Only fields that are valid for this type (from step 1)
   - `use_template`: `true` to apply the type's body template (default)
   - `content`: Optional markdown body (overrides template if provided)

**Do NOT** pass fields that aren't defined in the type — this will cause a validation error.

## Searching Notes

### `anvil_search` — Free-text + filters (Typesense)
Best for: finding notes by keyword, filtering by type/status/tags. Uses Typesense as primary search engine with FTS5 as emergency fallback.

```json
{
  "query": "authentication bug",
  "type": "task",
  "status": "in-progress",
  "tags": ["backend"],
  "limit": 20
}
```

Tags use AND semantics — a note must have ALL specified tags to match.

**For an unfiltered search, omit `query` entirely** — passing `"*"` is invalid FTS5 syntax and will error.

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

## Updating Notes

Updates use **PATCH semantics** — only send fields you want to change:

```json
{
  "noteId": "uuid-here",
  "fields": { "status": "done", "priority": "P1-high" }
}
```

- Omitted fields are preserved
- `content` replaces the body for most types
- **Journals are append-only** — `content` is appended, not replaced
- Some fields may be immutable (e.g., `type`, `created_at`)

## Error Recovery

| Error | Cause | Fix |
|-------|-------|-----|
| `TYPE_NOT_FOUND` | Used a type that doesn't exist | Call `anvil_list_types` and use a valid type |
| `VALIDATION_ERROR` | Invalid field name or value | Check the type's field definitions from `anvil_list_types` |
| `NOTE_NOT_FOUND` | Invalid noteId | Verify the UUID via `anvil_search` |
| `APPEND_ONLY` | Tried to replace journal body | Use append semantics — content is added to existing body |
| `IMMUTABLE_FIELD` | Tried to change a read-only field | Remove that field from the update payload |

## Relationships

Use `anvil_get_related` to discover forward links (references this note makes) and backlinks (notes that reference this one). Useful for navigating project → stories → tasks hierarchies.

## Known Gotchas

These mistakes have been observed in practice — avoid them:

| # | Mistake | Correct behaviour |
|---|---------|------------------|
| 1 | Guessing status values (e.g., `draft`, `ready`, `in_progress`) | **Always call `anvil_list_types` first.** Status enums are type-specific. Tasks/stories use `open`, `in-progress`, `blocked`, `done`. |
| 2 | Passing `query: "*"` for an unfiltered search | **Omit `query` entirely.** FTS5 rejects bare `*` — leaving the field out returns all notes matching other filters. |
| 3 | Passing `filters: { status: "..." }` as a nested object to `anvil_search` | **`anvil_search` takes flat top-level params** (`status`, `type`, `priority`, `tags`). Only `anvil_query_view` uses a nested `filters` object. |
| 4 | Using `format`, `filter`, or `sort` with `anvil_query_view` | **The correct field names are `view` (required), `filters`, and `orderBy`.** The old names were stale schema — they will cause a validation error. |
