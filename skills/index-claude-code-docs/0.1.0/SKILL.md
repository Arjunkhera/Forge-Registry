---
name: index-claude-code-docs
description: >
  Indexes Claude Code documentation from code.claude.com into the Vault knowledge base
  under external/claude-code/. Fetches machine-readable .md URLs, synthesizes groups of
  related pages into structured Vault knowledge pages, and runs the full write pipeline.

  Use this skill when: the user wants to refresh or update Claude Code docs in Vault,
  new Claude Code features have shipped, a Vault search for Claude Code capabilities
  returns stale or missing results, or the user invokes /index-claude-code-docs.

  Supports two modes: diff-only (default, indexes only new/changed pages) and
  --full (re-indexes everything regardless of status).
---

# Index Claude Code Docs

Indexes Claude Code documentation into the Vault so agents can query Claude Code
capabilities without browsing the live docs.

## Context

- **Source index:** https://code.claude.com/docs/llms.txt (126 pages as of 2026-05-09)
- **Page format:** Each doc has a `.md` URL — append `.md` to the HTML URL or use the URL directly from llms.txt. These return clean markdown, no scraping needed.
- **Manifest:** `artifacts/claude-code-docs/pages.json` in the benchy workspace — defines the 32 Vault page groups, their source URLs, and current status (`pending` / `done`)
- **Strategy doc:** `artifacts/claude-code-docs/strategy.md` — full rationale, skip list, and frontmatter template
- **Vault base path:** `external/claude-code/`
- **Vault index:** `external/claude-code/index.md`

## Input

Invoked as `/index-claude-code-docs` with optional flag:
- (no flag) — diff mode: only process pages with status `pending` or new pages not in manifest
- `--full` — re-index all 32 Vault pages regardless of status

## Process

### Step 1: Discover changes

1. Fetch `https://code.claude.com/docs/llms.txt` with WebFetch
2. Read `artifacts/claude-code-docs/pages.json`
3. Compare the llms.txt page list against the manifest:
   - New URLs not in any `source_urls` array → flag affected Vault page groups as needing update
   - In diff mode: collect only Vault pages with status `pending` plus any flagged above
   - In `--full` mode: collect all 32 Vault page groups
4. Report to the user: "Found N Vault pages to update"

### Step 2: Fetch and write (parallelized)

Spawn sub-agents (one per section) to work in parallel. Sections:

| Section | Vault pages |
|---------|-------------|
| Core | core/overview, core/how-it-works, core/memory, core/permissions, core/context-window |
| Features | features/skills, features/mcp, features/hooks, features/subagents, features/plugins |
| Reference | reference/cli-reference, reference/commands, reference/settings |
| Workflows | workflows/common-workflows, workflows/cicd, workflows/sessions |
| Platforms | platforms/overview, platforms/ide-extensions, platforms/web-desktop, platforms/computer-use, platforms/cloud-providers, platforms/slack |
| Admin | admin/setup, admin/monitoring, admin/network-security |
| Agent SDK | agent-sdk/overview, agent-sdk/core-features, agent-sdk/tools-and-skills, agent-sdk/hooks-and-permissions, agent-sdk/advanced, agent-sdk/reference |
| Index | index.md (write last, after all sections complete) |

Each sub-agent receives the list of Vault pages assigned to it. For each Vault page:

**a. Fetch source content**
- Fetch all `source_urls` for the page in parallel using WebFetch
- Prompt: "Return the complete markdown content of this page verbatim, preserving all headings, code blocks, lists, and tables."

**b. Compose the Vault page**
Combine fetched content into a single cohesive markdown document:
```
---
title: "<page title>"
description: "<one concise sentence>"
type: guide
mode: reference
scope:
  program: claude-code
tags:
  - claude-code
source_urls:
  - <all fetched URLs>
last_fetched: "<YYYY-MM-DD today>"
---

# <Title>

<Synthesized content with H2/H3 sections, preserving code blocks and tables>

## Source URLs
<list of all source URLs>
```

**c. Run the Vault write pipeline** (never skip steps)
1. `knowledge_check_duplicates(title, content_summary)` — score ≥ 0.75 means novel, proceed; below means overlap, update existing page instead
2. `knowledge_suggest_metadata(full_content)` — use suggestions to refine frontmatter
3. `knowledge_validate_page(full_content_with_frontmatter)` — fix any errors before proceeding
4. `knowledge_write_page(path, content)` — returns PR URL; record it

### Step 3: Merge PRs

After all sub-agents complete, collect all PR URLs. Then:
```bash
gh pr list --repo Arjunkhera/knowledge-base --state open --limit 100 --json number \
  | jq -r '.[].number' \
  | xargs -I{} gh pr merge {} --repo Arjunkhera/knowledge-base --merge
```

### Step 4: Update manifest

Update `artifacts/claude-code-docs/pages.json`:
- Set `status: "done"` for all successfully written pages
- Update `last_fetched` timestamp
- Add any new pages discovered in llms.txt

## Output

Report to user:
```
Indexed N Vault pages under external/claude-code/
- N pages updated, N unchanged
- N PRs merged: <list PR URLs>
- Manifest updated: artifacts/claude-code-docs/pages.json
```

## Skip List

Never index these pages (they are excluded from pages.json):
- `changelog.md` — too long, frequently changing
- `whats-new/*.md` — weekly updates, volatile
- `champion-kit.md`, `communications-kit.md` — internal marketing
- `legal-and-compliance.md`, `data-usage.md`, `zero-data-retention.md` — legal
- `troubleshoot-install.md`, `errors.md` — support docs

## Guidelines

- **Always read pages.json first** — it is the source of truth for groupings and current status
- **Vault write pipeline is mandatory** — never call `knowledge_write_page` without first running check_duplicates, suggest_metadata, and validate_page
- **Valid frontmatter types:** `guide`, `concept`, `procedure`, `repo-profile`, `keystone`, `learning`
- **Valid mode values:** `reference`, `operational`, `keystone`
- **If validate_page returns errors:** fix frontmatter and retry once before reporting failure
- **Index page last:** `external/claude-code/index.md` must be written after all section pages so it can reference accurate page paths
- **Diff mode is safe to run anytime** — it only touches pages that need updating
