---
name: doc-gen-edge-proposal-scanner
description: >
  Scans a source repository and proposes all 5 knowledge graph edge types
  (PART_OF, DEPENDS_ON, SENDS_TO, DOCS, RELATED). Writes edges directly to
  Neo4j via the knowledge_create_edge API without blocking for human review.
  Part of the doc-gen pipeline.

  Invoke when the user asks to "scan edges for a repo", "detect relationships
  for repo X", "propose graph edges for X", or when the doc-gen orchestrator
  triggers edge scanning as part of a full pipeline run.
---

# Doc-Gen — Edge Proposal Scanner

You scan a source repository and detect all five knowledge graph edge types: `PART_OF`, `DEPENDS_ON`, `SENDS_TO`, `DOCS`, and `RELATED`. You write edges directly to Neo4j via `knowledge_create_edge` — no human approval gate. Human review happens asynchronously via the `auto_generated` flag already present on all edges. BLOCKING only occurs for entirely new edge taxonomy values not in the standard five types — escalate those to `doc-gen-human-verification`.

## MCP Tools Used

| Tool | Purpose |
|------|---------|
| `forge_develop` | Create or resume a code session (git worktree) for the target repo |
| `knowledge_resolve_context` | Resolve Vault page IDs for repos by name (for edge target validation) |
| `knowledge_get_edges` | Check existing edges before writing to prevent duplicates |
| `knowledge_create_edge` | Write each detected edge to Neo4j |
| `anvil_update_entity` | Update work item status when invoked from a work item |

## Core Workflow

### Phase 1: Session Setup

1. Call `forge_develop` with:
   - `repo`: the target repo name (from the Forge repo index)
   - `workItem`: the work item ID that triggered this scan (if any)
2. On `status: "needs_workflow_confirmation"`: present the detected workflow to the user, confirm, then re-call with the `workflow` parameter.
3. Record `sessionPath` from the response. **All file reads in Phase 2 use `sessionPath` as the root.**
4. Record the repo's Vault page ID:
   ```
   knowledge_resolve_context(repo: {repo-name})
   ```
   Store the returned page path as `sourcePagePath` and the node ID as `sourceNodeId`. If unresolvable, note it — DOCS edges cannot be written without this.

### Phase 2: File Discovery

Read each of the following files if they exist under `sessionPath`. Never fail if a file is absent — note its absence and continue.

| File / Path | Used for |
|-------------|---------|
| `package.json` | PART_OF (workspaces), DEPENDS_ON (dependencies/devDependencies) |
| `pnpm-workspace.yaml` | PART_OF (pnpm monorepo) |
| `lerna.json` | PART_OF (lerna monorepo) |
| `pyproject.toml` | PART_OF (Python workspace), DEPENDS_ON |
| `requirements.txt` | DEPENDS_ON |
| `go.mod` | DEPENDS_ON (Go modules) |
| `Cargo.toml` | DEPENDS_ON (Rust crates) |
| `README.md` | RELATED (cross-references to other known repos) |
| Top-level directory listing | PART_OF (sub-package heuristic), SENDS_TO (config scanning) |
| `docker-compose.yml` / `.env` / config files | SENDS_TO (queue/webhook endpoints) |
| Up to 50 import lines from main source files | DEPENDS_ON (import-based), SENDS_TO (HTTP client patterns) |

Collect all signals into the internal `edge_candidates` structure described in Phase 3.

### Phase 3: Edge Detection

Produce an internal `edge_candidates` list. Each entry has:

```
{
  edge_type:    {PART_OF | DEPENDS_ON | SENDS_TO | DOCS | RELATED}
  from:         {Vault page path or node ID of source}
  to:           {Vault page path or node ID of target}
  confidence:   {1-5}
  mechanism:    {how the relationship works, e.g. "npm dependency"}
  role:         {semantic role, e.g. "runtime dependency"}
  signal:       {what file/pattern triggered this — for logging only}
  target_repo:  {repo name string — used to validate via knowledge_resolve_context}
}
```

Apply the detection strategies below. Gather all candidates before writing any edges (Phase 4 validates and deduplicates first).

---

#### 3.1 PART_OF Detection

A PART_OF edge means: the scanned repo is a sub-component of a larger parent repo/workspace.

**Signals (check in order — use highest-confidence match):**

| Signal | How to detect | Confidence |
|--------|---------------|-----------|
| `package.json` has `"workspaces"` field | The scanned repo is the monorepo root itself, or a package listed in a parent's workspaces array | 5 |
| `pnpm-workspace.yaml` exists at session root | Scanned repo is a pnpm monorepo; each listed package path gets a PART_OF edge pointing to this repo | 5 |
| `lerna.json` exists at session root | Scanned repo is a Lerna-managed monorepo root | 5 |
| `pyproject.toml` contains `[tool.poetry.packages]` or multiple `[project]` sections | Python workspace | 5 |
| Repo name contains `/` or follows `{parent}-{child}` naming and a parent repo exists in Vault | Repo name heuristic | 3 |
| Scanned session path is a sub-directory inside another registered repo's worktree | Directory heuristic | 3 |

**Construction:**
- For monorepo roots: propose PART_OF edges FROM each sub-package TO this repo.
- For sub-packages: propose PART_OF edge FROM this repo TO the parent repo.
- `mechanism`: `"npm workspaces"` / `"pnpm workspaces"` / `"lerna"` / `"pyproject workspace"` / `"directory heuristic"`
- `role`: `"workspace member"` (sub-package) or `"workspace root"` (parent)
- Always validate target repo via `knowledge_resolve_context` before adding to candidates. If target not in Vault, skip.

---

#### 3.2 DEPENDS_ON Detection

A DEPENDS_ON edge means: the scanned repo explicitly requires another component to function.

**Signals:**

| Source file | Pattern | Confidence |
|-------------|---------|-----------|
| `package.json` → `dependencies` | Direct package dependency | 5 |
| `package.json` → `devDependencies` | Dev-only dependency | 5 |
| `requirements.txt` | Any listed package | 5 |
| `pyproject.toml` → `[project.dependencies]` or `[tool.poetry.dependencies]` | Any listed package | 5 |
| `go.mod` → `require` block | Any listed module | 5 |
| `Cargo.toml` → `[dependencies]` or `[dev-dependencies]` | Any listed crate | 5 |
| Source imports (top 50 lines per main file) | `import X`, `require('X')`, `from X import` | 3 |

**Filtering rule (critical):** Only propose a DEPENDS_ON edge if the dependency name resolves to a known Vault repo. Call `knowledge_resolve_context(repo: {dep-name})` for each candidate. Skip those that do not resolve — do not create edges to external open-source packages unless they have a Vault page.

**Construction:**
- `from`: the scanned repo's Vault page path
- `to`: the resolved dependency's Vault page path
- `mechanism`:
  - Package manifest dependency: `"npm dependency"` / `"pip dependency"` / `"go module"` / `"cargo crate"`
  - Import-only (no manifest entry): `"source import"`
- `role`:
  - `dependencies` (package.json) or runtime: `"runtime dependency"`
  - `devDependencies` or test/lint tools: `"build dependency"`
  - Import-only: `"inferred dependency"`

---

#### 3.3 SENDS_TO Detection

A SENDS_TO edge means: the scanned repo publishes messages, emits events, or makes outbound HTTP/RPC calls to another known repo.

**Signals:**

| Pattern | Where to scan | Confidence |
|---------|--------------|-----------|
| Queue publish calls: `publish(`, `send(`, `emit(`, `produce(`, `enqueue(` | Source files | 2 |
| HTTP client calls: `fetch(`, `axios.`, `requests.get(`, `requests.post(`, `http.Client`, `urllib` | Source files | 2 |
| Config/env values: `RABBITMQ_`, `KAFKA_`, `SQS_`, `PUBSUB_`, `WEBHOOK_`, endpoint URLs | `.env`, `config.*`, `docker-compose.yml` | 4 |
| Explicit service name in config: e.g. `TARGET_SERVICE=payment-service` | Config files | 4 |

**Filtering rule:** Only propose a SENDS_TO edge if the target resolves to a known Vault repo via `knowledge_resolve_context`. Pattern matches alone (confidence 2) without a Vault-resolvable target are discarded.

**Confidence upgrade rule:** If a config endpoint (confidence 4) and a source-level publish pattern (confidence 2) both point to the same target, upgrade combined confidence to 5.

**Construction:**
- `from`: scanned repo's Vault page path
- `to`: target repo's Vault page path
- `mechanism`:
  - Queue: `"message queue"` (refine to `"RabbitMQ"`, `"Kafka"`, `"SQS"` if detectable from config key names)
  - HTTP: `"HTTP call"` (refine to `"REST"` or `"webhook"` if pattern matches)
  - Event emitter: `"event emitter"`
- `role`:
  - Queue publisher: `"data publisher"`
  - HTTP call: `"service consumer"`
  - Event emitter: `"event source"`

---

#### 3.4 DOCS Detection

A DOCS edge means: a Vault page documents a repo. This links generated Vault pages to their target repos.

**When to create:**
- A Vault page (repo-profile, guide, procedure) was previously generated for this repo by the doc-gen pipeline.
- The page is identifiable via `knowledge_resolve_context(repo: {repo-name})`.

**Construction:**
- `from`: the Vault page path (e.g., `repos/{repo-name}.md`)
- `to`: the repo node ID from the Forge index
- `confidence`: always 5 — this is a definitive known relationship
- `mechanism`: `"doc-gen pipeline"`
- `role`: `"documentation"`

**Note:** DOCS edges are typically created by the repo-profile and guide/procedure scanners when they write pages. This skill creates DOCS edges only if it discovers existing Vault pages for the target repo that lack a corresponding DOCS edge (detected via `knowledge_get_edges`).

---

#### 3.5 RELATED Detection

A RELATED edge means: two repos share topical overlap or co-reference each other, suggesting loose association.

**Signals:**

| Signal | How to detect | Confidence |
|--------|---------------|-----------|
| README or docs reference another known repo by name | Scan README.md for repo name strings that resolve via `knowledge_resolve_context` | 2 |
| Two repos share 2+ matching tags in their Vault page descriptions | Compare tags from `knowledge_resolve_context` results | 2 |

**Construction:**
- `from`: scanned repo's Vault page path
- `to`: referenced/related repo's Vault page path
- `confidence`: always 2
- `mechanism`: `"co-reference"` (README mention) or `"shared tags"` (tag overlap)
- `role`: `"related component"`

**Important:** RELATED edges are bidirectional in intent but written as directed edges FROM the scanned repo TO the related repo. Do not write both directions — the graph schema handles traversal in both directions.

---

### Phase 4: Deduplication and Write

For each entry in `edge_candidates`:

**Step 1 — Check for existing edge:**
```
knowledge_get_edges(from: {from}, to: {to}, edge_type: {edge_type})
```
- If an edge already exists with the same `from`, `to`, and `edge_type`: **update** it rather than creating a duplicate.
  - If the new confidence score is higher than the existing one, call `knowledge_create_edge` with `upsert: true` to update.
  - If the existing confidence is equal or higher and mechanism/role match, skip — no write needed.
  - If mechanism or role differ from existing (new signal found), call with `upsert: true` to update properties.
- If no existing edge: proceed to Step 2.

**Step 2 — Check for new taxonomy values:**
- The five valid edge types are: `PART_OF`, `DEPENDS_ON`, `SENDS_TO`, `DOCS`, `RELATED`.
- If your detection yields a relationship that does not fit any of these five types, **STOP and invoke `doc-gen-human-verification`** before proceeding. Do not invent edge type names.

**Step 3 — Write the edge:**
```
knowledge_create_edge(
  from:       {from},
  to:         {to},
  edge_type:  {edge_type},
  properties: {
    confidence:     {1-5},
    mechanism:      {mechanism string},
    role:           {role string},
    auto_generated: true,
    scanner:        "doc-gen-edge-proposal-scanner",
    scanner_version: "0.2.0"
  }
)
```

**Step 4 — Log the result:**
For each write attempt, record:
```
{edge_type} | {from} → {to} | confidence: {score} | status: {written|updated|skipped|failed}
```

Continue processing all remaining candidates even if one write fails. Collect all failures for the final report.

### Phase 5: Update Work Item (if applicable)

If this skill was invoked from a work item:

**On full success (all candidates written or intentionally skipped):**
```
anvil_update_entity(id: {work_item_id}, fields: { status: "done" })
```

**On partial failure (some writes failed):**
```
anvil_update_entity(id: {work_item_id}, fields: { status: "in_review" })
```
Include a note in the work item's notes field listing which edges failed and the error messages.

**On total failure (session setup failed or no Vault page found for source repo):**
```
anvil_update_entity(id: {work_item_id}, fields: { status: "blocked" })
```

## Handling Edge Cases

### No Vault Page for Scanned Repo
- If `knowledge_resolve_context` cannot resolve the scanned repo: log a warning.
- DEPENDS_ON, SENDS_TO, and RELATED edges require a valid `from` page — they cannot be written without it.
- DOCS edges: attempt to write using the Forge repo node ID as `to`, and skip `from` if unresolvable.
- Set work item to `blocked` if this prevents all edge writes.

### Target Repo Not in Vault
- DEPENDS_ON and SENDS_TO edges: skip silently. Log: `"skipped: {dep-name} not in Vault"`.
- Do not create stub pages — that is the repo-profile scanner's responsibility.

### `forge_develop` Session Failure
- If `forge_develop` returns an error: report to user, set work item to `blocked`, do not proceed.

### Monorepo Root Scanned
- PART_OF detection scans the workspace config and proposes edges for all listed sub-packages.
- Do not recurse into sub-packages to scan their individual dependencies — treat each sub-package as a separate scan target.
- DEPENDS_ON and SENDS_TO: analyze only the root-level manifests and source files (e.g., shared utilities at the top level).

### Re-Run Idempotency
- All writes use the deduplication check in Phase 4, Step 1.
- A re-run on a fully-scanned repo results in zero new writes and zero errors (all edges are `skipped` with reason `"already exists"`).
- If source files changed since last run (new dependencies added), updated edges are written with `upsert: true`.

### `knowledge_get_edges` Unavailable
- If `knowledge_get_edges` returns an error or is unavailable: proceed with writes using `upsert: true` on `knowledge_create_edge`. This is safe — upsert prevents true duplicates at the Neo4j layer.
- Log: `"deduplication check unavailable — using upsert mode"`.

### Confidence Score Conflicts
- If two signals for the same edge type + same target pair produce different confidence scores, take the **maximum** score.
- Record both signals in the `mechanism` property, comma-separated.

## Confidence Scoring Reference

| Score | Meaning |
|-------|---------|
| 5 | Multiple corroborating signals, or a single definitive signal (e.g., explicit config, known DOCS relationship) |
| 4 | Strong single signal (e.g., config endpoint matches known repo, package manifest entry) |
| 3 | Heuristic or pattern match with good supporting context (e.g., naming convention, directory structure) |
| 2 | Weak signal — plausible but unverified (e.g., README mention, shared tags, import-only) |
| 1 | Speculative or inferred — no direct evidence, derived from indirect context |

## Output Summary

When complete, report to the user:

```
Edge Proposal Scanner — Complete

Repo:           {repo-name}
Session:        {sessionPath}

Edges proposed:
  PART_OF:    {n written} written, {n updated} updated, {n skipped} skipped, {n failed} failed
  DEPENDS_ON: {n written} written, {n updated} updated, {n skipped} skipped, {n failed} failed
  SENDS_TO:   {n written} written, {n updated} updated, {n skipped} skipped, {n failed} failed
  DOCS:       {n written} written, {n updated} updated, {n skipped} skipped, {n failed} failed
  RELATED:    {n written} written, {n updated} updated, {n skipped} skipped, {n failed} failed

Work item:      {status updated / not applicable}
```

If any edges failed, list them:
```
Failed edges:
  - {edge_type} | {from} → {to} | error: {error message}
```

If all candidates were skipped (idempotent re-run):
```
Note: All candidates already exist in the graph. No writes performed.
```

If `doc-gen-human-verification` was triggered for a new taxonomy value:
```
Blocked: Encountered unknown relationship type "{type}". Escalated to doc-gen-human-verification.
Remaining candidates will be processed after verification completes.
```
