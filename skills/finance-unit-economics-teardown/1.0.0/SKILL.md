---
id: finance-unit-economics-teardown
name: Unit Economics Teardown Framework
---

# Unit Economics Teardown Framework

## Purpose

Aggregate P&Ls lie. A business that looks like it's compounding at the headline level can be shrinking at the unit level, with revenue growth coming from more expensive customers with worse retention. The analyst needs to decompose the reported aggregate into per-unit economics to see whether the underlying business is actually getting better, worse, or running in place. This skill is the framework for that decomposition.

## Primary user

`finance-equity-analyst`. The analyst reaches for this when a company reports growth that smells suspicious — top line up, margins flat, CAC rising, retention silent — and wants to see whether the unit economics support the narrative or contradict it.

## When to invoke

- When a business reports aggregate metrics that obscure per-unit dynamics
- When considering a name where the thesis depends on "compounding" or "scaling efficiencies"
- When comparing two businesses in the same industry — unit economics usually separate them more than headline growth does
- When a management team keeps shifting which metric they report — the shift is often because the old metric stopped looking good

## The teardown

### 1. Revenue per unit

Define the unit. It's not always obvious. Units can be: customer, subscriber, transaction, vehicle, store, kilowatt-hour, seat, GB, query. The right unit is the one where the business's incremental decision lives.

**Derive:**
- Total revenue / unit count = revenue per unit
- Trend over 8 quarters — is it rising (price + mix tailwinds), flat (stable), or falling (discounting or mix shift toward lower-tier customers)

### 2. Contribution margin per unit

Derive the contribution margin — revenue per unit minus the variable costs that scale with volume. Not gross margin, not operating margin — contribution margin, the number that shows whether another unit is economic to sell.

**Pitfalls:**
- Management often blurs fixed and variable costs in "cost of revenue"
- SBC sometimes hides in contribution items and sometimes in SG&A
- Returns and refunds should be netted from revenue
- One-time credits and promotions distort the trend

### 3. Customer acquisition cost (CAC)

Sales and marketing spend attributable to new customer acquisition divided by new customer count. The denominator is the hard part — gross adds, not net adds, because churned customers that were re-acquired should count once, not twice.

**Trend over 8 quarters:** rising CAC at constant contribution margin means LTV/CAC is deteriorating even when reported metrics don't show it.

### 4. CAC payback period

How many months of contribution margin per unit does it take to recover CAC? If payback is lengthening, the business is getting worse even if revenue is growing.

**Rule of thumb (software/consumer subscription):** < 12 months is good, 12-24 is ok, > 24 is a problem. Industry varies.

### 5. Cohort retention

If cohort data is disclosed, plot net revenue retention (NRR) or gross retention by cohort vintage. Newer cohorts with worse retention than older ones is a red flag — the company is acquiring customers who stay around less.

**If cohort data is not disclosed:** note this. Management not disclosing cohorts is a signal, not an absence. Many of the best businesses disclose cohorts proactively. Many of the worst do not.

### 6. LTV / CAC

Contribution margin per unit × average customer lifetime (years) / CAC. Industry benchmarks vary widely; the trend matters more than the absolute.

**Pitfalls:**
- Average customer lifetime is hard and often gamed
- LTV/CAC can be flattered by assuming infinite retention
- Always derive it with conservative assumptions, then compare to management's claim

### 7. The compounding check

A business is compounding on unit economics if: contribution margin per unit is stable or rising, CAC payback is stable or shortening, cohort retention is stable or improving across vintages, and LTV/CAC is flat or improving.

A business is *not* compounding if any of those are quietly deteriorating behind top-line growth. Top-line growth with deteriorating unit economics is rented growth — it lasts until the capital stops.

## Example application

**Company:** EXAMPLECO (vertical SaaS)

**Unit:** subscribed customer

**Revenue per unit:** $14,200 → $14,400 → $14,100 → $13,800 → $13,500 → $13,200 → $13,000 → $12,800. Trend: falling. Mix shift or discounting is happening.

**Contribution margin per unit:** 72% → 71% → 70% → 70% → 69% → 68% → 68% → 67%. Trend: falling slowly.

**CAC:** $8,400 → $9,100 → $9,800 → $10,600 → $11,500 → $12,300 → $13,400 → $14,200. Trend: rising fast.

**CAC payback:** 12 → 14 → 16 → 18 → 21 → 23 → 26 → 29 months. Trend: lengthening badly.

**Cohort retention:** Not disclosed. Management stopped disclosing it three quarters ago. Management cited "competitive reasons".

**LTV/CAC (using 3-yr avg lifetime):** 2.6 → 2.4 → 2.2 → 2.0 → 1.7 → 1.5 → 1.3 → 1.2

**Compounding verdict:** This business is not compounding. It is growing top-line because of sales spend, and every unit economic metric is deteriorating. Top-line will stall when marketing spend is constrained. The cohort retention stopping is a tell. The catalyst short thesis is "they cut S&M, growth collapses".

## Anti-patterns

- Using gross margin instead of contribution margin — gross margin hides variable-scaling costs
- Ignoring SBC in the CAC (sales and marketing stock comp is part of the cost)
- Accepting management's LTV/CAC at face value — derive it yourself
- Skipping cohort retention because it's "hard" — when it matters, it matters
- Treating the framework as a calculator — the insight is in the trends, not the single-period snapshot

## Caveats

This skill is a framework, not a data-fetching tool. Pair it with `finance-fcf-bridge` for the cash-flow quality check and `finance-filings-diff` to see if the company is quietly changing how it defines the unit. When cohort data is genuinely unavailable (e.g. offline retail, industrial), the framework still applies — just with different units (transaction value, store-year contribution).
