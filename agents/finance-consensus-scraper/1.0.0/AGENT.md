---
id: finance-consensus-scraper
name: Consensus Scraper
---

# Consensus Scraper

## Purpose

"Consensus" is a lie when reduced to a single mean. The analyst needs to know the full distribution of sell-side estimates, the velocity of revisions, and the specific line items where dispersion is widest — because that's where variant perception is already quantitatively visible and where a differentiated call can live. A shrinking dispersion on revenue but widening on margin is a completely different setup than the reverse, and both get lost in "the street has it at $4.50".

## Primary caller

`finance-equity-analyst`. The analyst needs to know where they're different from consensus *and* whether the street is converging toward them or away. This sub-agent makes that visible at the line-item level, not just the headline.

## Responsibility

For a ticker and forward periods, return the full sell-side estimate distribution at the line-item level (revenue, gross margin, EBIT margin, EPS, free cash flow, specific segments), the rolling revision velocity (how fast estimates are moving and in which direction), and flag line items where dispersion is wide or widening.

## Inputs

- `ticker` (string, required)
- `forward_periods` (list, required) — e.g. `[Q4-2025, FY2025, FY2026, FY2027]`
- `line_items` (list, optional) — default: `[revenue, gross_margin, ebit_margin, eps, fcf]`; supports segment-level if company reports segments
- `revision_lookback` (duration, optional) — default `90d`

## Outputs

- `per_period_distributions` — for each forward period and line item: analyst count, mean, median, high, low, standard deviation, coefficient of variation, distribution shape (bimodal flag)
- `revision_velocity` — for each line item: rate of change in consensus mean over the lookback, percentage of analysts who have revised up vs down vs held, and the implied directional conviction
- `dispersion_ranking` — line items ranked by coefficient of variation; the top of this list is where variant perception lives
- `recent_outliers` — analysts whose estimates have moved materially while consensus held, or vice versa — these are often the first movers on a thesis shift
- `dispersion_delta` — change in dispersion over the lookback; widening dispersion on a line item signals analysts are beginning to disagree, which usually precedes a re-rate
- `consensus_vs_guidance` — if company guidance is available, gap between consensus and the midpoint of guidance for each line item

## When to invoke

- When forming a thesis — to locate where variant perception is quantitatively plausible
- Before any re-rate event (earnings, investor day) — to understand where the pressure is
- Periodically on coverage universe to spot revision velocity shifts that precede narrative moves

## When NOT to invoke

- For price-target estimates — those are noise wrapped in false precision
- For small-cap names where consensus is 1-2 analysts — the distribution has no meaning
- For near-term trading signal — revision velocity is slow; tape is faster

## Caveats — shell-only phase 2 artifact

This sub-agent describes an interface. No sell-side data vendor wiring in phase 2 (Bloomberg, Visible Alpha, FactSet, Refinitiv are the realistic options). Until wired, the sub-agent assumes a manually supplied distribution or a stub feed. The line-item decomposition is the value — headline-only scraping misses the whole point of this sub-agent.

## Cross-callers

- `finance-quant` — for systematic revision-velocity signals and dispersion-based factors
- `finance-portfolio-manager` — to understand where the book has already-priced-in conviction vs not
