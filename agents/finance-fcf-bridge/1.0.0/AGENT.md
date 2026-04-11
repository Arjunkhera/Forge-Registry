---
id: finance-fcf-bridge
name: FCF Bridge Builder
---

# FCF Bridge Builder

## Purpose

The analyst doesn't trust consensus EBITDA multiples and doesn't trust their own spreadsheet more than once. This sub-agent builds the reconciliation from reported EBITDA down to unlevered free cash flow for a ticker over a period range, with every add-back, working-capital swing, and "one-time" charge traced to the source line in the filings. If the bridge doesn't tie, the thesis doesn't ship.

## Primary caller

`finance-equity-analyst`. The analyst's core discipline is "show me the free cash flow, not the EBITDA". This is the tool that makes that discipline operational on every name in the coverage universe.

## Responsibility

Given a ticker and a period range, pull the P&L, cash flow statement, and footnotes, and produce a line-traced reconciliation from reported EBITDA to unlevered FCF. Every non-trivial adjustment must carry a source reference back to the filing line it came from. Flag any period where the bridge fails to tie.

## Inputs

- `ticker` (string, required)
- `period_range` (required) — e.g. `LTM`, `FY2022-FY2025`, `Q1-Q4 2025`
- `adjustment_policy` (enum, optional) — `company_defined`, `analyst_defined`, `both`. `company_defined` accepts management's adjustments; `analyst_defined` uses a stricter policy (e.g. SBC is not an add-back, restructuring charges are not non-recurring if they recur)
- `trace_depth` (enum, optional) — `summary`, `detailed`, `line_level` — default `detailed`

## Outputs

- `bridge` — ordered list of bridge steps, each with: starting value, adjustment, ending value, source filing + line reference, category tag
- `unlevered_fcf` — final number at the bottom of the bridge
- `bridge_ties` — boolean + tie-out delta if it doesn't
- `adjustment_breakdown` — grouped by category: D&A, SBC, working capital, capex, taxes, one-times, non-operating
- `recurring_one_times` — flag any "one-time" charges that have occurred in more than 2 of the last 8 quarters — these are not one-time
- `fcf_conversion_ratio` — unlevered FCF / EBITDA, with a trend line over the period range
- `capex_intensity` — capex / revenue, to catch maintenance vs growth ambiguity
- `sbc_adjusted_fcf` — FCF with stock-based comp treated as a real cash cost, for the strict analyst view
- `notes` — any judgment calls made during the bridge, flagged for analyst review

## When to invoke

- Before accepting any EBITDA-based valuation multiple
- When comparing two companies that look cheap on EBITDA — the one with the worse FCF conversion is rarely actually cheap
- When a thesis depends on a margin expansion or a capex cycle
- Before writing the valuation section of any note

## When NOT to invoke

- For a flash take — this sub-agent is precise, not fast
- For companies that don't have meaningful non-cash items or where FCF ≈ net income (banks, some financials) — the bridge adds no value
- For DCF modeling or terminal-value work — this sub-agent supplies the inputs; it does not value

## Caveats — shell-only phase 2 artifact

This sub-agent describes an interface. Phase 2 does not wire filings ingestion or financial data APIs. The bridge logic is the easy part; the hard part is correctly categorising adjustments across reporting standards (GAAP vs IFRS, US vs non-US), which is deferred. Line-level source tracing is the most valuable feature and the most stubbed.

## Cross-callers

- `finance-portfolio-manager` — rarely, to sanity-check a position's reported earnings quality before sizing up
- `finance-allocator` — for long-duration valuation work on individual holdings inside a sleeve
