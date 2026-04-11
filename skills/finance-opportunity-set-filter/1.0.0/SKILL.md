---
id: finance-opportunity-set-filter
name: Opportunity Set Filter
---

# Opportunity Set Filter

## Purpose

The allocator's first question is always "should this even be in the opportunity set?" — and it should kill most pitches before they get sized. Every name that comes across the desk gets filtered through this checklist, and the filter is deliberately restrictive because the allocator's job is patient capital compounding, not reacting to pitches.

## Primary user

`finance-allocator`. The allocator does not engage with sizing, timing, or valuation until the opportunity-set question is answered cleanly. Most pitches fail here and should.

## When to invoke

- The moment someone pitches a name, a theme, or a new sleeve
- When considering whether to widen or narrow the strategic opportunity set
- When reviewing current holdings to see if anything has drifted *out* of the opportunity set and should be exited on strategic grounds, not tactical ones

## The filter

### 1. What asset class is this?

Force a specific answer: US large-cap equity, US small-cap equity, intl developed equity, EM equity, US treasuries, IG credit, HY credit, loans, real assets, private equity, hedge fund, cash. Single-name pitches that don't cleanly map to an asset class are already suspicious — they're often a tactical story dressed as an allocation.

**Reject:** anything that can't be named as an asset class.

### 2. What's the strategic weight for this asset class today?

Pull the current policy weight and actual weight for the asset class this pitch would go into. If the asset class is already at or above target, adding a name to it is not an allocation decision — it's a single-name substitution, which belongs to a PM, not an allocator.

**Reject:** pitches where the asset class is already at or above target unless the pitch is a substitution (and then the question is which existing holding gets trimmed).

### 3. Is this alpha or is this beta I'm already paying for via the index?

Decompose the pitch: does it deliver a return stream that my broad-market exposure does not? If not, I'm paying active fees for beta I already own. The allocator should not accept active exposure unless there's credible alpha separable from index beta.

**Test:** describe the return stream of this position in regime-conditional terms — what does it do in a risk-on environment, a risk-off environment, a rates shock, a liquidity shock? If the answer looks like the index, it is the index.

**Reject:** pitches that fail the alpha-vs-beta distinction.

### 4. Does the multi-year thesis survive if we're wrong on cycle timing?

The allocator's horizon is multi-year. A thesis that only works if we're right about the current cycle position is a tactical call, not a strategic one. Force the test: if cycle position is the opposite of what we currently think — e.g. if we're actually in early contraction when we thought we were in late expansion — does this position still make sense?

**Reject:** anything that only works in one cycle state.

### 5. What would have to be true in ten years for this to be a good allocation?

Not the thesis — the end-state. Ten years from now, what does the world look like if this position has compounded? Is that world plausible from here? Is it plausible through multiple intervening cycles, not just the current one?

**Reject:** pitches where the ten-year end-state requires a sequence of specific near-term events to hold.

## Example application

**Pitch:** Long NVDA, 5% of portfolio, "AI infrastructure supercycle"

**1. Asset class:** US large-cap equity, tech sector. ✓ maps cleanly.

**2. Strategic weight:** US large-cap is at policy target. Tech sector is already 28% of the US large-cap sleeve via index holdings and is at the high end of historical weight. **Asset class concentration flag.**

**3. Alpha vs beta:** NVDA is the largest position in S&P 500 by market cap. Holding NVDA as a standalone allocation alongside a broad-market index is double-counting. In regime terms, NVDA behaves like a high-beta growth stock with elevated correlation to AI capex cycles — not clearly differentiated from the tech sub-sleeve of the index. **Alpha-vs-beta fails.**

**4. Multi-year thesis under cycle-timing risk:** thesis depends on the AI capex supercycle continuing to 2028. If we're actually in late-cycle expansion and hyperscaler capex rolls over in 2025-2026, the thesis breaks. The multi-year case is cycle-dependent. **Cycle-timing dependence flag.**

**5. Ten-year end state:** ten years from now, NVDA either dominates the AI infrastructure layer or is commoditised. In the dominance case, the S&P 500 also benefits heavily because NVDA is 7% of it. In the commoditisation case, the position underperforms. The active decision is only adding differentiated return in one scenario and is redundant in the other.

**Verdict:** Rejected at the opportunity-set filter. Not an allocator decision. The underlying exposure is already being held through the index. If Arjun wants a concentrated AI bet on top of the index, that's a PM or trader decision, not an allocation one — and the allocator would strongly suggest sizing through the existing sleeve rather than adding a single-name overlay.

## Anti-patterns

- Accepting tactical stories as strategic ones — "AI is the future" is a story, not an allocation
- Filling the opportunity set with everything that *could* fit, rather than narrowing to what *must* fit
- Ignoring the alpha-vs-beta question because "this one is different" — it rarely is
- Skipping the cycle-timing test because "we're right about the cycle" — the test is specifically for when we're wrong

## Caveats

This skill is deliberately harsh. Most pitches fail here and should. The allocator who says yes to everything is not an allocator, they're a CIO in name only. Pair this with `finance-rebalancing-discipline` when drift is the trigger, and with `finance-macro-regime-tracker` when cycle position is in question.
