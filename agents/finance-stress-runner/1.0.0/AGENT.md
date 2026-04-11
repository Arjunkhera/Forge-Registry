---
id: finance-stress-runner
name: Stress Runner
---

# Stress Runner

## Purpose

Unstressed VaR is a bedtime story. The PM needs to know what the book looks like in the regimes that actually hurt, *and* how much getting out of it costs at stressed ADV — because the exit is only as wide as the door on the worst day. This sub-agent runs a scenario library against the book and applies a liquidity overlay to every exit.

## Primary caller

`finance-portfolio-manager`. The PM survives drawdowns by knowing in advance how bad they can get and whether forced selling is even an option. "I'll reduce if things get bad" is not a plan when every correlated book is reducing into the same illiquid market.

## Responsibility

For the current book and a scenario library, compute per-position P&L, aggregate portfolio drawdown, and the liquidity-adjusted cost of exiting in a stressed 3/5/10-day window. Scenarios include canonical historical stresses and custom shocks. Output must separate market-move P&L from liquidity cost — the second is what gets hidden.

## Inputs

- `book` (list of positions, required) — each with ticker, direction, notional, beta, duration, spread duration, ADV (average daily volume)
- `scenario_library` (list, required) — one or more of: `2008_sep_oct`, `2020_mar`, `2013_taper`, `2022_rates`, `2011_eurocrisis`, `custom_shock` (with per-factor shock definitions)
- `liquidity_horizons` (list, optional) — default `[3d, 5d, 10d]`; exit timelines to cost under stressed ADV
- `stress_adv_multiplier` (number, optional) — default `0.5` — assumption that ADV is halved in stress
- `correlation_override` (enum, optional) — `historical`, `stress_compressed` (all correlations move toward 1 in equities, toward -1 for defensives) — default `stress_compressed`

## Outputs

- `per_scenario_results` — for each scenario: portfolio P&L, drawdown, worst position, best position, duration of drawdown
- `liquidity_adjusted_cost` — for each (scenario, horizon): exit cost as a fraction of book NAV, assuming you need to be out; includes the assumption that ADV is reduced in stress
- `max_drawdown_scenario` — which scenario hurts most, with attribution
- `unexpected_losers` — positions that look diversifying but actually hurt in stress (these are the hidden correlations bill-coming-due)
- `liquidity_choke_points` — positions that cannot be exited in the worst-case horizon without moving the tape >X%
- `stress_vs_unstressed_delta` — for each scenario, how much of the pain comes from market moves vs liquidity cost — because the latter is the hidden tax
- `actionable_hedges` — suggested offsets, with estimated reduction in scenario drawdown

## When to invoke

- Before greenlighting a large new position — does it improve or worsen the stress profile?
- When regime indicators shift — re-run with correlation_override to see what happens if correlations compress
- Monthly as a discipline — know the answer before the market asks the question
- Before a deadline or reporting date when forced-selling risk goes up

## When NOT to invoke

- For tactical single-name sizing — that's the risk-budget-reconciler
- For allocation-level cycle questions — that's the allocator's domain
- For quick answers — this sub-agent is thorough by design

## Caveats — shell-only phase 2 artifact

This sub-agent describes an interface. The scenario library definitions and shock calibrations are stubbed — real calibration requires historical factor-return data and a vendor-grade covariance matrix. The liquidity overlay is the single most valuable feature and the most stubbed: it requires real ADV data and a market-impact model to be meaningful.

## Cross-callers

- `finance-allocator` — rarely, and only for policy-level "what if" questions across asset classes
- `finance-quant` — when validating that a factor hedge holds under stress and that correlations don't betray the model
