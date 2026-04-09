---
name: horus-vault
description: >
  Vault MCP reference. Use when you need to read or write knowledge pages —
  repo profiles, guides, procedures, concepts, and learnings. Covers the
  read path, write path pipeline, page types, scope resolution, schema
  management, and multi-vault routing.
---

# Horus Vault — MCP Tool Reference

Vault is the knowledge base. It stores long-lived, structured documentation about codebases, conventions, procedures, and decisions. It has a two-tier architecture: a Python REST API (FastAPI) for search and knowledge logic, and a thin TypeScript MCP adapter that translates MCP calls to HTTP requests.

## Multi-Vault Architecture

Horus supports multiple vault instances (e.g., `personal` and `work`). All tools route through `vault-router`, which sits between the MCP and the vault instances:

- **Read tools** (search, resolve-context, list-by-scope, check-duplicates, suggest-metadata) **fan out** to all vaults and merge results. Pass `vault=` to restrict to one vault.
- **Write/routed tools** (get-page, get-related, write-page, validate-page, registry-add, schema) **route to a specific vault** — by explicit `vault=` param, UUID registry lookup, or default vault.

## Tools

| Tool | Purpose | Key Parameters |
|------|---------|---------------|
| `knowledge_resolve_context` | Get all applicable pages for a repo | `repo` (required), `include_full` (default: false), `vault` |
| `knowledge_search` | Hybrid search (keyword + semantic + reranking) | `query` (required), `scope` ({program, repo}), `type`, `mode`, `limit`, `vault` |
| `knowledge_get_page` | Read a full page by ID (UUID or file path) | `id` (required), `vault` |
| `knowledge_get_related` | Follow links from a page (UUID or file path) | `id` (required), `vault` |
| `knowledge_list_by_scope` | Browse pages by scope, mode, type, tags | `scope` ({program, repo}), `type`, `mode`, `tags`, `limit`, `vault` |
| `knowledge_validate_page` | Validate page against schema + registries | `content` (full markdown with frontmatter), `vault` |
| `knowledge_suggest_metadata` | Auto-suggest frontmatter fields | `content` (markdown), `hints`, `vault` |
| `knowledge_check_duplicates` | Check overlap with existing pages | `title`, `content`, `threshold` (0-1, default: 0.75), `vault` |
| `knowledge_get_schema` | Get schema definition + registry contents | `vault` (defaults to default vault) |
| `knowledge_write_page` | Write page via git (UUID auto-generated if missing) | `path` (required), `content` (required), `pr_title`, `pr_body`, `commit_message`, `vault` |
| `knowledge_registry_add` | Add entry to a registry | `registry` (tags/repos/programs), `entry` ({id, description?, aliases?}), `vault` |

### The `vault` parameter

All tools accept an optional `vault` string (e.g., `"personal"`, `"work"`):

- **Omitted on read tools** → fan-out: results merged from all vaults, each result tagged with `source_vault`
- **Specified on read tools** → restrict to that vault only
- **Omitted on write/routed tools** → UUID registry lookup (for existing pages) or default vault (for new pages)
- **Specified on write/routed tools** → route directly to that vault

## Page Identity

Every knowledge page has a **UUIDv4 `id`** in its YAML frontmatter as its primary identifier. All tools that accept a page `id` parameter accept either a UUID (e.g., `550e8400-e29b-41d4-a716-446655440000`) or a file path (e.g., `repos/anvil.md`). Search results and page summaries return the UUID as `id` and the file path as `path`. New pages get a UUID auto-generated on write.

## Page Types

| Type | Purpose | Example |
|------|---------|---------|
| `repo-profile` | Describes a repository — tech stack, conventions, test commands | `repos/anvil.md` |
| `guide` | How-to guide for a specific workflow | `guides/onboarding.md` |
| `procedure` | Step-by-step operational procedure | `procedures/deploy.md` |
| `concept` | Explains an architectural concept or pattern | `concepts/event-sourcing.md` |
| `keystone` | Program-level overview and architecture | `programs/horus.md` |
| `learning` | Captured learnings, post-mortems, discoveries | `learnings/caching-gotcha.md` |

## Page Modes

| Mode | Description | Typical Types |
|------|-------------|---------------|
| `reference` | Long-lived reference material | concepts, repo-profiles |
| `operational` | Active procedures and guides used during work | guides, procedures |
| `keystone` | Top-level architectural overviews | keystone |

## Scope System

Pages are scoped at two levels: **program** and **repo**.

```
Program Level (e.g., program: horus)
  └── Repo Level (e.g., repo: anvil)
```

When resolving context for a repo:
1. Find the repo-profile page
2. Extract the program from scope
3. Collect all operational pages:
   - **Specificity 2** (repo-level): `scope.repo` matches OR `applies_to` references the repo
   - **Specificity 1** (program-level): `scope.program` matches
4. Return sorted by specificity (repo-level first)

**Cross-repo references:** The `applies-to` field lets a page reference multiple repos without duplicating content.

## Page Frontmatter

```yaml
---
id: 550e8400-e29b-41d4-a716-446655440000  # UUIDv4 (auto-generated if missing)
title: Deployment Guide                    # Required, max 120 chars
type: guide                                 # Required (one of the 6 types)
mode: operational                           # Required (reference/operational/keystone)
scope:
  program: horus                            # Program scope
  repo: anvil                               # Repo scope (optional)
tags: [deployment, ci-cd]                   # From registry, min 1
owner: platform-team                        # Recommended
last-verified: "2026-03-01"                 # Recommended
description: "Step-by-step deploy guide"    # Recommended
related: [guides/rollback.md]               # Relationship: general
depends-on: ["services/api.md"]             # Relationship: dependency
consumed-by: ["services/monitoring.md"]     # Relationship: consumer
applies-to: [anvil, forge]                  # Cross-repo reference
---
```

## Relationships

| Field | Direction | Description |
|-------|-----------|-------------|
| `related` | Bidirectional | General relationship |
| `depends-on` | This page depends on... | Dependency chain |
| `consumed-by` | This page is consumed by... | Consumer tracking |
| `applies-to` | This page applies to repos... | Cross-repo scope |

Formats: wiki-links (`[[Page Title]]`), dict refs (`{"repo": "name"}`), or plain strings.

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

### 5. Vault-specific read ("search only my work vault")
```
knowledge_search(query, vault: "work")
```

### Progressive disclosure
Search results return **PageSummary** (description only). Use `knowledge_get_page` for **PageFull** (with body + relationships). Use `include_full: true` on `resolve_context` to get full pages in one call.

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
Returns per-field suggestions with confidence levels (high/medium/low/none). Analysis includes: type signals, mode signals, keyword extraction, registry fuzzy matching, repo mention extraction.

### 3. Validate
```
knowledge_validate_page(content)
```
- Pass full markdown with YAML frontmatter
- Validates: type, required fields, field constraints, registry values, mode, scope
- Returns structured errors with fuzzy-match suggestions for invalid values
- Fix any errors before writing

### 4. Write
```
knowledge_write_page(path, content, pr_title?, pr_body?, commit_message?, vault?)
```
- Creates a new branch, commits the page, and opens a GitHub PR
- Returns the PR URL for human review
- Requires `GITHUB_TOKEN` and `GITHUB_REPO` configuration

## Schema and Registries

### Get schema + registries
```
knowledge_get_schema(vault?)
```
Returns all page types, field constraints, and registry contents (tags, repos, programs). Defaults to default vault's schema.

### Add to a registry
If validation rejects a value that should exist:
```
knowledge_registry_add(registry: "tags"|"repos"|"programs", entry: {id, description?, aliases?}, vault?)
```

## Common Patterns

**Finding repo conventions before coding:**
```
knowledge_resolve_context(repo: "my-repo", include_full: true)
```

**Creating a new learning page after a discovery:**
```
1. knowledge_check_duplicates(title, content)
2. knowledge_suggest_metadata(content, hints: {"scope.program": "horus"})
3. knowledge_validate_page(full_page)
4. knowledge_write_page(path, full_page, pr_title: "Add learning: ...")
```

**Understanding a program's architecture:**
```
knowledge_search(query: "architecture", scope: {program: "horus"}, type: "keystone")
```

**Writing to a specific vault:**
```
knowledge_write_page(path, content, vault: "work")
```

**Searching only one vault:**
```
knowledge_search(query: "auth conventions", vault: "personal")
```

## Error Codes

| Code | HTTP | Cause | Fix |
|------|------|-------|-----|
| `VALIDATION_FAILED` | 400 | Schema/registry validation | Fix errors in frontmatter, check registries |
| `PARSE_ERROR` | 400 | YAML frontmatter parsing | Fix YAML syntax |
| `PAGE_NOT_FOUND` | 404 | Page ID doesn't exist | Check the path/ID |
| `REGISTRY_NOT_FOUND` | 404 | Invalid registry name | Use: tags, repos, or programs |
| `DUPLICATE_ENTRY` | 409 | Registry entry already exists | Entry already registered |
| `SCHEMA_NOT_LOADED` | 503 | Schema not loaded yet | Wait for service startup |
| `GIT_ERROR` | 500 | Git operation failure | Check git repo state |
| `GITHUB_API_ERROR` | 500 | GitHub API call failure | Check GITHUB_TOKEN |
