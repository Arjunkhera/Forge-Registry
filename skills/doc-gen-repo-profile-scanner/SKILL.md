---
name: doc-gen-repo-profile-scanner
description: >
  Analyzes a source repository via a Forge code session and generates a
  structured repo-profile Vault page. Part of the doc-gen pipeline.
---

# Doc-Gen — Repo Profile Scanner

> Status: stub — implementation pending (work item 9b53c99f)

## Purpose

Analyzes a source repository via a Forge code session and generates a
structured `repo-profile` Vault page. Part of the doc-gen pipeline.

## When to Use

Invoke this skill after `forge_develop` has created a session for the target
repo. The skill reads the repo contents and produces Vault pages.

## Inputs

- Active Forge session path (from `forge_develop`)
- Target repo name

## Outputs

- `repo-profile` Vault page written via write-path pipeline
- Repo node created in Neo4j
- Confidence score (1–5) on generated content
- `auto_generated: true` flag on output
- Registry entry created via PR (see Phase: Registry Update below)

## Phase: Registry Update (mandatory)

After writing the repo-profile page via `knowledge_write_page`, the scanner **must** register the repo in the Vault registry. This is non-optional — without it, the repo will not appear in alias-based `resolve_context` lookups.

### When to run
Immediately after `knowledge_write_page` succeeds. Extract `repo_name` and `aliases` from the generated profile frontmatter.

### How to call

```
knowledge_registry_add({
  registry: "repos",
  entry: {
    id: "<repo_name>",                      // canonical name (e.g. "horus")
    description: "<one-line description>",
    aliases: ["<alias1>", "<alias2>", ...], // sub-service names from frontmatter
  },
  via_pr: true,  // write to git branch + open PR, do not edit in-place
})
```

### Response
- On success: `{ added: true, pr_url: "https://github.com/..." }` — log the PR URL
- On `duplicate_entry` error: repo already registered — skip silently, log at DEBUG
- On any other error: log at WARN but do NOT fail the overall scan (non-blocking)

### Example (horus monorepo)
```
knowledge_registry_add({
  registry: "repos",
  entry: {
    id: "horus",
    description: "Horus pnpm monorepo containing all Horus services and packages",
    aliases: ["vault", "anvil", "forge", "vault-mcp", "vault-router", "cli", "search", "ui"],
  },
  via_pr: true,
})
```

## Implementation Notes

_Full 6-phase scanner implementation pending (work item 9b53c99f). Registry update phase specified above in b0e37ad3._
