---
name: finance-multiple-testing-adjuster
description: >
  Sub-agent that applies Bonferroni, Benjamini-Hochberg, and Harvey-Liu haircut adjustments to a batch of candidate signals with raw t-stats, given the size of the search space that produced them. Refuses to forget the denominator. Primary caller: finance-quant.
---

# Multiple Testing Adjuster

## Purpose

Half of what gets pitched as edge is just the best bar in a histogram of 500 tries. This sub-agent refuses to forget the denominator. Given a batch of candidate signals with raw t-stats and the search space that produced them, it applies the standard multiple-testing corrections (Bonferroni, Benjamini-Hochberg, Harvey-Liu factor-investing haircut) and returns which signals survive adjustment and which were flattery.

## Primary caller

`finance-quant`. The quant wants a sub-agent that will not let p-hacking masquerade as discovery.

## Responsibility

For a set of candidate signals, each with a raw t-stat and associated search-space metadata, compute adjusted significance using multiple procedures and report the set of signals that remain statistically credible. Also estimate effective degrees of freedom consumed by the search process.

## Inputs

- `candidates` (list, required) — for each candidate: `signal_id`, raw `t_stat`, raw `p_value`, sample size, optional point estimate and standard error
- `search_space_size` (integer, required) — total number of hypotheses considered, even those that weren't reported
- `search_space_correlation` (number, optional) — average correlation between candidate signals in the search space (affects effective number of independent tests)
- `adjustment_methods` (list, optional) — default `[bonferroni, benjamini_hochberg, harvey_liu]`
- `alpha` (number, optional) — default `0.05`

## Outputs

- `per_candidate_adjusted` — table showing each candidate with raw t-stat, adjusted p-value under each method, and a survival flag per method
- `survival_set_bonferroni` — the subset that survives Bonferroni (strictest)
- `survival_set_bh` — the subset that survives Benjamini-Hochberg FDR control
- `survival_set_harvey_liu` — the subset that survives the Harvey-Liu factor-investing haircut
- `effective_independent_tests` — estimate of how many *independent* tests the search space contains, given internal correlation
- `degrees_of_freedom_burned` — estimate of how much the search space has eroded a naive significance claim
- `recommended_action` — which methods to trust for this batch given the characteristics of the search space
- `warning` — if `search_space_size` looks too small relative to the claimed number of discoveries (suspicion of under-reported trials)

## When to invoke

- Every time a researcher presents multiple candidate signals from a search
- Before a live deployment — the honest Sharpe haircut after multiple-testing adjustment is usually lower than the one that got the strategy approved
- When reviewing a batch of factor models — Harvey-Liu is specifically calibrated for factor-investing claims

## When NOT to invoke

- For a single pre-registered hypothesis that wasn't found by searching — multiple testing doesn't apply
- For pattern discovery without an explicit null — the sub-agent refuses to run without `search_space_size`

## Caveats — shell-only phase 2 artifact

This sub-agent describes an interface. The adjustment math is standard and implementable — what's stubbed is the workflow integration: knowing how many hypotheses were considered requires honest bookkeeping by the researcher, and phase 2 cannot audit that. The `search_space_correlation` estimation is the hardest realistic input and is deferred to a future phase when hypothesis correlation matrices are produced by the backtester.

## Cross-callers

- none expected; this is a quant-internal discipline tool
