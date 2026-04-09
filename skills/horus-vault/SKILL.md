---
name: horus-vault
description: >
  Vault MCP reference. Use when you need to read or write knowledge pages —
  repo profiles, guides, procedures, concepts, and learnings. Covers the
  read path, write path pipeline, page types, and schema management.
---

# Horus Vault — MCP Tool Reference

Vault is the knowledge base. It stores long-lived, structured documentation about codebases, conventions, procedures, and decisions.

## Tools

| Tool | Purpose | Key Parameters |
|------|---------|---------------|
| `knowledge_resolve_context` | Get all applicable pages for a repo | `repo` (required), `include_full` (default: false) |
| `knowledge_search` | Hybrid search (keyword + semantic + reranking) | `query` (required), `scope` ({program, repo}), `type`, `mode`, `limit` |
| `knowledge_get_page` | Read a page by ID (UUID or file path) | `id` (UUID or path, e.g., `repos/anvil.md`) |
| `knowledge_get_related` | Follow links from a page | `id` (UUID or file path) |
| `knowledge_list_by_scope` | Browse pages for a program/repo | `scope` ({program, repo}), `type`, `mode`, `tags`, `limit` |
| `knowledge_validate_page` | Validate page against schema | `content` (full markdown with YAML frontmatter) |
| `knowledge_suggest_metadata` | Auto-suggest frontmatter fields | `content` (markdown), `hints` (optional partial knowledge) |
| `knowledge_check_duplicates` | Check overlap with existing pages | `title`, `content`, `threshold` (0-1, default: 0.75) |
| `knowledge_get_schema` | Get full schema + registry contents | (none) |
| `knowledge_registry_add` | Add tag/repo/program to a registry | `registry` (tags/repos/programs), `entry` ({id, description?, aliases?}) |
| `knowledge_write_page` | Write page, commit to branch, open PR (UUID auto-generated) | `path` (required), `content` (required), `pr_title`, `pr_body`, `commit_message` |

## Page Identity

Every knowledge page has a **UUIDv4 `id`** in its YAML frontmatter as its primary identifier. All tools that accept a page `id` parameter accept either a UUID (e.g., `550e8400-e29b-41d4-a716-446655440000`) or a file path (e.g., `repos/anvil.md`). UUIDs are returned in search results and page summaries. New pages get a UUID auto-generated on write.

## Read Path

Follow this order when answering knowledge questions:

### 1. Repo-scoped questions ("how does X work in repo Y?")
```
knowledge_resolve_context(repo) → get summaries
  → knowledge_get_page(id) → read full page if needed
```

### 2. General questions ("what's the convention for...?")
```
knowledge_search(query) → find relevant pages
  → knowledge_get_page(id) → read full content
```

### 3. Browsing ("show me all guides for program X")
```
knowledge_list_by_scope(scope, type?) → list pages
  → knowledge_get_page(id) → read specific pages
```

### 4. Relationship exploration
```
knowledge_get_related(id) → follow links (related, depends-on, consumed-by, applies-to)
```

## Page Types

| Type | Purpose | Example |
|------|---------|---------|
| `repo-profile` | Describes a repository — tech stack, conventions, test commands | `repos/anvil.md` |
| `concept` | Explains an architectural concept or pattern | `concepts/event-sourcing.md` |
| `guide` | How-to guide for a specific workflow | `guides/onboarding.md` |
| `procedure` | Step-by-step operational procedure | `procedures/deploy.md` |
| `keystone` | Program-level overview and architecture | `programs/horus.md` |
| `learning` | Captured learnings, post-mortems, discoveries | `learnings/caching-gotcha.md` |

## Page Modes

| Mode | Description |
|------|-------------|
| `reference` | Long-lived reference material (concepts, repo profiles) |
| `operational` | Active procedures and guides used during work |
| `keystone` | Top-level architectural overviews |

## Write Path Pipeline

**Never skip steps.** Always follow this sequence:

### 1. Check for duplicates
```
knowledge_check_duplicates(title, content, threshold?)
```
- Score >= threshold → novel content, safe to create new page
- Score < threshold → overlap exists, merge into existing page instead

### 2. Suggest metadata
```
knowledge_suggest_metadata(content, hints?)
```
Returns per-field suggestions with confidence. Use to build frontmatter.

### 3. Validate
```
knowledge_validate_page(content)
```
- Pass full markdown with YAML frontmatter
- Returns structured errors with fuzzy-match suggestions for invalid values
- Fix any errors before writing

### 4. Write
```
knowledge_write_page(path, content, pr_title?, pr_body?, commit_message?)
```
- Creates a new branch, commits the page, and opens a GitHub PR
- Returns the PR URL for human review

## Schema and Registries

### Get schema + registries
```
knowledge_get_schema()
```
Returns all page types, valid field values, and registry contents (tags, repos, programs).

### Add to a registry
If validation rejects a value that should exist:
```
knowledge_registry_add(registry: "tags"|"repos"|"programs", entry: {id, description?, aliases?})
```

## Common Patterns

**Finding repo conventions before coding:**
```
knowledge_resolve_context(repo: "my-repo", include_full: true)
```

**Creating a new learning page after discovering something:**
```
1. knowledge_check_duplicates(title, content)
2. knowledge_suggest_metadata(content)
3. knowledge_validate_page(full_page)
4. knowledge_write_page(path, full_page)
```

**Understanding a program's architecture:**
```
knowledge_search(query: "architecture", scope: {program: "horus"}, type: "keystone")
```
