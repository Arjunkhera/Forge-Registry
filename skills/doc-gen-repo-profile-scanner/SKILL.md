---
name: doc-gen-repo-profile-scanner
description: >
  Analyzes a source repository via a Forge code session and generates a
  structured repo-profile Vault page. Extracts tech stack, key dependencies,
  conventions, entry points, and build/test commands. Assigns a confidence
  score (1-5) and writes the page via the Vault write-path pipeline. Part of
  the doc-gen pipeline.

  Invoke when the user asks to "scan a repo", "generate a repo profile",
  "document this codebase", or "create a Vault page for repo X".
---

# Doc-Gen — Repo Profile Scanner

You analyze a source repository via a Forge code session and produce a `repo-profile` Vault page. Your output is agent-optimized: dense, unambiguous, and structured so other skills can consume it without re-reading the source.

## MCP Tools Used

| Tool | Purpose |
|------|---------|
| `forge_develop` | Create or resume a code session (git worktree) for the target repo |
| `knowledge_check_duplicates` | Check for an existing repo-profile before writing |
| `knowledge_suggest_metadata` | Get frontmatter field suggestions from Vault |
| `knowledge_validate_page` | Validate the page against schema before writing |
| `knowledge_write_page` | Write the page via git workflow (branch → commit → PR) |
| `knowledge_registry_add` | Register the repo (with aliases) in the repos registry via PR |
| `knowledge_create_edge` | Create a `DOCS` edge linking the page to the repo node |
| `anvil_update_note` | Update work item status when invoked from a work item |

## Core Workflow

### Phase 1: Session Setup

1. Call `forge_develop` with:
   - `repo`: the target repo name (from the Forge repo index)
   - `workItem`: the work item ID that triggered this scan (if any)
2. On `status: "needs_workflow_confirmation"`: present detected workflow to user, confirm, then re-call with `workflow` parameter.
3. Record `sessionPath` from the response. **All file reads in Phase 2 use `sessionPath` as the root.**

### Phase 2: Repo Analysis

Read each of the following files if they exist under `sessionPath`. Never fail if a file is absent — note its absence and continue.

**Discovery targets (in priority order):**

| File / Path | What to extract |
|-------------|----------------|
| `README.md` | Description, purpose, key concepts, usage examples |
| `package.json` | Language (Node/JS/TS), framework, scripts, top dependencies |
| `pyproject.toml` / `setup.py` / `requirements.txt` | Python stack, dependencies, entry points |
| `go.mod` | Go module name, Go version, key dependencies |
| `Cargo.toml` | Rust crate name, edition, dependencies |
| `Dockerfile` / `docker-compose.yml` | Deployment model, exposed ports, environment requirements |
| `.github/workflows/*.yml` | CI/CD patterns, test commands, lint commands, deploy steps |
| `src/` or primary source directory | Language confirmation, framework usage, key patterns |
| Top-level directory listing | Module organization, presence of `tests/`, `docs/`, `scripts/` |

**Produce a structured internal analysis:**

```
primary_language: {language}
framework: {framework or "none"}
key_dependencies: [{name: ..., purpose: ...}, ...]  # top 5-10
service_role: {what this repo does in 1-2 sentences}
testing_approach: {jest/pytest/go test/etc., location of tests}
notable_conventions: [{pattern description}, ...]
entry_points: [{file or command, purpose}, ...]
build_commands:
  install: {command}
  test: {command}
  lint: {command or "not found"}
  run: {command or "not found"}
confidence: {1-5}  # see scoring rubric below
is_monorepo: {true/false}
```

**Confidence scoring rubric:**

| Score | Criteria |
|-------|---------|
| 5 | README, package manifest, and source directory all present and internally consistent |
| 4 | README + package manifest present (source partially readable or absent) |
| 3 | README only, OR package manifest only with readable source |
| 2 | Source analysis only — no README and no manifest |
| 1 | Very sparse repo: no README, no manifest, minimal source signals |

### Phase 3: Generate Repo-Profile Page

Using the structured analysis from Phase 2, produce a Vault `repo-profile` page with the following template. Fill every section — do not omit sections even if content is sparse (use "Not found" or "N/A" rather than omitting).

````markdown
---
title: {Repo Name} — {Short Description (≤60 chars)}
type: repo-profile
mode: reference
scope:
  repo: {repo-name}
  program: {program-name-if-detectable}
tags: [{language}, {framework-if-any}, {key-domain-tags}]
description: {1-2 sentence description optimized for agent consumption — dense and unambiguous}
confidence: {1-5}
auto-generated: true
---

# {Repo Name}

## Role
{What this service or library does in 2-3 sentences. Write for agent consumption: state the role clearly, avoid filler phrases like "this repo is a...". Name the domain, the responsibility boundary, and any upstream/downstream dependencies if known.}

## Tech Stack
| Layer | Technology |
|-------|-----------|
| Language | {language} {version-if-known} |
| Framework | {framework or "None"} |
| Runtime | {runtime or "N/A"} |
| Package Manager | {npm/pip/cargo/go modules/etc.} |

## Key Dependencies
- `{dep-name}` — {one-line purpose}
- `{dep-name}` — {one-line purpose}
{repeat for top 5-10 dependencies}

## Entry Points
| Command / File | Purpose |
|----------------|---------|
| {file or command} | {purpose} |

## Conventions
{2-5 bullet points describing key patterns. Examples: naming conventions (camelCase vs snake_case), test file locations, module structure, error handling style, config injection approach.}

## Build & Test Commands
```
# Install
{install command}

# Test
{test command}

# Lint
{lint command or "# Not found"}

# Run
{run command or "# Not found"}
```

## Notes
{Any important caveats: monorepo flag, sparse analysis warning, known gaps. If confidence < 4, state what was missing and how it affects the profile quality.}
````

**Template rules:**

- `scope.program`: infer from repo name patterns (e.g., `horus-*` → `horus`), directory structure, or README references. If not detectable, omit the field.
- `tags`: use lowercase kebab-case. Always include the primary language. Add framework, domain (e.g., `api`, `cli`, `library`), and any notable tags from README.
- `description`: write as if answering "what is this repo and what does it do?" in one sentence for an agent that has never seen it.
- `confidence`: copy the score from your Phase 2 analysis.
- Monorepo: if `is_monorepo: true`, note it prominently in the Notes section and add a `monorepo` tag.

### Phase 4: Write via Vault Pipeline

Follow the Vault write-path pipeline exactly. Never skip or reorder steps.

**Step 1 — Check for duplicates:**
```
knowledge_check_duplicates(title: "{Repo Name} — {Short Description}", content: {full page})
```
- If a conflict is returned (score below threshold): an existing profile was found. **Update the existing page** instead of creating a new one — use `knowledge_write_page` with the existing page's path.
- If no conflict: proceed to Step 2.

**Step 2 — Suggest metadata:**
```
knowledge_suggest_metadata(content: {full page markdown}, hints: {scope if known})
```
- Review suggestions. Apply any high-confidence suggestions that differ from your draft (e.g., corrected tag values, better program inference).
- Log any medium/low-confidence suggestions you chose to override, with reasoning.

**Step 3 — Validate:**
```
knowledge_validate_page(content: {full page with frontmatter})
```
- If validation errors are returned: fix them before proceeding. Common fixes:
  - Invalid tag → check registry, use closest valid tag or add to registry via `knowledge_registry_add`
  - Missing required field → add it
  - Invalid type or mode → correct to valid values
- Re-validate after fixes until clean.

**Step 4 — Write:**
```
knowledge_write_page(
  path: "repos/{repo-name}.md",
  content: {validated page},
  pr_title: "doc-gen: add repo profile for {repo-name}",
  pr_body: "Auto-generated repo profile for {repo-name}. Confidence: {score}/5. Scanner: doc-gen-repo-profile-scanner v0.2.0.",
  commit_message: "docs(vault): add repo-profile for {repo-name}"
)
```
- Record the PR URL returned.

### Phase 5: Registry Update (mandatory)

After `knowledge_write_page` succeeds, register the repo in the Vault repos registry. This is **non-optional** — without it, the repo will not appear in alias-based `resolve_context` lookups.

Extract `repo_name` and `aliases` from the generated profile frontmatter, then call:

```
knowledge_registry_add({
  registry: "repos",
  entry: {
    id: "{repo-name}",
    description: "{one-line description from profile}",
    aliases: ["{alias1}", "{alias2}", ...],  // from frontmatter aliases field
  },
  via_pr: true,  // write to git branch + open PR, do not edit in-place
})
```

**Response handling:**
- Success: `{ added: true, pr_url: "..." }` — log the PR URL in the output summary
- `duplicate_entry` error: repo already registered — skip silently, log at DEBUG
- Any other error: log at WARN but do **not** fail the scan (non-blocking)

### Phase 6: Create Graph Edge

After the page is written:

```
knowledge_create_edge(
  from: "repos/{repo-name}.md",
  to: {repo node ID from Forge index},
  edge_type: "DOCS"
)
```

This links the Vault page to the repo node in Neo4j, enabling graph traversal from repo → documentation.

If `knowledge_create_edge` is unavailable or returns an error, log the failure and continue — the page write is the primary artifact.

### Phase 7: Update Work Item (if applicable)

If this skill was invoked from a work item:

```
anvil_update_note(id: {work_item_id}, fields: { status: "done" })
```

Only transition to `done` if the Vault page was successfully written. If the write failed, set status to `in_review` and include a note explaining the failure.

## Handling Edge Cases

### No README
- Proceed with source and manifest analysis only
- Set confidence ≤ 3
- Note in the page's Notes section: "No README found. Profile derived from source analysis and package manifest."

### Monorepo
- Scan top-level directory structure only
- Do not recurse into sub-packages
- Add `monorepo` tag to frontmatter
- Note in the Notes section: "This is a monorepo. Profile covers top-level structure only. Sub-package profiles may need separate scans."
- Set `scope.repo` to the top-level repo name

### Existing Vault Page (Conflict from `knowledge_check_duplicates`)
- Do not create a new page
- Read the existing page via `knowledge_get_page`
- Merge new findings into the existing content (prefer newer/more complete data)
- Write the merged content to the existing path using `knowledge_write_page`
- PR title: `"doc-gen: update repo profile for {repo-name}"`

### Manifest Present, Source Unreadable
- Use manifest + README for the profile
- Note in Notes: "Source directory not fully readable. Profile may miss implementation-level conventions."
- Set confidence ≤ 4

### `forge_develop` Session Failure
- If `forge_develop` returns an error: report to user, do not proceed
- Do not attempt to write a Vault page without a valid session path

## Output Summary

When complete, report to the user:

```
Repo Profile Scanner — Complete

Repo:         {repo-name}
Confidence:   {score}/5
Vault PR:     {PR URL}
Registry PR:  {PR URL (or: already registered / failed — see above)}
Edge:         DOCS link created (or: failed — see above)
Work item:    {status updated to "done" / "not applicable"}
```

If confidence < 3, add a warning:
```
Warning: Low confidence ({score}/5). Profile is based on limited signals.
Manual review recommended before relying on this profile for agent context.
```
