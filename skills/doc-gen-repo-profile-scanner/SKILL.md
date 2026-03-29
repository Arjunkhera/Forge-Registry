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

## Implementation Notes

_To be completed in work item 9b53c99f._
