---
id: finance-drift-monitor
name: Strategic Drift Monitor
---

# Strategic Drift Monitor

## Purpose

Strategic drift is the allocator's single biggest operational risk. Small tactical moves compound into a portfolio nobody intended to own. This sub-agent watches the actual vs. target weights by sleeve, attributes drift to flows vs price, and tells the allocator when drift has exceeded tolerance bands — and crucially, whether the market is doing the rebalancing *for* them or *against* them. The allocator won't catch this by eyeballing.

## Primary caller

`finance-allocator`. The allocator's whole discipline is staying close to strategic exposures across multi-year horizons. Without a drift monitor they run a portfolio they never explicitly approved. With it, they can be deliberate about when to rebalance and when to let a drift run because the underlying market move is doing their work for them.

## Responsibility

For a portfolio and a policy (target weights + tolerance bands per sleeve), report actual vs target, attribute drift to flows vs price, flag tolerance-band breaches with time-in-breach, and distinguish "market moving me toward my target" drift from "market moving me away from target" drift. Output is weekly-cadence friendly — no daily pings.

## Inputs

- `portfolio` (object, required) — current holdings grouped by sleeve (e.g. `us_equity_large_cap`, `us_equity_small_cap`, `intl_dm_equity`, `em_equity`, `us_treasury`, `ig_credit`, `hy_credit`, `real_assets`, `cash`)
- `policy` (object, required) — per-sleeve: target weight, tolerance band (± bps or %), rebalancing rule (`corridor`, `calendar`, `opportunistic`)
- `flows` (list, optional) — contributions, withdrawals, dividends, coupons over the lookback; if absent, drift attribution can't separate flows from price
- `lookback` (duration, optional) — default `30d`
- `include_sub_sleeves` (boolean, optional) — default `true`

## Outputs

- `per_sleeve_status` — for each sleeve: current weight, target weight, drift in bps, in-band / out-of-band, direction (above / below target)
- `drift_attribution` — for each sleeve, drift split between flows and price; a sleeve that is out of band because of price moves is a different decision than one out of band because of uneven flows
- `tolerance_breaches` — list of sleeves currently outside tolerance bands, with time-in-breach
- `helpful_vs_hostile_drift` — classifies drift as: the market is moving you *toward* the target (do nothing, let it run), *away* from the target (action required), or you are neutral (threshold matters but urgency is low)
- `rebalancing_suggestion` — for each breached sleeve: suggested trim/add size, tax-awareness flag if applicable, whether this breach should be combined with any pending flow
- `next_review_date` — calendar rule for the next check
- `no_action_verdict` — if the whole portfolio is inside bands and no breaches are projected in the near term, this output is `no_action` — and the allocator closes the tool

## When to invoke

- Weekly as baseline discipline (quick read, usually `no_action`)
- Monthly for a full review
- When fresh capital comes in or a distribution is made — natural rebalancing moment
- When cycle-position has shifted (signal from `finance-macro-regime-tracker`) and the allocator is questioning policy weights

## When NOT to invoke

- For tactical rotation within a sleeve (single-name buy/sell) — that's a PM question
- For single-quarter performance attribution — different tool, different question
- For daily performance — wrong cadence, wrong purpose

## Caveats — shell-only phase 2 artifact

This sub-agent describes an interface. Portfolio ingestion is stubbed — no custody or broker integration in phase 2. Flows attribution requires a clean flows log that phase 2 assumes is provided. Tax-awareness logic is deferred to a future phase when tax lot data is wired in.

## Cross-callers

- `finance-portfolio-manager` — rarely, and only for positions held at the allocator level that the PM sleeve borrows from (unusual configuration)
