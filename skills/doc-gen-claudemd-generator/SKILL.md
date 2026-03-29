---
name: doc-gen-claudemd-generator
description: >
  Generates CLAUDE.md files for repositories by synthesizing repo-profile
  Vault pages and knowledge graph context. Part of the doc-gen pipeline.
---

# Doc-Gen — CLAUDE.md Generator

> Status: stub — implementation pending (work item 3743b19c)

## Purpose

Generates `CLAUDE.md` files for repositories by synthesizing `repo-profile`
Vault pages and knowledge graph context. Produces Claude Code-optimized
project instructions with conventions, commands, and architecture overview.
Part of the doc-gen pipeline.

## When to Use

Invoke this skill after repo-profile pages exist in Vault for the target repo.
The skill reads Vault context and writes a `CLAUDE.md` to the repo session
path.

## Inputs

- Target repo name
- Active Forge session path (from `forge_develop`)
- Vault repo-profile page ID for the target repo

## Outputs

- `CLAUDE.md` file written to the Forge session path
- Summary of sections generated

## Implementation Notes

_To be completed in work item 3743b19c._
