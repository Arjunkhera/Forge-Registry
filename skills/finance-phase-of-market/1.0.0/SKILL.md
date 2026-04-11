---
id: finance-phase-of-market
name: Phase of Market Framework
---

# Phase of Market Framework

## Purpose

Every setup has a market phase it works in and phases it dies in. Breakouts work in trends and fail in ranges. Mean-reversion setups work in ranges and die in trends. Climax fades work in climaxes and are suicide in healthy trends. The trader who takes the same setup through all phases is losing edge they didn't know they were spending. This skill forces the trader to name the current phase, know the tells, and filter their setup playbook against the phase before any trade is considered.

## Primary user

`finance-swing-trader`. The trader's most expensive mistake is fighting the phase. This skill is the weekly-and-on-demand discipline that stops that mistake.

## When to invoke

- Sunday session — before the week begins, classify the current phase across the indices and sectors being traded
- Any time the tape feels different than yesterday — check whether the phase has shifted
- Immediately before invoking `finance-pre-trade-checklist` — question 4 of the checklist requires this classification

## The four phases

### Trending

**Tells:**
- Higher highs and higher lows on the daily (or lower lows and lower highs, inverse)
- Breadth (advancers vs decliners) confirming the move
- Pullbacks to moving averages hold
- Volume expands on the direction-of-trend moves, contracts on counter-trend moves
- Implied vol is low or declining

**Setups that work:**
- Breakout-retest
- Pullback-to-moving-average
- Base-breakout
- Trend-pullback continuation
- Earnings-drift (the initial reaction persists)

**Setups that die:**
- Mean-reversion trades against the trend
- Counter-trend climax fades on the first sign of exhaustion — wait for climax confirmation
- Any "contrarian" trade that assumes the trend has topped before it shows you

### Ranging

**Tells:**
- Price oscillates between clear support and resistance
- Breakouts fail and round-trip back into the range
- Breadth is middling, sector leadership rotates weekly
- Volume spikes on the range edges, contracts in the middle
- Implied vol is stable

**Setups that work:**
- Mean-reversion at range edges
- Failed-breakdown (long at the bottom of the range)
- Failed-breakout (short at the top of the range)
- Gap-fill within the range

**Setups that die:**
- Breakout-retest — the breakout fails too often
- Trend-pullback — there's no trend to pull back to
- Momentum chases on any single-day move

### Transitioning

**Tells:**
- A prior trend is losing conviction: lower highs in an uptrend, higher lows in a downtrend
- Breadth diverges from price
- Leadership changes — prior leaders stop leading
- Volume profile shifts, often with one or two climactic sessions
- Implied vol starts to tick up

**Setups that work:**
- Nothing cleanly. Sizes should be cut. Patience.
- Range-expansion *if* the new direction confirms — wait for confirmation
- Cash is a position

**Setups that die:**
- Everything that worked in the prior phase
- "It worked last week" is the most expensive phrase in a transition

### Climaxing

**Tells:**
- Price moves vertically on accelerating volume
- Breadth narrows even as indices make new highs (or widens as they make new lows)
- Leadership narrows to a handful of names carrying the tape
- Implied vol expands even as price continues in the same direction
- Sentiment indicators hit extremes

**Setups that work:**
- Climax-fade — but only after the climax confirms (first red day after vertical move, or first green day after vertical down)
- Volatility-expansion trades

**Setups that die:**
- Any trend-continuation trade taken at the end of a climax
- Fresh breakouts chased at the top of the move
- Mean-reversion during the climax itself — "fading the top" before the top confirms

## How to use the framework

1. Open the chart of the primary index being traded (SPX, NDX, or the relevant sector)
2. Answer: daily structure — trending, ranging, transitioning, or climaxing?
3. Cross-check with breadth: does the breadth confirm or contradict the price structure?
4. Cross-check with volume: does the volume profile match the phase tells?
5. If the answer is ambiguous, the phase is transitioning — act accordingly
6. Apply the filter: which setups in your playbook work in this phase, and which should be off the table until the phase changes?

## Example application

**Sunday session read, Apr 6 2026:**

SPX: higher highs and higher lows across the last 3 weeks. Pullbacks to the 20-day holding. Breadth healthy — 70% of S&P above their 50-day. Volume expanding on up days. VIX at 14, drifting lower.

**Phase:** Trending.

**Setups on the table this week:** breakout-retest, pullback-to-moving-average, base-breakout, trend-pullback.

**Setups off the table:** mean-reversion, failed-breakout shorts, any climax-fade before the climax shows.

**Adjustments:** size can be full tier. Tight stops are appropriate. Short-selling is off the table entirely — the phase does not support it.

## Anti-patterns

- Classifying based on how you *feel* about the market rather than what the tape is actually doing
- Refusing to update the classification when the phase has shifted (this is how the trader fights the new phase)
- Trading the same setups in every phase because "they work long-term" — long-term expectancy doesn't save a trade taken in the wrong phase
- Over-classifying sub-phases that don't meaningfully change the setup filter

## Caveats

Phase classification is fractal — the daily phase and the intraday phase can be different. This skill is for the daily-to-weekly phase that governs the swing trader's playbook. Intraday phase shifts are a separate, faster-rhythm question (borrow from `finance-tape-reader`).
