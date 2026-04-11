---
id: finance-regime-change-playbook
name: Regime Change Playbook
---

# Regime Change Playbook

## Purpose

Historical correlation is a liability in a regime shift. The 2020 lesson — "diversified" books blew up because two positions that looked independent shared a factor exposure nobody had stress-tested, and the factor exposure only revealed itself when the regime changed. This playbook is invoked the moment the vol, correlation, or rates regime breaks, and it walks the PM through the specific moves to make before the book gets hurt more.

## Primary user

`finance-portfolio-manager`. The PM's regime-break discipline is the difference between surviving a drawdown and becoming a forced seller. This skill is the cold-water version of "what do I do right now".

## When to invoke

- Vol regime break — realised or implied vol breaks out of its recent range, typically when VIX crosses a major level or the vol-of-vol expands
- Correlation regime break — when historical correlations stop holding, typically when previously diversifying assets start moving together (or when correlated assets decouple)
- Rates regime break — when the path of rates changes faster than the curve previously implied, or when the curve re-shapes meaningfully
- When the allocator's `finance-macro-regime-tracker` emits a `wake_up` signal — the playbook is the PM's response to that signal

## The playbook

### 1. Stop trusting historical correlation

The first rule is: the correlation matrix that got you through the last 18 months is now lying. Re-run the book's risk metrics using stress-compressed correlation assumptions (`correlation_override: stress_compressed` in `finance-factor-decomposer` and `finance-stress-runner`). The numbers you see are the numbers you're actually running, not the ones the historical matrix said you were running.

**Action:** Re-run factor decomposer and stress runner with stress-compressed correlations before any trading decision is made.

### 2. Identify which positions cluster under the new regime

In regime shifts, positions that were diversifying become concentrated and vice versa. Identify:
- **Hidden cluster winners:** positions that were independent and have now collapsed into a single factor bet — these are the stacked risk you didn't know you had
- **Hidden cluster losers:** positions that were concentrated and have now diversified — these can be trusted more now than they could before

**Action:** Rank book by marginal risk contribution under the new correlation assumption. Top 3 are the first candidates for trimming.

### 3. Cut the hidden-cluster winners first

Rotation in a regime shift starts with cutting the positions that are silently concentrating the book, not the positions that look the worst on single-name P&L. The single-name P&L tells you nothing about regime risk.

**Action:** Trim 25-50% from each hidden-cluster winner, sized to bring book factor exposures back inside caps. Do this before any new entries.

### 4. Re-underwrite vol assumptions

The vol you were using for sizing is probably wrong. If realised vol has expanded by 50% or more, position sizing that was correct two weeks ago is now double the risk it looked like. Re-check vol estimates per position against recent (5-10 day) realised vol, not the 90-day or 252-day window.

**Action:** Reduce position sizes where realised vol has materially outrun the vol assumed in sizing. Do not wait for the full re-check — size to the new vol immediately for any positions > 3% book NAV.

### 5. Identify the liquidity choke points

Regime shifts and liquidity crunches arrive together. Check `finance-stress-runner` with a 3-day liquidity horizon and flag any positions where the exit cost under stressed ADV is > 1% of book NAV. Those positions are not exitable in a forced-selling scenario — size them accordingly or pre-exit.

**Action:** Pre-trim any position where forced-exit cost is > 1% of book NAV. Leave a margin for error.

### 6. Identify which hedges still work

The hedges that worked in the old regime may not work in the new one. A long-vol hedge is effective in a vol expansion but not in a slow grind. A short-credit hedge is effective in a risk-off move but not in a rates-driven selloff. Re-map the hedge book against the new regime.

**Action:** For each hedge position, state the regime it's effective in and whether the current regime matches. Replace hedges that don't match.

### 7. Re-state the risk budget

The risk budget you had in the old regime is wrong for the new one. If vol has doubled, the same position sizes carry twice the vol contribution. Either the risk budget number goes up (which is rarely what the PM wants in a stress) or the position sizes come down. Usually the sizes come down.

**Action:** Re-state the risk budget against the new vol regime. Most PMs should reduce gross exposure 20-40% in a regime shift, not hold steady.

### 8. Pre-commit to the re-entry triggers

Once the book is repositioned for the new regime, pre-commit to what signals would allow re-building gross exposure. Otherwise the PM spends the shift out of risk and misses the rebuild.

**Action:** State three conditions that would signal the regime is stable and exposure can be rebuilt. Write them down. Enforce them.

## Example application

**Trigger:** VIX breaks 28 after 6 months below 20; 2y-10y curve re-inverts on a Fed pivot.

**Step 1:** Re-run factor decomposer with stress-compressed correlations. Result: book factor exposure to growth moves from 35% to 52% — NVDA, MSFT, AVGO are now one factor bet.

**Step 2:** Hidden-cluster winners: MSFT/AVGO/NVDA triplet (now correlated 0.85+). Hidden-cluster losers: healthcare defensives, now diversifying again.

**Step 3:** Trim 40% of each of MSFT/AVGO/NVDA. Book factor exposure to growth falls to 38% — inside cap.

**Step 4:** Realised vol on the book has risen from 12% to 19%. Position sizes > 3% NAV re-sized to match.

**Step 5:** Two illiquid positions identified with > 1% NAV exit cost in a 3-day forced exit — pre-trimmed to 1% book NAV each.

**Step 6:** Long-vol hedge (VXX) remains effective. Short-credit hedge (HYG puts) re-upped for the rates regime. Short-equity index hedge added as overlay.

**Step 7:** Gross exposure reduced from 180% to 130%. Net exposure reduced from 65% to 40%.

**Step 8:** Re-entry triggers: (a) VIX closes below 22 for 5 consecutive days, (b) 2y-10y curve re-steepens to > 0, (c) HY credit spreads tighten by > 30 bps from peak. Two of three required before adding back gross.

## Anti-patterns

- Waiting for the single-name P&L to tell you the regime has changed — it tells you too late
- Trimming winners last because "don't interrupt momentum" — in regime shifts, yesterday's momentum is tomorrow's beta
- Holding historical correlation assumptions because "they'll normalise" — they might, after the book is already hurt
- Pre-committing to exposure levels but not to re-entry triggers — guarantees the shift is survived and the rebuild is missed

## Caveats

This skill is the PM's crisis playbook. It assumes the book is already well-constructed enough that rotation is possible and liquidity is available. A book that is already deeply concentrated or already illiquid has fewer options and needs pre-commitment before the regime shifts, not during. Pair with `finance-position-fit-pre-mortem` to ensure new positions in the regime-adjusted book are sized correctly.
