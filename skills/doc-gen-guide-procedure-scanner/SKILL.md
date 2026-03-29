---
name: doc-gen-guide-procedure-scanner
description: >
  Analyzes a source repository and generates structured guide and procedure
  Vault pages. Part of the doc-gen pipeline.
---

# Doc-Gen — Guide & Procedure Scanner

> Status: stub — implementation pending (work item 611b46eb)

## Purpose

Analyzes a source repository and generates structured `guide` and `procedure`
Vault pages. Extracts repeatable workflows, setup steps, and operational
runbooks from the codebase. Part of the doc-gen pipeline.

## When to Use

Invoke this skill after `forge_develop` has created a session for the target
repo. The skill reads the repo contents and produces Vault guide and procedure
pages.

## Inputs

- Active Forge session path (from `forge_develop`)
- Target repo name

## Outputs

- `guide` and/or `procedure` Vault pages written via write-path pipeline
- Confidence score (1–5) on generated content
- `auto_generated: true` flag on output

## Implementation Notes

_To be completed in work item 611b46eb._
