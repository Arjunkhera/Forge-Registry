---
id: finance-thesis-catalyst-variant
name: Thesis-Catalyst-Variant Template
---

# Thesis-Catalyst-Variant Template

## Purpose

The analyst's discipline is "what's the catalyst?" — cheap isn't a trigger, something has to force the re-rate. This skill is the one-page structure that enforces that discipline before a thesis ships. A thesis without a catalyst is a view, and a view without variant perception is consensus dressed up. This skill stops both.

## Primary user

`finance-equity-analyst`. The analyst invokes this skill the moment they're tempted to write "undervalued" without a trigger. It sharpens the question: do I actually have a call, or am I just saying the price is low?

## When to invoke

- Every time a new thesis is being formed
- Whenever an existing thesis needs to be defended or re-underwritten
- Before sizing up into a name, to force an honest check: is the catalyst still in the window?
- When a catalyst passes without a re-rate — time to re-thesise or walk

## The template

### 1. The thesis — two sentences, no more

State what the market is getting wrong and what the right view is. No macro. No "cheap on EBITDA". A specific, narrow, testable claim about the business.

**Format:**
- Sentence 1: what the market currently believes about this business.
- Sentence 2: what I believe and why that belief will be forced into the tape.

If you need a third sentence, the thesis isn't sharp enough.

### 2. The catalyst — specific event, date window, evidence trigger

State the event that will force the re-rate, with a date window and the evidence the market will see.

**Format:**
- Event: (e.g. Q3 earnings print, FDA PDUFA date, investor day, segment disclosure change, regulatory ruling, product launch)
- Date window: the specific period within which this event is expected (e.g. "between Oct 21 and Nov 4")
- What the market will see: the specific data point or disclosure (e.g. "segment operating margin for cloud infrastructure above 22% for the first time")
- Why this forces the re-rate: consensus currently assumes something inconsistent with this data point being public

If you can't state all four, you don't have a catalyst. You have wishful thinking about the price.

### 3. The variant perception — consensus vs me vs gap-closer

State the disagreement as a three-part formula.

**Format:**
- **Consensus believes** X — specifically, not vaguely
- **I believe** Y — with the evidence
- **The gap closes when** Z — the data point or event that forces the reconciliation

If "consensus believes X" and "I believe Y" are the same sentence with different words, you don't have a variant perception. You're paraphrasing the street.

### 4. The disconfirmers — what breaks this thesis

List the specific pieces of evidence that would falsify the thesis before you size up. Not "the stock goes down" — the actual data points that would change the fundamental view.

**Format:**
- Disconfirmer 1: (e.g. "gross margin compression more than 150bps in the print")
- Disconfirmer 2: (e.g. "management removing the mid-term margin target")
- Disconfirmer 3: (e.g. "a competitor's product launch with materially lower pricing")

Three is the minimum. Five is better. If you can't name three things that would kill the thesis, the thesis is unfalsifiable — and unfalsifiable theses don't re-rate, they decay.

### 5. The kill criteria — when I walk away

State the conditions under which the thesis is dead and the position is exited regardless of price. Catalyst passed without a re-rate. Disconfirmer triggered. Variant perception closed without the re-rate. Time decay past the catalyst window.

**Format:** a short list of concrete conditions. Not feelings. Not "if it keeps going down".

## Example application

**Ticker:** EXAMPLECO (semiconductor equipment)

**Thesis:**
1. The market currently believes EXAMPLECO is a cyclical with peaking orders because WFE spending has already rolled over.
2. I believe the 3nm transition is creating a structural shift in per-wafer capex intensity that extends the cycle and raises baseline orders by 15-20% vs prior peaks.

**Catalyst:**
- Event: Q1 earnings + guidance
- Date window: April 24 - May 1
- Market will see: first explicit guidance that forward-quarter orders are above the prior cycle peak
- Why this forces re-rate: consensus has the business cresting at prior-peak orders; a number above that proves the structural shift

**Variant perception:**
- Consensus believes: orders peak at $X, business normalises at $0.7X
- I believe: orders peak at $1.15X, business normalises at $0.85X
- The gap closes when: the Q1 guide exceeds consensus peak by more than 5%, or the Q2 order book disclosure confirms above-peak bookings

**Disconfirmers:**
- Gross margin compression > 200bps (would signal the pricing power I'm crediting is overstated)
- Management removing the "structural shift" language from the narrative
- Competitor announcement of comparable-intensity tooling at lower ASPs
- Evidence of double-booking from one customer inflating the order number

**Kill criteria:**
- Q1 guide comes in at or below consensus peak with no forward order-book disclosure
- Any of the disconfirmers trigger
- Catalyst passes and re-rate hasn't happened within 2 reporting cycles

## Anti-patterns

- Thesis = "cheap on EBITDA/PE/EV/sales" — no, that's a valuation observation, not a thesis
- Catalyst = "eventually the market will realize" — no date window, no event, not a catalyst
- Variant perception = "I like it more than others do" — that's not a variant perception, it's a preference
- Disconfirmers = "the stock goes down" — the disconfirmer is the evidence that would change the view, not the price
- Kill criteria = "I'll reassess if the thesis doesn't work" — that's not a criterion, that's a feeling

## Caveats

This skill is methodology, not execution. Once the thesis is written, the analyst still has to defend it with `finance-thesis-pre-mortem`, and the catalyst has to be watched against filings (`finance-filings-diff`), transcripts (`finance-transcript-parser`), and sell-side moves (`finance-consensus-scraper`). The skill makes the thesis legible; the sub-agents keep it alive.
