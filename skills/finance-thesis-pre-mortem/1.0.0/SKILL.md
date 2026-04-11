---
id: finance-thesis-pre-mortem
name: Thesis Pre-Mortem
---

# Thesis Pre-Mortem

## Purpose

A thesis that has survived contact with its own bear case — stated in its strongest form, not a strawman — is a thesis the analyst can actually size. This skill forces that pre-mortem. It is the discipline of "kill the thesis before it ships", which is the opposite of the usual analyst temptation to defend a view once it's been written down.

## Primary user

`finance-equity-analyst`. The analyst invokes this immediately before sizing up, or any time the position is being defended against someone else's bear case. It is the skill that turns a thesis into a position.

## When to invoke

- Before sizing up into a name — full-cycle test
- When someone credible pushes back on the thesis — structured defence
- Before the catalyst — last-chance falsification
- Quarterly as a re-underwriting exercise for existing positions

## The checklist

### 1. What breaks this thesis?

State three specific pieces of evidence that would kill the view. Not generic ("the stock goes down") — concrete evidence from filings, transcripts, industry data, or customer signals that would force a fundamental re-think.

**Format:**
- Breaker 1: a data point from the filings that would invalidate the model
- Breaker 2: a statement from management that would invalidate the narrative
- Breaker 3: a competitive development that would invalidate the moat

If you can't name three, the thesis is unfalsifiable — and unfalsifiable theses don't survive contact.

### 2. What's the tape that would tell me I'm wrong?

The tape often knows before the fundamentals do. What's the specific price behaviour that would make you seriously reconsider, regardless of whether the fundamental case has changed yet?

**Format:**
- Negative tape tell 1: (e.g. "down on a positive guidance raise")
- Negative tape tell 2: (e.g. "sector laggards outperform peers on the same news")
- Negative tape tell 3: (e.g. "breakdown of a multi-year base on above-average volume")

The tape is not your persona — you're an analyst, not a trader — but it is data about what other investors think. Honouring it is discipline, not trading.

### 3. The bear case stated in its strongest form

Write the bear case as if you were the smartest short on the name. No strawman. No "bears don't understand the business". Give the short their best argument and see if your thesis still holds after hearing it.

**Format:** a full paragraph. Specific numbers. Specific concerns. The strongest version.

If the bear case is not a fair, strong statement — you haven't done the pre-mortem, you've shadow-boxed.

### 4. What number in the next print would invalidate me?

The next reporting event is the closest objective test. State the specific number — not the aggregate headline, the specific line item — that would force you to re-underwrite.

**Format:**
- Line item: (e.g. "cloud infrastructure segment gross margin")
- Invalidation threshold: (e.g. "below 42% — this would indicate pricing pressure we don't have modelled")
- Why this line item: (one-sentence link to the core thesis)

### 5. If the catalyst passes without a re-rate, what does that mean?

A catalyst passing without the expected re-rate is a signal. Either the thesis was wrong, the catalyst wasn't actually the trigger, or the market has priced it in faster than you thought. State in advance what the interpretation will be.

**Format:** one of three — thesis wrong, wrong catalyst, already priced. State the evidence that would distinguish them.

## Example application

**Thesis under test:** EXAMPLECO long, structural 3nm capex cycle

**1. What breaks this thesis:**
- Gross margin compression > 200bps in the next print (would signal the pricing power I'm crediting is overstated)
- Top customer announcing a shift to alternative tooling in prepared remarks
- The 3nm wafer forecasts being cut by TSMC or similar primary customer

**2. Tape tells I'd be wrong:**
- Underperformance on a positive guidance raise
- Sector peers (LRCX, AMAT) outperforming on equivalent catalysts
- Breakdown below the 12-month base on volume

**3. Bear case in its strongest form:**
The 3nm transition is a one-time capex bulge, not a structural shift. Orders are pulled forward from 2027, not added to the run rate. Gross margins are peaking because mix-shift to advanced nodes is a cyclical high, not a new baseline — as 3nm matures, pricing compresses faster than historical nodes because the end-market (smartphones) is mature and customers have more leverage. The stock is trading at 22x on peak earnings; next-year EPS is lower, not higher, and the multiple re-rates back to 14x. Downside: -35%.

**4. Number in next print that invalidates:**
- Line item: Q1 cloud infrastructure segment gross margin
- Threshold: below 42%
- Why: the thesis's margin sustainability hinges on this segment holding above 42% even through the pricing normalization; below suggests the pricing power is narrower than I've credited

**5. If the catalyst passes without a re-rate:**
- If the Q1 guide beats consensus by <5% and the stock is flat: catalyst was wrong — the market was already pricing in the above-peak view. Re-underwrite.
- If the guide beats by >5% and the stock is flat: priced in. Thesis was right but the move happened before I entered. Take the lesson, move on.
- If the guide misses consensus peak: thesis wrong. Exit.

## Anti-patterns

- Strawman bear case — "bears think it's expensive, but it's not" is a strawman
- Vague disconfirmers — "if the business deteriorates" is not a disconfirmer
- Avoiding step 4 because "any number could matter" — specificity is the discipline
- Defending instead of testing — the pre-mortem is a test, not a rebuttal

## Caveats

This skill is paired with `finance-thesis-catalyst-variant` — the pre-mortem tests the thesis that the catalyst-variant template produced. They should be used together. Pre-morteming a thesis that was never properly structured is an exercise in defending poorly-defined claims.
