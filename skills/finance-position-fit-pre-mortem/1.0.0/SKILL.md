---
id: finance-position-fit-pre-mortem
name: Position-Fit Pre-Mortem
---

# Position-Fit Pre-Mortem

## Purpose

"Good idea" is meaningless without "does it fit". The PM's discipline is refusing to evaluate a name outside the book's context — and this skill is the structured way to enforce that refusal. It forces the PM to answer six questions before sizing any new position, and if any of the answers are unsatisfactory, the trade doesn't go on.

## Primary user

`finance-portfolio-manager`. Not to be confused with `finance-thesis-pre-mortem`, which is the analyst's single-name thesis check. This skill is portfolio-level: the thesis is already validated; the question is whether the book can carry it.

## When to invoke

- Before greenlighting any new position — mandatory
- Before adding to a winner — the correlation-adjusted marginal may have changed
- When a new factor exposure is being added to the book that wasn't previously on
- Before a rotation — closing A to open B is two pre-mortems, not one

## The checklist

### 1. Factor map — what factor bet does this add to the book?

State the primary and secondary factor exposures this position carries. Use the factor model from `finance-factor-decomposer`. Do not accept "it's a single-name fundamental call" — every long equity is a beta bet, every short is a short beta bet, and most have secondary exposures (growth, value, momentum, quality, size, rates, FX, commodity).

**Format:** primary factor, secondary factor, tertiary factor, and whether any of these concentrate a factor already on the book above the PM's caps.

### 2. Correlation to top 5 existing positions

The question isn't "what's this correlated to on average" — it's "what's this correlated to in my specific top 5 positions, where the book's risk is actually concentrated". A position that's 0.3 correlated to SPX and 0.8 correlated to my largest long is not diversifying; it's doubling down.

**Format:** list the top 5 existing positions by risk contribution, pairwise correlation (historical and stress-compressed) to the new position, and an overall correlation profile.

### 3. Stress P&L — what does 2008, 2020, 2022 do to this position in the book?

Run the position through the stress library (via `finance-stress-runner`) and report per-scenario P&L. More importantly: how does the stress P&L change when the new position is added to the existing book vs evaluated standalone? The answer is often "much worse" because of hidden correlations.

**Format:** scenario × standalone P&L × in-book P&L × delta.

### 4. Liquidity-to-exit — can I get out in the worst case?

If I had to exit this position in 3 days at stressed ADV, what does it cost? If it's a top-5 book position and the liquidity window is weeks, I should size accordingly — or rotate in a smaller notional.

**Format:** exit cost at 3-day, 5-day, 10-day windows under stressed ADV, as a fraction of position notional and as a fraction of book NAV.

### 5. What has to be true for this to be wrong?

The thesis-level "what breaks this" is the analyst's job. The PM-level version is different: what does the *book* have to believe for this position to be wrong? If the thesis depends on a regime that's inconsistent with the rest of the book's positions, that's a signal the book already disagrees with itself.

**Format:** three conditions under which this position would materially hurt the book, and whether any of them are already being priced elsewhere in the book.

### 6. The unwind trigger

State the specific signal that would force a cut — not reduce, *cut*. Not "if the thesis deteriorates" but a concrete observable: a level, a number, a date, a peer behaviour.

**Format:** a one-line trigger, and the pre-committed action it triggers. No ambiguity.

## Example application

**Proposed position:** Long NVDA, 3% book NAV, target 12% gross contribution.

**1. Factor map:** Primary — equity beta. Secondary — growth and momentum. Tertiary — tech sector concentration, USD beneficiary. Momentum and growth are already 38% of book factor risk; this takes them to 46%, which exceeds the 40% single-factor cap. **Gate triggered.**

**2. Correlation:** Top 5 positions include MSFT and AVGO. NVDA is 0.76 correlated to MSFT in historical data, 0.88 in stress-compressed. Adding NVDA is effectively adding to the MSFT / AVGO cluster.

**3. Stress P&L:**
- 2020 March: standalone -14%, in-book -18% (hidden correlation through semiconductor supply chain)
- 2022 rates: standalone -22%, in-book -29% (stacked growth-factor exposure)
- 2008: standalone -31%, in-book -35%

**4. Liquidity:** 3-day exit cost at stressed ADV: 45 bps. 5-day: 30 bps. 10-day: 18 bps. Position is sizeable relative to single-name ADV; 3-day exit is meaningfully costly.

**5. What has to be true for this to be wrong (book-level):** AI infrastructure capex is a 2024-peak cyclical bulge, not a durable trend. If true, MSFT and AVGO are also wrong — my book is already expressing this view. This position doubles down on a consensus that may already be priced.

**6. Unwind trigger:** any material guidance cut from a hyperscaler customer in their next print. Pre-committed action: reduce to 1% on the open after the print.

**Pre-mortem verdict:** **Blocked.** The factor-cap breach is dispositive. Either trim MSFT/AVGO first to make room, or reduce the NVDA notional to fit inside the cap. The book cannot carry this trade as proposed.

## Anti-patterns

- Evaluating a position standalone because "it's a great thesis" — that's the analyst's job, not the PM's
- Defaulting to historical correlation when the book is near its vol target — stress-compressed is the relevant view
- Treating the factor cap as negotiable because of conviction — conviction sizes inside caps, not through them
- Skipping step 4 because liquidity "isn't an issue right now" — it isn't until it is

## Caveats

This skill depends on the PM's factor model, correlation matrices, and stress library. In phase 2, those are conceptual — the skill describes the discipline, not the computed numbers. When `finance-factor-decomposer`, `finance-stress-runner`, and `finance-risk-budget-reconciler` are wired to real data, this skill becomes the front-door interface to all three.
