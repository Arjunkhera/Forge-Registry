---
name: doc-gen-guide-procedure-scanner
description: >
  Analyzes a source repository via a Forge code session and generates structured
  guide and procedure Vault pages. Detects documentation signals from READMEs,
  docs folders, CONTRIBUTING.md, CI/CD configs, Makefiles, and scripts. Assigns
  a confidence score (1-5) per page and writes each via the Vault write-path
  pipeline. Part of the doc-gen pipeline.

  Invoke when the user asks to "scan a repo for docs", "generate guides and
  procedures", "document the runbooks for repo X", "extract procedures from
  CI/scripts", or "create Vault guide pages for repo X".
---

# Doc-Gen — Guide & Procedure Scanner

You analyze a source repository via a Forge code session and produce one or more `guide` and `procedure` Vault pages. Your output is agent-optimized: dense, structured, and unambiguous so other skills can consume it without re-reading the source. You write multiple pages per repo when multiple distinct documents are detected — each page is independent.

## MCP Tools Used

| Tool | Purpose |
|------|---------|
| `forge_develop` | Create or resume a code session (git worktree) for the target repo |
| `knowledge_check_duplicates` | Check for an existing page before writing each candidate |
| `knowledge_suggest_metadata` | Get frontmatter field suggestions from Vault |
| `knowledge_validate_page` | Validate each page against schema before writing |
| `knowledge_write_page` | Write each page via git workflow (branch → commit → PR) |
| `knowledge_create_edge` | Create a `DOCS` edge linking each page to the repo node |
| `anvil_update_note` | Update work item status when invoked from a work item |

## Core Workflow

### Phase 1: Session Setup

1. Call `forge_develop` with:
   - `repo`: the target repo name (from the Forge repo index)
   - `workItem`: the work item ID that triggered this scan (if any)
2. On `status: "needs_workflow_confirmation"`: present detected workflow to user, confirm, then re-call with `workflow` parameter.
3. Record `sessionPath` from the response. **All file reads in Phase 2 use `sessionPath` as the root.**

### Phase 2: Detection Pass

Scan the repository for guide and procedure candidates. Read each target path if it exists. Never fail if a file is absent — note its absence and continue.

#### Guide Detection Sources

Guides explain how to use or understand something: concepts, workflows, architecture, and patterns. Collect every distinct candidate — each will become a separate Vault page.

| Source | What to look for | Notes |
|--------|-----------------|-------|
| `README.md` | Sections named Architecture, Overview, How It Works, Design, Concepts, Getting Started (>200 words) | Each qualifying section is a separate candidate |
| `docs/*.md` | Any `.md` file in the `docs/` folder | Each file is a candidate |
| `doc/*.md` | Alternative docs location | Each file is a candidate |
| `wiki/*.md` | Alternative wiki location | Each file is a candidate |
| `CONTRIBUTING.md` | Full file — guide for contributors | Single candidate |
| Long README sections (>200 words) about usage, architecture, or getting started | Extract as standalone guide | Split at `##` boundaries |

**Guide candidate record (internal):**
```
source_path: {relative path under sessionPath}
title_hint: {inferred title from section heading or filename}
content_summary: {key topics covered, 2-3 points}
word_count: {approximate}
confidence: {1-5}  # see scoring rubric
```

#### Procedure Detection Sources

Procedures are step-by-step operational instructions: deployment, setup, debugging, and runbook steps.

| Source | What to look for | Notes |
|--------|-----------------|-------|
| `Makefile` | Each named target with a `##` or `#` comment above it | One candidate per documented target; group related targets into one page if they form a workflow |
| `.github/workflows/*.yml` | Each workflow file | One candidate per workflow |
| `scripts/*.sh` / `scripts/*.bash` | Shell scripts with a comment header (first 5 lines) describing purpose | One candidate per documented script |
| `docker-compose.yml` | Full file — deployment procedure | Single candidate |
| `Dockerfile` | Full file — build procedure | Single candidate |
| `DEPLOY.md` | Full file — deployment procedure | Single candidate |
| `RUNBOOK.md` | Full file — operational runbook | Single candidate |
| `OPERATIONS.md` | Full file — ops procedure | Single candidate |

**Procedure candidate record (internal):**
```
source_path: {relative path under sessionPath}
title_hint: {inferred title from filename, target name, or workflow name}
trigger_condition: {when this procedure is run — from file content or name}
steps_count: {approximate number of steps or targets}
confidence: {1-5}  # see scoring rubric
```

#### Confidence Scoring Rubric

Apply this rubric independently to each candidate:

| Score | Criteria |
|-------|---------|
| 5 | Explicit `docs/` folder file or dedicated `DEPLOY.md`/`RUNBOOK.md`/`OPERATIONS.md` with structured, complete content |
| 4 | `README.md` section with clear heading and >200 words of coherent content; or a well-commented CI workflow with named steps |
| 3 | `CONTRIBUTING.md`, Makefile with documented targets, or scripts with header comments — content is present but implicit |
| 2 | Dockerfile or docker-compose.yml only, or README sections with <200 words or sparse structure |
| 1 | Very sparse signals: uncommented scripts, bare Makefile targets, stub docs |

#### Deduplication

Before generating pages:
- If multiple sources cover the same topic (e.g., `docs/deploy.md` + `DEPLOY.md`), merge into one candidate with the richer source as primary.
- If a README section and a `docs/` file cover the same topic, prefer the `docs/` file (higher confidence signal).
- Do not generate pages for identical or near-identical content from different sources.

#### No Candidates Found

If no guide or procedure candidates are detected after scanning all sources:
- Do not error.
- Report to the user: "No guide or procedure candidates detected in `{repo-name}`. Repo may lack documentation signals."
- Skip Phases 3–5.
- If a work item was provided, set status to `in_review` with a note explaining the absence.

### Phase 3: Generate Pages

For each candidate, produce a complete Vault page using the appropriate template. Fill every section — use "Not found" or "N/A" rather than omitting a section. Set `auto-generated: true` and `confidence` on every page.

#### Guide Page Template

````markdown
---
title: {Repo Name} — {Guide Title}
type: guide
mode: reference
scope:
  repo: {repo-name}
tags: [{language}, {framework-if-any}, {domain-tags}]
description: {1-2 sentence description optimized for agent consumption — what this guide covers and when to consult it}
confidence: {1-5}
auto-generated: true
---

# {Guide Title}

## Overview
{What this guide covers. 2-3 sentences. Write for an agent that has never seen this repo: name the domain, the audience, and the key concepts covered.}

## {Section 1}
{Content extracted or synthesized from source. Preserve structure — use sub-headings if the source uses them.}

## {Section 2}
{Content}

{Add more sections as needed to cover all distinct topics in the source}

## Notes
{Caveats, gaps, or confidence-related warnings. If confidence < 4, state what was missing. If content was extracted from a larger README, note the source section.}
````

#### Procedure Page Template

````markdown
---
title: {Repo Name} — {Procedure Title}
type: procedure
mode: operational
scope:
  repo: {repo-name}
tags: [{language}, {domain-tags}, procedure]
description: {1-2 sentence description: what this procedure does and when to use it}
confidence: {1-5}
auto-generated: true
---

# {Procedure Title}

## When to Use
{Trigger conditions: what event or state should cause an operator or agent to run this procedure. Be specific.}

## Prerequisites
{What must be true before starting. List tools, access, environment variables, or dependencies that must be present. Use "None detected" if not found.}

## Steps
1. {Step 1 — from source content or inferred from script/workflow structure}
2. {Step 2}
{Continue for all steps. Number every step. If steps are conditional, use sub-lists.}

## Expected Outcome
{What success looks like. State the end state, artifact produced, or signal that the procedure completed correctly. Use "Not specified in source" if absent.}

## Troubleshooting
{Common failure modes and fixes, if detectable from source comments, error handling, or known patterns. Use "Not detected in source" if absent.}

## Notes
{Caveats, confidence-related warnings. If inferred from CI config or Makefile rather than explicit docs, state so. If steps were reconstructed rather than directly extracted, note it.}
````

**Template rules:**

- `tags`: use lowercase kebab-case. For guides: include primary language and domain (e.g., `architecture`, `contributing`, `api`, `getting-started`). For procedures: always include `procedure` plus domain (e.g., `deployment`, `ci`, `build`, `runbook`).
- `description`: write as if answering "what is this page and when should an agent consult it?" in one sentence.
- `confidence`: copy the score from your Phase 2 candidate record.
- `scope.repo`: use the repo name from Forge, not the `sessionPath` directory name.
- Do not invent steps or content. If a section has no source material, use "Not detected in source" rather than fabricating.

### Phase 4: Write Each Page via Vault Pipeline

For **each generated page**, follow the Vault write-path pipeline exactly. Never skip or reorder steps. Process pages sequentially — do not batch.

**Step 1 — Check for duplicates:**
```
knowledge_check_duplicates(title: "{page title}", content: {full page markdown})
```
- If a conflict is returned (existing page found): update the existing page instead of creating a new one — use `knowledge_write_page` with the existing page's path.
- If no conflict: proceed to Step 2.

**Step 2 — Suggest metadata:**
```
knowledge_suggest_metadata(content: {full page markdown}, hints: {scope if known})
```
- Review suggestions. Apply any high-confidence suggestions that differ from your draft (e.g., corrected tag values, better domain inference).
- Log any medium/low-confidence suggestions you chose to override, with reasoning.

**Step 3 — Validate:**
```
knowledge_validate_page(content: {full page with frontmatter})
```
- If validation errors are returned: fix them before proceeding. Common fixes:
  - Invalid tag → check registry, use closest valid tag or add via `knowledge_registry_add`
  - Missing required field → add it
  - Invalid type or mode → correct to valid values (`type: guide` + `mode: reference`, `type: procedure` + `mode: operational`)
- Re-validate after fixes until clean.

**Step 4 — Write:**

For guides:
```
knowledge_write_page(
  path: "guides/{repo-name}/{guide-title-slug}.md",
  content: {validated page},
  pr_title: "doc-gen: add guide '{guide-title}' for {repo-name}",
  pr_body: "Auto-generated guide page for {repo-name}. Source: {source_path}. Confidence: {score}/5. Scanner: doc-gen-guide-procedure-scanner v0.2.0.",
  commit_message: "docs(vault): add guide for {repo-name} — {guide-title-slug}"
)
```

For procedures:
```
knowledge_write_page(
  path: "procedures/{repo-name}/{procedure-title-slug}.md",
  content: {validated page},
  pr_title: "doc-gen: add procedure '{procedure-title}' for {repo-name}",
  pr_body: "Auto-generated procedure page for {repo-name}. Source: {source_path}. Confidence: {score}/5. Scanner: doc-gen-guide-procedure-scanner v0.2.0.",
  commit_message: "docs(vault): add procedure for {repo-name} — {procedure-title-slug}"
)
```

- Record the PR URL for each page written.
- If a page write fails, log the failure, skip that page, and continue with the remaining candidates. Do not abort the entire run.

### Phase 5: Create Graph Edges

After each page is successfully written:

```
knowledge_create_edge(
  from: "{page path written above}",
  to: {repo node ID from Forge index},
  edge_type: "DOCS"
)
```

This links the Vault page to the repo node in Neo4j, enabling graph traversal from repo → documentation.

If `knowledge_create_edge` is unavailable or returns an error, log the failure and continue — the page write is the primary artifact.

### Phase 6: Update Work Item (if applicable)

If this skill was invoked from a work item:

- If **all pages** were written successfully:
  ```
  anvil_update_note(id: {work_item_id}, fields: { status: "done" })
  ```
- If **some pages** failed:
  ```
  anvil_update_note(id: {work_item_id}, fields: { status: "in_review" })
  ```
  Include a note listing which pages failed and why.
- If **no candidates** were found:
  ```
  anvil_update_note(id: {work_item_id}, fields: { status: "in_review" })
  ```
  Include a note: "No guide or procedure candidates detected."

## Handling Edge Cases

### No README
- Proceed with source file detection only (Makefile, CI, scripts, docs folder).
- Set confidence ≤ 3 for any guides inferred from non-README sources.
- Note in each page's Notes section: "No README found. Content derived from source analysis."

### README with No Qualifying Sections
- A README exists but all sections are <200 words and none match guide section names.
- Do not generate a guide from it.
- Continue scanning other sources (docs folder, CONTRIBUTING.md, etc.).

### Monorepo
- Scan top-level directory structure only.
- Do not recurse into sub-packages for detection.
- Scope each generated page to the top-level repo name.
- Add `monorepo` tag to all generated pages.
- Note in each page's Notes section: "Source is a monorepo. Page covers top-level documentation only. Sub-package docs may need separate scans."

### Existing Vault Page (Conflict from `knowledge_check_duplicates`)
- Do not create a new page.
- Read the existing page via `knowledge_get_page`.
- Merge new findings into existing content (prefer newer/more complete data).
- Write merged content to the existing path using `knowledge_write_page`.
- PR title: `"doc-gen: update {type} '{title}' for {repo-name}"`

### Undocumented Makefile Targets
- Makefile targets with no comment are low signal (confidence 1).
- Skip targets that are conventional boilerplate (`.PHONY`, `all`, `clean`) unless they have explanatory comments.
- Only generate procedure pages for targets that have either a `##` comment or a clearly descriptive multi-step body.

### CI Workflow with No Named Steps
- A `.github/workflows/*.yml` exists but uses generic step names (`run: make build`).
- Set confidence 2. Generate the procedure page but note in Notes: "Step descriptions reconstructed from commands — no explicit step names in source."

### Partial or Empty docs/ Folder
- A `docs/` folder exists but files are stubs (< 50 words each).
- Set confidence 1 for those files.
- Still generate a page but include a prominent warning in Notes.

### `forge_develop` Session Failure
- If `forge_develop` returns an error: report to user, do not proceed.
- Do not attempt to write any Vault page without a valid session path.

### Multiple Sources for the Same Topic
- Detected via title deduplication in Phase 2.
- Prefer the richer source. Log the discarded source in the page's Notes section: "Additional source detected and merged: `{discarded_path}`."

## Output Summary

When all pages have been processed, report to the user:

```
Guide & Procedure Scanner — Complete

Repo:          {repo-name}
Pages written: {N} ({guides_count} guide(s), {procedures_count} procedure(s))
Pages skipped: {N} (write failures or duplicates — see below)

Written:
  [guide]     {title} — confidence {score}/5 — PR: {URL}
  [procedure] {title} — confidence {score}/5 — PR: {URL}
  ...

Skipped:
  {title} — reason: {failure message or "duplicate, existing page updated"}
  ...

Edges:        DOCS links created for {N} pages (failures: {N})
Work item:    {status updated to "done" / "in_review" / "not applicable"}
```

If no candidates were detected:
```
Guide & Procedure Scanner — No candidates found

Repo:       {repo-name}
Result:     No guide or procedure signals detected.
            Checked: README.md, docs/, CONTRIBUTING.md, Makefile,
                     .github/workflows/, scripts/, Dockerfile,
                     docker-compose.yml, DEPLOY.md, RUNBOOK.md, OPERATIONS.md
Work item:  {status updated to "in_review" / "not applicable"}
```

If any page has confidence < 3, add a per-page warning in the Written list:
```
  Warning: Low confidence ({score}/5). Content is sparse or reconstructed.
           Manual review recommended before relying on this page for agent context.
```
