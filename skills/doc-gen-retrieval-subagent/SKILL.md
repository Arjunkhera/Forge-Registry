---
name: doc-gen-retrieval-subagent
description: >
  Subagent that retrieves and synthesizes Vault knowledge for doc-gen pipeline
  stages. Part of the doc-gen pipeline.
---

# Doc-Gen — Retrieval Subagent

> Status: stub — implementation pending (work item 5456c682)

## Purpose

Subagent that retrieves and synthesizes Vault knowledge for doc-gen pipeline
stages. Resolves repo context, fetches related pages via Neo4j graph
traversal, and returns structured briefings for other doc-gen skills. Part of
the doc-gen pipeline.

## When to Use

Invoke this subagent at the start of any doc-gen pipeline stage that requires
Vault context. Other doc-gen skills delegate context loading to this subagent
rather than querying Vault inline.

## Inputs

- Caller skill name
- Target repo name
- Requested context types (e.g., repo-profile, related guides, graph edges)

## Outputs

- Structured briefing with resolved Vault pages
- Related page IDs and edge summaries from Neo4j
- Gap list (context that could not be resolved)

## Implementation Notes

_To be completed in work item 5456c682._
