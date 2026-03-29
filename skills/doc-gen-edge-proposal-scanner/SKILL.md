---
name: doc-gen-edge-proposal-scanner
description: >
  Scans a source repository and proposes knowledge graph edges between Vault
  pages. Part of the doc-gen pipeline.
---

# Doc-Gen — Edge Proposal Scanner

> Status: stub — implementation pending (work item b08bfdb0)

## Purpose

Scans a source repository and proposes knowledge graph edges between existing
Vault pages. Identifies relationships across the 5 supported edge types and
produces edge proposals for review before Neo4j commit. Part of the doc-gen
pipeline.

## When to Use

Invoke this skill after repo-profile pages exist in Vault for the target repo.
The skill reads existing pages and proposes new edges to connect them.

## Inputs

- Target repo name
- Existing Vault page IDs for the repo (from repo-profile scanner output)

## Outputs

- Edge proposal set (source, target, edge type, confidence)
- Edges written to Neo4j after human review
- `auto_generated: true` flag on proposed edges

## Implementation Notes

_To be completed in work item b08bfdb0._
