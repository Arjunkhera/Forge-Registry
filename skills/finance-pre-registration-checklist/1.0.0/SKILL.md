---
id: finance-pre-registration-checklist
name: Pre-Registration Checklist
---

# Pre-Registration Checklist

## Purpose

Research and p-hacking are distinguished by exactly one thing: whether the hypothesis, the test, and the stopping rule were written down before the data was touched. This skill enforces pre-registration — the quant writes down what they're testing, on what universe, with what stopping rule, before the backtest runs. Everything that comes after is real research. Everything done without pre-registration is, at best, exploratory data analysis that should never be passed off as a finding.

## Primary user

`finance-quant`. The quant invokes this skill the moment someone (including themselves) says "I have an idea". The idea gets written down in pre-registered form, then the data gets touched. Never the other way around.

## When to invoke

- Any time a new hypothesis is being tested
- When converting an exploratory finding into a formal backtest — pre-register the formal test even if the exploration was unpinned
- Before a backtest runs in `finance-walk-forward-backtester`
- When reviewing a colleague's research proposal — "where's the pre-registration?" is the first question

## The checklist

### 1. State the null hypothesis

Not the alternative — the null. What is the version of the world you're trying to reject? "There is no excess return from signal X after transaction costs" is a null. "Signal X works" is not a null, it's a wish.

**Format:** a single sentence, negative in form, testable with data.

### 2. Define the universe

Exactly which tickers, exactly which date range, exactly which filters. "Large-cap US equities" is not a universe; the Russell 1000 constituents as of each month-end from 2005 to 2024, excluding the 48-hour window around M&A announcements, is a universe.

**Format:** the specific constituent list or rule, the specific date range, any explicit exclusions.

### 3. Define the sample window

In-sample period (where the signal was observed or hypothesised) and out-of-sample period (where the signal will be tested). The in-sample cannot overlap the out-of-sample. The out-of-sample must be a meaningful fraction of the total sample (typically ≥ 30%).

**Format:** start and end dates for each; the OOS window must be specified *before* the signal is computed.

### 4. Specify the OOS hold-out rule

Walk-forward with purged and embargoed folds is the minimum. Purge eliminates labels that overlap the test window. Embargo adds a buffer period to prevent leakage through autocorrelated features. State the fold count, the purge window length, and the embargo length.

**Format:** explicit fold parameters.

### 5. Define the success criteria

Exactly what numbers, at what significance, would cause you to accept the alternative hypothesis. Not "interesting", not "looks promising" — a specific threshold. Examples:
- "Deflated Sharpe > 1.0 at p < 0.05 after Bonferroni adjustment for 200 search trials"
- "OOS return > 2× transaction costs in at least 4 of 5 folds"
- "Regime-conditional returns positive in both expansion and contraction regimes"

**Format:** an ordered list of thresholds, with an "all required" or "any two of three" gate.

### 6. Define the stopping rule

When do you stop looking? Pre-registration is useless if the quant peeks at the data and keeps extending the test. State in advance:
- The number of parameter variations to be tested (not "as many as needed")
- The number of alternative universes to be tested (ideally: one)
- When the decision will be called final (date or number of trials)

**Format:** a cap on variations + a calendar deadline.

### 7. Multiple testing adjustment commitment

Commit in advance to applying multiple testing corrections based on the full search space — not the signals that "survived" the initial pass. If the search considered 200 variants, the adjustment is against 200, not against the 3 that looked good.

**Format:** method (Bonferroni, BH, Harvey-Liu) + committed search-space size.

## Example application

**Idea:** "Stocks with positive Form-4 insider buying in the prior 90 days outperform over the next 60 days."

**1. Null hypothesis:** Russell 3000 stocks with ≥3 open-market insider purchases in the 90-day window have no excess return (after costs) vs matched non-purchase stocks over the subsequent 60 days.

**2. Universe:** Russell 3000 constituents as of each month-end from Jan 2005 to Dec 2023. Exclude financials. Exclude names with market cap < $500M. Exclude the 10-day window around earnings releases.

**3. Sample window:** In-sample 2005-2018 (for signal observation and threshold calibration). OOS 2019-2023 (the test period, untouched until the specification is locked).

**4. OOS hold-out:** 5-fold walk-forward with quarterly folds, 5-day purge window, 2-day embargo. Purged folds only.

**5. Success criteria (all required):**
- Deflated Sharpe > 1.0 at p < 0.05, with Harvey-Liu haircut applied
- Positive OOS return in at least 4 of 5 folds
- Positive conditional return in both expansion and contraction regimes

**6. Stopping rule:**
- Maximum 50 parameter variants tested (hurdle = 3, 5, 10; holding period = 30/60/90 days; etc.)
- No additional universes tested (Russell 3000 only)
- Final decision date: end of calendar Q2, no extensions

**7. Multiple testing commitment:** Harvey-Liu adjustment against 50 variants. If fewer variants are tested, the adjustment is still against 50 — no rewarding restraint after the fact.

## Anti-patterns

- "I'll decide the OOS window after I see the results" — that's not OOS
- "I only ran 5 variants" after running 50 — the search space is the true denominator, not the reported one
- Stopping rules like "when it looks good" — not a stopping rule
- Success criteria like "interesting results" — not criteria
- Changing the universe mid-test because "financials are weird" — selection bias

## Caveats

This skill is the front door to `finance-walk-forward-backtester` and `finance-multiple-testing-adjuster`. Pre-registration is only useful if the downstream analysis honours it — the backtester needs to enforce the OOS window, and the multiple-testing adjuster needs the true search-space size. Pair them. Pre-registration alone, with undisciplined execution, is security theatre.
