---
name: finance-regime-classifier
description: >
  Sub-agent that labels historical periods with regimes (risk-on/risk-off, expansion/contraction, low-vol/high-vol, trending/mean-reverting) using macro, volatility, and liquidity features, and returns same-regime-only resamples of any strategy's returns for conditional evaluation. Primary caller: finance-quant.
---

# Regime Classifier

## Purpose

"It worked 2012-2019" is not evidence a strategy works. The quant wants to see 2008, 2020, 2022 conditional returns — or they are not interested. This sub-agent labels historical periods with regimes and returns same-regime-only resamples of any strategy's returns, so the quant can test whether an edge generalises across regimes or is a backtest artifact of one environment.

## Primary caller

`finance-quant`. Conditional evaluation is a load-bearing discipline for the quant. A strategy with a good unconditional Sharpe and terrible conditional performance in contraction regimes is not a strategy; it's a bet on expansion.

## Responsibility

Given a date range and a feature set, classify each period into a regime label. Return the regime time series. On request, take a strategy return series and return same-regime-only resamples for conditional evaluation.

## Inputs

- `date_range` (object, required)
- `feature_set` (enum, optional) — default `macro_vol_liquidity`: realised vol, VIX, credit spreads, curve shape, real yields, global M2 growth, dollar, commodity index. Alternative: `micro_structure` (trend, mean-reversion, dispersion, cross-sectional spread)
- `classification_method` (enum, optional) — `rule_based`, `hmm`, `k_means`, `gaussian_mixture` — default `rule_based` for reproducibility
- `num_regimes` (integer, optional) — default `4`
- `strategy_returns` (time series, optional) — if provided, sub-agent returns conditional evaluation alongside classification
- `regime_lexicon` (object, optional) — custom regime labels like `risk_on_low_vol`, `risk_off_high_vol`, `stagflation`, `soft_landing`

## Outputs

- `regime_time_series` — date-indexed regime labels across the requested period
- `regime_transition_matrix` — empirical frequencies of moving from regime X to regime Y
- `regime_duration_distribution` — how long each regime typically persists
- `regime_feature_profiles` — for each regime, mean and spread of the features that define it
- `conditional_strategy_performance` (if `strategy_returns` supplied) — mean, Sharpe, max drawdown, hit rate per regime
- `robustness_verdict` (if strategy_returns supplied) — does the strategy have positive edge in every regime, or is it conditional on specific environments
- `current_regime` — the regime label for the most recent period in the range
- `regime_uncertainty` — classification confidence, flagged low at transitions

## When to invoke

- When validating whether a backtest's edge is regime-specific
- When choosing between candidate strategies that have similar unconditional metrics but different conditional profiles
- Before deploying live — does the current regime match a regime where the strategy has demonstrated edge?
- To support `finance-edge-decay-monitor` in distinguishing absolute decay from regime-conditional decay

## When NOT to invoke

- For tactical rotation — regime classification is strategic context, not a trading signal
- For real-time regime nowcasting — this sub-agent is designed for historical labelling, not intraday regime calls

## Caveats — shell-only phase 2 artifact

This sub-agent describes an interface. The feature pipeline and classification models are stubbed — phase 2 defines the contract and the output schema. Rule-based classification is the simplest to stand up; HMM and gaussian-mixture approaches require real historical feature data that phase 2 does not wire.

## Cross-callers

- `finance-allocator` — shares regime definitions with `finance-macro-regime-tracker`; regime-classifier is the historical/quant view, macro-regime-tracker is the current/allocator view
- `finance-portfolio-manager` — for correlation assumption validation: correlations are regime-dependent, and the PM wants the stress-runner to use regime-aware correlations
