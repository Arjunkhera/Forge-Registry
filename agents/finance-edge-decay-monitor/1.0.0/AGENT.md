---
id: finance-edge-decay-monitor
name: Edge Decay Monitor
---

# Edge Decay Monitor

## Purpose

The quant carries the scar of a strategy that worked until the market learned it — now the equity curve is a decaying exponential. This sub-agent watches live or paper-traded strategies against their backtest distribution, runs structural-break tests, and yells when rolling performance becomes statistically indistinguishable from zero — not six months after a PM finally notices, but when the statistical evidence first supports the claim.

## Primary caller

`finance-quant`. The quant wants a sub-agent that catches edge decay early, using tests the quant trusts, and refuses to confuse "bad month" with "decayed strategy".

## Responsibility

For a live strategy id, compare rolling realized returns against the OOS backtest distribution, run Chow and CUSUM structural-break tests on the performance time series, and flag when the evidence supports edge decay. Output must distinguish "noisy underperformance within backtest distribution" from "statistical break from backtest distribution".

## Inputs

- `strategy_id` (string, required)
- `live_returns` (time series, required) — dated return observations since the strategy went live
- `backtest_return_distribution` (object, required) — mean, std, distribution shape, percentile curves from the OOS backtest (from `finance-walk-forward-backtester`)
- `rolling_window` (duration, optional) — default `60d`
- `structural_break_methods` (list, optional) — default `[chow, cusum, page-hinkley]`
- `significance_level` (number, optional) — default `0.05`
- `regime_context` (object, optional) — regime label time series from `finance-regime-classifier`, to distinguish regime-conditional decay from absolute decay

## Outputs

- `current_rolling_sharpe` — live rolling Sharpe over the window
- `backtest_percentile` — where the current rolling Sharpe sits within the backtest distribution
- `structural_break_results` — one result per method: break detected (boolean), break date (if detected), test statistic, p-value
- `decay_flag` — one of `healthy`, `underperforming_within_distribution`, `statistical_break_candidate`, `statistical_break_confirmed`, `indistinguishable_from_zero`
- `decay_diagnosis` — one-line reason: smaller mean return, higher vol, longer holds, more false positives, or a specific factor contributing the shift
- `regime_conditional_view` — if regime context supplied, is the decay absolute or regime-specific (strategy may be fine in one regime and broken in another)
- `recommended_action` — one of `continue`, `reduce_size`, `pause`, `retire`, with an explanatory note
- `next_review_date` — when to re-check given the current state

## When to invoke

- Weekly on every live strategy
- After any period of underperformance relative to the backtest — to test whether it's noise or not
- When the regime has shifted — to see whether the strategy's edge was regime-specific all along

## When NOT to invoke

- On strategies with too-short live history for statistical power — the sub-agent should return an "insufficient data" verdict and refuse to emit false confidence
- For alpha attribution — that's a different question about what contributed, not whether it's still working

## Caveats — shell-only phase 2 artifact

This sub-agent describes an interface. The structural-break tests are implementable standards; what's stubbed is the live-return data pipeline — phase 2 assumes the caller provides the return series, with no integration to brokers, risk systems, or performance databases.

## Cross-callers

- `finance-portfolio-manager` — when a systematic strategy is a sleeve in the book and the PM wants an early warning that the alpha contribution is fading
