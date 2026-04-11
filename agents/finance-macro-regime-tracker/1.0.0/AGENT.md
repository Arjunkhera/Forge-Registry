---
id: finance-macro-regime-tracker
name: Macro Regime Tracker
---

# Macro Regime Tracker

## Purpose

For the allocator, the only question that matters most quarters is "has cycle position actually changed, or is this noise?". This sub-agent monitors the handful of variables that actually move cycle position and tells the allocator when to *wake up* — not when to act daily. It is a deliberate under-pinger. It will stay silent through 95% of market weather and speak clearly when something crosses a meaningful threshold.

## Primary caller

`finance-allocator`. The allocator rebalances slowly, moves deliberately, and treats most short-horizon noise as irrelevant. This sub-agent is calibrated to their horizon — it does not mention daily moves, it does not surface news, it does not emit tactical signals.

## Responsibility

Track cycle-position indicators, compute change-since-last-check (on a weekly-to-monthly cadence, not daily), and flag any indicator that has crossed a threshold meaningful enough to affect strategic positioning. Report the current regime classification and the conviction of that classification. Refuse to manufacture urgency.

## Inputs

- `indicator_set` (enum, optional) — default `cycle_core`: real yields, 2s10s and 3m10y curve shape, IG and HY credit spreads, ISM manufacturing PMI, ISM services PMI, global M2 growth, earnings yield minus bond yield, US dollar DXY, commodity index. `cycle_extended` adds high-yield OAS, loan demand surveys, CFNAI, Chicago Fed financial conditions
- `lookback` (duration, optional) — default `90d`, for computing change-since-last-check and threshold crosses
- `threshold_sensitivity` (enum, optional) — `conservative` (wake the allocator only on clear regime shifts), `balanced` (also flag material threshold crosses), `sensitive` (surface more noise — not recommended for allocator). Default `conservative`.

## Outputs

- `regime_classification` — one of `late_cycle_expansion`, `early_cycle_recovery`, `slowdown`, `contraction`, `stagflation`, `soft_landing`, `uncertain` — with a conviction score
- `regime_change_flag` — boolean — has classification changed since last check?
- `indicators_snapshot` — current values for each tracked indicator
- `threshold_crosses` — indicators that have crossed a meaningful threshold since last check (e.g. curve inversion, credit spreads > long-term median + 1σ), each with a one-line interpretation
- `change_since_last_check` — for each indicator, the direction and magnitude of change
- `allocator_wake_signal` — one of `stay_asleep`, `check_in`, `wake_up` — the header-level call to action
- `notes` — if `wake_up`, a paragraph on what's shifted, for the allocator to read once and then decide whether to act
- `next_check_cadence` — recommended when to run this again

## When to invoke

- Weekly as baseline discipline — quick check
- Monthly as deeper review — read the notes if regime changed
- When someone else is panicking — to test whether the panic is actually a regime signal

## When NOT to invoke

- For daily portfolio decisions — wrong horizon
- For single-name research — macro is not the stock call
- For tactical rotation between growth and value — that's a PM question, not an allocator question
- For news-driven urgency — if a headline made you open this, close it and come back next week

## Caveats — shell-only phase 2 artifact

This sub-agent describes an interface. Real indicator data sources (FRED, ICE BofA, ISM direct, central bank data) are not wired in phase 2. Threshold calibrations are placeholders. The regime-classification logic is stubbed — in a future phase it should be an HMM, a rule-based ensemble, or a tuned statistical classifier; here it's a hand-wave.

## Cross-callers

- `finance-portfolio-manager` — monthly, to inform the regime view inside the stress runner's correlation assumptions
- `finance-quant` — to define regime labels for conditional backtests (via `finance-regime-classifier` which borrows the definitions here)
