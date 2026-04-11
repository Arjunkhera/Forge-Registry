---
id: finance-rebalancing-discipline
name: Rebalancing Discipline Framework
---

# Rebalancing Discipline Framework

## Purpose

Rebalancing is where allocators either add value or destroy it. Done right, it's the only persistent source of long-term return in excess of the policy benchmark. Done wrong, it becomes a vehicle for tactical drift — the allocator trims winners they "feel good about" and waits to rebalance losers "until things stabilize", which is the opposite of the discipline. This skill enforces the rebalance-as-rule, not rebalance-as-opinion principle.

## Primary user

`finance-allocator`. The allocator's rebalancing discipline is the difference between a patient-capital compounder and a dressed-up tactical account.

## When to invoke

- Whenever `finance-drift-monitor` reports a tolerance-band breach
- On the calendar (e.g. quarterly rebalance reviews)
- When fresh capital comes in — use flows as the rebalancing mechanism when possible
- When a distribution is being taken — use withdrawals as the rebalancing mechanism when possible

## The framework

### 1. Pre-commit to the rules before the moment arrives

The whole point of this framework is that rebalancing decisions are made *before* the drift happens, not *during* the drift. State the rules in the Investment Policy Statement (IPS) or its equivalent:
- Tolerance bands per sleeve (e.g. ± 3% absolute for large sleeves, ± 20% relative for small ones)
- Rebalance method (corridor, calendar, opportunistic)
- Cash buffer rules (how much cash before redeploying)
- Tax-aware sequencing priority

If the rules aren't written down, rebalancing becomes tactical every time. Write them down.

### 2. Rebalance into weakness, trim into strength

Counterintuitive but the evidence is clear: rebalancing works because it forces buying what's down and selling what's up. Resist the instinct to wait for the rebound. If an asset class is below target weight, it's specifically because the market has dropped its price — which means the forward expected return is higher, not lower.

**Rule:** rebalance into weakness. If a sleeve is below target because of a selloff, buy it back to target on schedule.

### 3. Tax-aware sequencing

When rebalancing requires sales in taxable accounts, sequence the sales to minimize tax impact:
- Sell loss lots first (tax-loss harvesting)
- Avoid selling short-term gain lots unless forced
- Prefer using distributions and new contributions to rebalance without sales
- Consider tax-lot-specific cost basis for every sale

**Tax-aware sequencing can materially reduce after-tax drag and should be pre-committed in the IPS.**

### 4. Use flows first, sales second

If fresh capital is coming in, allocate it to underweight sleeves — this rebalances without triggering taxes. Same for distributions taken from overweight sleeves. Only use outright sales when flows are insufficient or the drift is too large.

**Order of operations:** (1) direct new flows to underweight, (2) draw distributions from overweight, (3) sell loss lots in taxable accounts, (4) sell gains in tax-deferred accounts, (5) sell gains in taxable accounts (last resort).

### 5. Distinguish strategic rebalance from tactical re-thinking

When a sleeve is out of band, the default is to rebalance to policy. Only re-think policy if cycle position, fundamentals, or an allocator-level view has materially changed — and that re-thinking is a separate discipline, not an exception to rebalancing. If you're tempted to skip rebalancing "because the market will recover soon", you're making a tactical call. Name it, face it, and either commit to it (with explicit policy change) or rebalance as planned.

**Rule:** no tactical holds inside the rebalancing framework. Either follow the rule or change the rule.

### 6. Helpful drift vs hostile drift

From `finance-drift-monitor`: if the market is moving the portfolio *toward* policy, do nothing — let the drift do the work. If the market is moving the portfolio *away* from policy, act on the tolerance band. Not all drift requires action. Distinguish.

### 7. Minimum rebalance cadence: do not rebalance too often

Over-rebalancing erodes returns through friction and taxes. A minimum calendar cadence (e.g. quarterly review, monthly check-in only) prevents the allocator from turning the book over every month.

**Rule:** no more than N rebalances per year unless a material breach demands it (N typically 1-4 depending on portfolio size and volatility).

## Example application

**Trigger:** `finance-drift-monitor` reports US large-cap equity has drifted from 35% policy to 39.5% actual after a strong Q1. Tolerance band is ± 3% — breach confirmed.

**Step 1 — pre-committed rule check:** IPS specifies corridor rebalancing with ± 3% bands; this breach triggers action.

**Step 2 — direction of drift:** actual > policy. Need to trim US large-cap and add to other sleeves.

**Step 3 — which sleeves are underweight?** Intl developed at 18% vs 20% target (-2%). IG credit at 12% vs 13% target (-1%). Cash at 2% vs 2% target (ok).

**Step 4 — flows:** a distribution of 1.5% of NAV is scheduled this month. Direct it proportionally to the underweight sleeves: 60% intl developed, 40% IG credit.

**Step 5 — sales (if needed after flows):** the distribution does not fully close the breach. Additional sale of 1.5% NAV from US large-cap is required. Check tax lots: 70% of the holding is in a tax-deferred account → sell there first to avoid taxable gains.

**Step 6 — helpful-vs-hostile check:** drift direction is away from policy (market moved US equity up). Hostile drift — action required.

**Step 7 — minimum cadence:** last rebalance was 4 months ago. Within allowable cadence.

**Executed:** trim US large-cap by 3% (all in tax-deferred), direct the distribution to intl developed and IG credit. Bands restored.

## Anti-patterns

- Waiting for the overweight sleeve to "mean revert" — that's a tactical call masquerading as patience
- Over-rebalancing — every rebalance costs friction; rebalance to the rule, not to the drift
- Selling loss lots in tax-deferred accounts — wasted tax-loss harvesting opportunity
- Using new flows to buy the overweight sleeve "because it's working" — buying at the top
- Changing the rules mid-rebalance to avoid a politically hard trade — either change them before, or follow them

## Caveats

Tax-awareness logic is deferred in phase 2 — the framework describes the principle; real tax lot integration is a future phase. For pre-tax analysis or tax-deferred portfolios, the framework is fully usable as-is. Pair with `finance-drift-monitor` (sub-agent) for the trigger and `finance-opportunity-set-filter` when the question isn't "rebalance" but "should this asset class even be in the policy".
