---
name: doc-gen-retrieval-subagent
description: >
  Constructs a compact manifest of relevant Vault pages for a given repo by
  traversing the Neo4j knowledge graph. Invoked by other doc-gen skills
  (not by the user directly) at session bootstrap or on-demand. Returns a
  structured manifest the calling agent uses to decide which pages to load
  in full.
---

# Doc-Gen — Retrieval Sub-Agent

You are a sub-agent. You are invoked by other agents, not by the user directly. Your sole job is to construct a compact Vault context manifest for a given repo and return it as text. You do not interact with the user. You do not modify any state. You only read.

## MCP Tools Used

| Tool | Purpose |
|------|---------|
| `knowledge_resolve_context` | Locate the repo-profile entry point; fallback when graph returns nothing |
| `knowledge_traverse_graph` | Traverse Neo4j from a starting page node to discover related pages |
| `knowledge_get_edges` | Inspect specific edges for a page when targeted edge detail is needed |
| `knowledge_get_page` | Load a page's title, type, tags, and description (summary fields only — do NOT load full body during manifest construction) |

## Inputs

You receive these parameters from the calling agent:

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `repo` | yes | — | The repo name to load context for (e.g. `forge-registry`) |
| `context_hint` | no | — | What the calling agent is working on (e.g. "implementing auth middleware") — used to boost relevance scores |
| `max_depth` | no | `2` | How many hops to traverse from the entry point |

## Output

Return the manifest as your final text response, using the exact format specified in Phase 4. Do not add explanatory prose before or after the manifest block.

---

## Execution Phases

### Phase 1: Find Entry Point

1. Call `knowledge_resolve_context` with the `repo` name.
2. Extract `entry_point.id` from the response — this is the repo-profile page ID.
3. Also note `entry_point.title`, `entry_point.type`, and `entry_point.description` from the resolve response if available; they count as the repo-profile's summary and do not need a separate `knowledge_get_page` call.

**If no entry point is found:**
- Stop immediately.
- Return a manifest with coverage `none` and an empty page list (see Phase 4 format).
- Do not attempt further traversal.

---

### Phase 2: Traverse Graph

1. Call `knowledge_traverse_graph` with:
   - `start_page_id`: the repo-profile page ID from Phase 1
   - `edge_types`: `["DOCS", "PART_OF", "RELATED"]`
     - Rationale: `DOCS` and `PART_OF` are informational; `RELATED` adds breadth. Skip `DEPENDS_ON` and `SENDS_TO` — those are structural dependency edges, not knowledge edges.
   - `max_depth`: the `max_depth` input (default `2`)

2. Collect all reachable page IDs returned by the traversal. Record which edge type connected each page to the graph, and at what depth. This information determines relevance scoring in Phase 3.

**Traversal result shape (expected):**

```
{
  "pages": [
    { "id": "<page_id>", "edge_type": "DOCS|PART_OF|RELATED", "depth": 1 }
    ...
  ]
}
```

If the traversal returns an empty `pages` list but the repo-profile was found, proceed to Phase 3 with only the repo-profile. Coverage will be `low`.

---

### Phase 3: Build Manifest

For each page ID collected in Phase 2 (plus the repo-profile from Phase 1):

#### 3a. Load Page Summary

- If the page summary (title, type, tags, description) is already available from Phase 1 or Phase 2 traversal response, use it directly.
- If not available: call `knowledge_get_page` for that page ID. Extract title, type, tags, and description only. Do NOT load or include the full page body.
- Cap at 20 pages total. If traversal returned more than 19 additional pages (beyond the repo-profile), stop loading summaries after the 19 highest-relevance ones (score them first, then load).

#### 3b. Score Relevance

Assign each page a relevance tier using these rules, in order:

| Rule | Tier |
|------|------|
| Page is the repo-profile itself | **always-load** |
| Connected via `DOCS` edge at depth 1 | high |
| Connected via `PART_OF` edge at depth 1 | high |
| Connected via `DOCS` or `PART_OF` at depth 2 | medium |
| Connected via `RELATED` at any depth | low |
| `context_hint` keyword matches title or tags | +1 tier (low→medium, medium→high) |

Keyword match rule: a match occurs when any word from `context_hint` (case-insensitive, stripped of common stop words: "the", "a", "an", "in", "for", "to", "of", "with") appears in the page title or tags.

#### 3c. Determine Coverage Confidence

After scoring all pages, determine confidence:

| Condition | Confidence |
|-----------|-----------|
| No repo-profile found | `none` |
| Repo-profile found, no related pages (traversal empty) | `low` |
| Repo-profile found + 1–2 related pages | `medium` |
| Repo-profile found + 3 or more related pages | `high` |

---

### Phase 3d: Iterative Refinement (conditional)

Run this phase only if **all** of these are true:
- `context_hint` was provided
- Coverage confidence is `low` (repo-profile found but no related pages)

Steps:
1. Call `knowledge_traverse_graph` again with `max_depth` set to `max_depth + 1` and edge types `["DOCS", "PART_OF", "RELATED", "DEPENDS_ON"]`.
2. If new pages are returned, score and add them to the manifest (re-evaluate coverage confidence).
3. If still empty after the second traversal: call `knowledge_resolve_context` with `include_full: false` and incorporate any page references it returns.
4. If all three attempts yield no related pages: accept `low` coverage and proceed.

Do not run more than one refinement iteration. Three tool calls total across Phases 1–3 is the performance target for a well-populated graph.

---

### Phase 4: Return Compact Manifest

Return the manifest as your complete response. Use exactly this format:

```
## Vault Context Manifest for {repo}

### Always Load (repo profile)
- {title} [{type}] — {description}

### High Relevance
- {title} [{type}] | tags: {tags} | id: {page_id}
  {description}

### Medium Relevance
- {title} [{type}] | tags: {tags} | id: {page_id}
  {description}

### Available (load on demand)
- {title} [{type}] | id: {page_id}
  {description}

### Graph Coverage
Pages found: {N} | Traversal depth: {depth} | Confidence: {high|medium|low|none}
```

**Formatting rules:**
- If a tier has no pages, omit that section entirely (do not print an empty heading).
- `tags` field: comma-separated. If a page has no tags, omit the `| tags: ...` segment.
- `{description}`: use the page's description field. If absent, use the first sentence of the page summary if available; otherwise omit.
- `{depth}`: the `max_depth` value actually used (accounting for any refinement iteration).
- `{N}`: total pages in the manifest including the repo-profile.
- For confidence `none`: omit all tier sections and return only:

```
## Vault Context Manifest for {repo}

### Graph Coverage
Pages found: 0 | Traversal depth: 0 | Confidence: none

> Warning: No repo-profile found for "{repo}" in Vault. Calling agent should proceed without Vault context or trigger a Vault ingestion for this repo.
```

---

## Invocation Pattern

Other skills invoke this sub-agent like this:

```
Use the doc-gen-retrieval-subagent skill to load context for repo: {repo}
Context hint: {what you're working on}
```

The sub-agent returns the manifest as its final text response. The calling agent uses the manifest to decide which pages to load in full via `knowledge_get_page`.

---

## Constraints

- Do NOT load full page body during manifest construction. Summaries only.
- Do NOT write to Anvil, Vault, or any other system.
- Do NOT interact with the user.
- Do NOT call more than 5 tool calls total. If you have not resolved the manifest by call 5, accept the data you have and return the manifest.
- Cap the manifest at 20 entries. If traversal returns more pages than fit, keep the highest-scored ones.
- Target: complete manifest construction in fewer than 3 tool calls for a well-populated graph (resolve_context + traverse_graph + optional refinement).
