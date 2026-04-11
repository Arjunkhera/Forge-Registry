---
id: finance-backtest-autopsy
name: Backtest Autopsy Template
---

# Backtest Autopsy Template

## Purpose

Every backtest handed to the quant is assumed to be lying in at least one of seven ways. This skill is the structured autopsy that goes through the seven categories before the quant engages with whatever the equity curve looks like. Catching the lies first is faster than arguing about them later.

## Primary user

`finance-quant`. The quant invokes this skill when anyone hands them a backtest — their own, a colleague's, a vendor's, a paper's. It is the minimum bar of skepticism.

## When to invoke

- Any time a backtest is presented for a decision
- Before running `finance-edge-decay-monitor` on a strategy — autopsy first, monitor second
- When reviewing a research paper's claims
- When the equity curve looks too good

## The seven lies

### 1. Look-ahead bias

Does the signal use data that was not yet available at the decision point? Common culprits:
- Point-in-time financial data replaced with restated data (e.g. GAAP restatements)
- Fundamental metrics computed using future quarters' reports
- Index constituent lists that include only surviving members retroactively
- Price data that includes a dividend adjustment before the ex-date

**Check:** every input to the signal must be provably available at the timestamp it's used. Demand the data vendor's snapshot timestamps, not the current-value timestamps.

### 2. Survivorship bias

Does the universe include only the names that survived through the backtest period? If so, the universe systematically excludes bankruptcies, delistings, and acquisitions — and the backtest is a survivor selection, not a testable edge.

**Check:** the universe must be reconstructed from the historical constituent list at each point in time, including dead names. If the data vendor can't supply a point-in-time constituent list, the backtest cannot be trusted.

### 3. Point-in-time data

Related to look-ahead but worth a separate line. Many signals depend on fundamental data that was revised after the fact. Using the restated value introduces lookahead that is invisible unless specifically checked.

**Check:** every fundamental data point must be the "as-reported" vintage, not the "most recently restated" vintage. This is a vendor question and a process question.

### 4. Transaction costs

Was the backtest run with realistic transaction costs including commission, spread, slippage, and market impact? A backtest that works on paper with zero costs is meaningless. A backtest that works with 5 bps costs on large-cap equities is probably real; a backtest that works with 5 bps on a thin microcap is a fantasy.

**Check:** transaction cost model must be documented. Spread and market impact must scale with ADV and volatility. Commissions alone are not transaction costs.

### 5. Capacity

Can the strategy actually be traded at a meaningful size, or is the return driven by tiny trades that can't scale? A strategy with a 2.0 Sharpe at $1M notional may have a 0.5 Sharpe at $100M notional after market impact — the capacity curve matters.

**Check:** run the backtest at 10×, 100×, 1000× the reported notional with scaled market-impact assumptions. If the Sharpe collapses, the strategy is a capacity fiction.

### 6. Sample size and degrees of freedom

How many independent observations does the result rest on? Rolling a quarterly-rebalanced strategy over 20 years is 80 observations. A daily strategy over 3 years is 750. A monthly signal tested over 5 years is 60 — and 60 is not enough. And how many degrees of freedom were burned to find the parameters that made the strategy work?

**Check:** compute the effective sample size (not the naive one), estimate the degrees of freedom consumed by parameter search, and deflate the Sharpe accordingly (hand off to `finance-multiple-testing-adjuster`).

### 7. Regime coverage

Does the backtest cover multiple regimes? A strategy validated on 2012-2019 covers low-vol expansion only. A strategy that hasn't been tested through 2008, 2020, and 2022 is not validated — it has been validated on a subset of history that happened to be favourable.

**Check:** run conditional returns via `finance-regime-classifier` and require positive returns in at least 2 distinct regime types. A strategy that only works in one regime is a regime bet, not an edge.

## Example application

**Backtest under autopsy:** "Value signal on US small caps, 2010-2023, Sharpe 1.8"

**1. Look-ahead:** Used Compustat current-value P/E. Compustat restates are common. **Possible look-ahead — demand point-in-time.**

**2. Survivorship:** Universe defined as "Russell 2000 members as of each year-end". Did the author use the point-in-time constituent list or the current one? If current, this is fatal. **Demand clarification.**

**3. Point-in-time:** P/E uses current fiscal year earnings. Were these "as-reported" or restated? **Demand clarification.**

**4. Transaction costs:** Backtest ran with 10 bps one-way costs. Small-cap universe has average bid-ask > 20 bps and market impact at scale. **Transaction cost model is inadequate.**

**5. Capacity:** Small-cap universe with monthly rebalancing at 5% portfolio turnover. Author ran at $10M notional. At $100M notional, market impact would meaningfully degrade the Sharpe. **Capacity curve must be shown.**

**6. Sample size:** 14 years of monthly rebalance = 168 observations. Not terrible. But how many parameter variants were tested? Not disclosed. **Demand search-space size for deflation.**

**7. Regime coverage:** 2010-2023 covers mostly low-vol expansion with one short shock (2020 March). No coverage of the 2008 crisis, the 2011 eurocrisis, or the full 2022 rates selloff. **Regime coverage is thin.**

**Verdict:** The Sharpe of 1.8 is a ceiling, not a point estimate. After accounting for inadequate cost assumptions, capacity degradation at scale, and regime-coverage thinness, the realistic expected live Sharpe is probably 0.5-0.8. Before engaging further: demand the point-in-time universe, as-reported fundamentals, a capacity curve, and a regime-conditional evaluation.

## Anti-patterns

- Starting with the Sharpe and working backwards ("impressive Sharpe, what's the story?") — start with the seven lies, then look at the curve
- Accepting "transaction costs at 10 bps" without asking if that matches the universe's realised spread
- Accepting a universe definition without asking how the constituent list was sourced
- Skipping the regime check because "the strategy is simple and should generalise" — simplicity is not generalisation
- Treating the autopsy as optional because "this is a credible researcher"

## Caveats

This skill is a checklist, not a verdict. A backtest that survives all seven checks is *more* credible — it is not *proven*. The only way to know whether a strategy works is to deploy it with real money and monitor it (see `finance-edge-decay-monitor`). The autopsy is the pre-deployment filter, not the final word.
