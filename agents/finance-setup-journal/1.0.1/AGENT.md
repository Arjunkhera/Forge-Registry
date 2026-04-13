---
name: finance-setup-journal
description: >
  Sub-agent that ingests trade records (entry notes, screenshots, post-mortems) and files them against a setup taxonomy with outcome tagged. Maintains a per-setup library with hit rate, average R-multiple, and average hold time. Primary caller: finance-swing-trader.
---

# Setup Journal

## Purpose

The only way a discretionary trader actually learns is by filing every trade against a setup taxonomy and watching the hit rate, average R-multiple, and average hold time of each setup evolve over time. Without this, every losing streak feels like bad luck and every winning streak feels like skill. With it, the trader can see that their B+ breakout-retest setup actually hits 55% at 1.8R — or that their A+ gap-fill setup has decayed to a coin flip since the regime changed.

## Primary caller

`finance-swing-trader`. The trader's conviction comes from setup clarity. Setup clarity comes from having enough history on each pattern to know whether it's real or flattery. The trader will not maintain a journal by hand. This sub-agent is the discipline layer.

## Responsibility

Ingest a trade record (entry reasoning, entry screenshot, post-mortem, exit reason), classify it against the setup taxonomy, store it, and return updated statistics for that setup. Surface when a setup's performance has meaningfully degraded.

## Inputs

- `trade_record` (object, required) — ticker, direction, entry price, stop, exit price, entry timestamp, exit timestamp, entry notes, exit notes, screenshots (paths or references)
- `setup_tag` (string, required) — from the taxonomy: `breakout-retest`, `failed-breakdown`, `gap-fill`, `range-expansion`, `trend-pullback`, `climax-fade`, `base-breakout`, `earnings-drift`, `sympathy`, `other` (flagged)
- `conviction_tier` (enum, required) — `A+`, `A`, `B+`, `B` — the tier the trader assigned at entry
- `market_phase` (enum, required) — `trend`, `range`, `transition`, `climaxing` — the tape-reader phase at entry

## Outputs

- `trade_id` — generated UUID for the entry
- `setup_library_snapshot` — for the tagged setup, updated rolling stats: sample size, hit rate, average R, average hold days, distribution of R outcomes, P&L contribution
- `per_conviction_tier_breakdown` — hit rate and average R by tier, to validate whether A+ is actually better than B+
- `per_market_phase_breakdown` — same stats bucketed by market phase, to detect regime sensitivity
- `decay_flag` — if the setup's rolling 20-trade stats are meaningfully worse than the setup's full history, flag it with a one-line diagnosis (smaller hit rate, smaller R, longer holds — or some combination)
- `honest_tier_suggestion` — if actual performance doesn't match claimed tier, suggest a reclassification

## When to invoke

- Right after every exit, winning or losing
- Periodically as a batch job over the last N trades to refresh decay flags
- When considering a new setup — query the library to see if this setup has a tier yet

## When NOT to invoke

- For trades that don't fit the taxonomy — mark them `other` and flag for review, do not force-fit
- For intraday scalps — this sub-agent assumes swing-timeframe trades

## Caveats — shell-only phase 2 artifact

This sub-agent describes an interface. Persistence is deferred — the storage layer is not wired to a real database in phase 2. The taxonomy above is the opening set and should expand as the trader's voice evolves. The "honest tier suggestion" logic is intentionally crude — average R within tier — and should be replaced with a distribution-aware heuristic in a future phase.

## Cross-callers

- `finance-quant` — occasionally, to query the library as a feature store for pattern-based research (e.g. "does breakout-retest have statistical edge that survives multiple-testing adjustment?")
