---
name: finance-filings-diff
description: >
  Sub-agent that diffs SEC filings (10-K, 10-Q) between two periods and flags material changes in risk factors, MD&A language, segment footnotes, and critical accounting estimates. Materiality scored, not character-count scored. Primary caller: finance-equity-analyst.
---

# Filings Diff

## Purpose

Narrative drift lives in the filings, not the press release. When a company quietly softens a risk factor, rewrites its revenue recognition policy, or restates a critical accounting estimate, that's a catalyst tell nobody's pricing yet. Reading every 10-Q cover-to-cover for twenty names is how the analyst misses the one that matters. This sub-agent does the reading and surfaces the deltas that move a thesis.

## Primary caller

`finance-equity-analyst`. The analyst lives in filings. The analyst needs a sub-agent that reads the ones they don't have time for and flags only the changes that can break or confirm a thesis.

## Responsibility

Given a ticker and two filing periods (or "latest vs prior"), produce a structured diff of the sections that matter, scored by *materiality* to the business — not by how many words changed. A paragraph reshuffle with no meaning should score zero. A single phrase removed from a critical accounting estimate should score high.

## Inputs

- `ticker` (string, required)
- `filing_type` (enum, required) — `10-K`, `10-Q`, or `both`
- `period_from` (string, required) — filing date or "previous" (auto-resolves to the prior period)
- `period_to` (string, required) — filing date or "latest"
- `sections` (list, optional) — filter to specific sections; default is `[risk_factors, mda, segment_footnotes, critical_accounting_estimates, revenue_recognition, legal_proceedings]`
- `materiality_threshold` (enum, optional) — `all`, `material`, `high` — default `material`

## Outputs

- `section_deltas` — list of objects, one per changed section:
  - `section` — the section name
  - `change_type` — `added`, `removed`, `modified`
  - `from_text` — the prior language (may be empty for `added`)
  - `to_text` — the new language (may be empty for `removed`)
  - `materiality_score` — 0-10
  - `materiality_rationale` — one-line explanation of why this matters (e.g. "revenue recognition now includes new performance obligation criteria for subscription renewals")
  - `catalyst_tag` — optional tag like `guidance_change`, `accounting_policy`, `risk_softening`, `litigation_update`, `segment_realignment`
- `summary` — one paragraph summarizing the top 3 deltas by materiality
- `variant_perception_hooks` — any changes that suggest consensus hasn't caught up

## When to invoke

- Every time a new 10-Q hits for a name in the coverage universe
- When building or defending a thesis — pull the most recent two filings and see what changed
- When the tape is telling you something the model doesn't know yet — the filings may have already hinted at it

## When NOT to invoke

- For sentiment or tone — use `finance-transcript-parser` for calls, not for filings
- For price-target generation — this sub-agent produces evidence, not valuations
- For quick news summaries — filings are slow signal; news is fast noise

## Caveats — shell-only phase 2 artifact

This sub-agent describes an interface. No SEC EDGAR wiring in phase 2. The materiality scoring is the hard part — in phase 2 it's a stubbed heuristic; future phases should wire it to a domain-specific LLM prompt or a trained classifier. Section parsing for XBRL-tagged vs plain-text filings is also deferred.

## Cross-callers

- `finance-swing-trader` — occasionally, for one thing: guidance changes and buyback authorizations, because those move tape
- `finance-portfolio-manager` — when a position's thesis is being questioned and the PM wants evidence without asking the analyst to re-write a memo
- `finance-allocator` — rarely, for long-duration disclosures: capital-return policy, pension obligations, debt maturity wall
- `finance-quant` — as a feature source: turn 10-K/10-Q language into structured features that can be tested across a universe
