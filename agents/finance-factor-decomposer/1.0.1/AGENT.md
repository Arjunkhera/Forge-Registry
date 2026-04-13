---
name: finance-factor-decomposer
description: >
  Sub-agent that takes a portfolio book and returns factor-mapped exposures (equity beta, rates DV01, credit spread DV01, USD, oil, momentum, value, size, quality) plus marginal contribution to risk per position and the top three hidden correlations. Primary caller: finance-portfolio-manager.
---

# Factor Decomposer

## Purpose

The PM's single indispensable tool. It takes the current book and returns the factor-mapped exposures — what bets the portfolio is *actually* on, versus what the position list suggests it's on. A "diversified" book with five growth names and two credit shorts is one factor bet in disguise; this sub-agent makes that visible before the regime shift reveals it.

## Primary caller

`finance-portfolio-manager`. The PM does not engage with a single-name thesis until they know what adding it does to factor exposures already on. This sub-agent is the gate on sizing and the truth-teller about "diversification".

## Responsibility

Given a book (positions, weights, sensitivities) and a factor model definition, return the mapped exposures, marginal contribution to risk per position, and the hidden correlations that position-level eyeballing misses. The output must be actionable — naming the positions that are concentrating a factor bet, not just reporting "high momentum exposure".

## Inputs

- `book` (list of positions, required) — each position with: ticker, direction (long/short), notional, beta, duration, spread duration, FX exposure, commodity exposure, and any analyst-supplied factor tags
- `factor_model` (enum, required) — `baseline` (equity-beta, rates-DV01, spread-DV01, USD, oil, momentum, value, size, quality) or `custom` (caller supplies factor definitions)
- `period` (string, required) — the period the decomposition is anchored to (affects factor returns used in the covariance)
- `include_stress_view` (boolean, optional) — if true, also compute exposures conditional on a stressed regime

## Outputs

- `factor_exposures` — table of factor × net exposure, with gross on either side
- `top_factor_bets` — the three largest factor exposures the book is on, each with a one-line diagnosis
- `marginal_contribution_to_risk` — per-position contribution to portfolio volatility, ranked
- `hidden_correlations` — pairs of positions that look independent by sector/geography but share a dominant factor (e.g. two names that are both levered to the same rates move through different mechanisms)
- `concentration_flags` — factor exposures above a configurable threshold (default: any single factor > 40% of total risk)
- `attribution_snapshot` — for the trailing N days, attribution of P&L to each factor — to validate the model against reality
- `stress_exposures` (if requested) — how exposures change in a stressed regime (correlation compression, beta expansion)

## When to invoke

- Before sizing any new position — run with and without the proposed position to see the delta
- After every meaningful market move, to see whether realized P&L matches attribution
- When rotating exposure — to ensure the rotation is real, not just a relabel of the same factor bet
- Weekly as a discipline — the PM should know their factor map at all times

## When NOT to invoke

- For single-name research — factor decomposition at the book level assumes a book
- For allocation-level questions (asset class, cycle position) — this is a portfolio-level tool, not a strategic-allocation tool
- For pure thesis validation — factor exposure is orthogonal to whether the story is right

## Caveats — shell-only phase 2 artifact

This sub-agent describes an interface. The factor-model covariance matrix is the hardest part and is stubbed — phase 2 assumes a caller-supplied model or a placeholder. Integrating with a real factor model (Axioma, Barra, MSCI, or an in-house model) is deferred. Beta and duration estimates per position are assumed-supplied in phase 2, not computed.

## Cross-callers

- `finance-equity-analyst` — when suspicious that a "stock call" is secretly a value-factor bet
- `finance-quant` — to validate a factor hedge or when designing a factor-neutral strategy
- `finance-swing-trader` — when sizing a fourth position and wanting to know if the book has become one factor bet
