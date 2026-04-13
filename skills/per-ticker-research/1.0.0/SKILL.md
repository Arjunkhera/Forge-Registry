---
id: per-ticker-research
name: Per-Ticker Research
---

# Per-Ticker Research

## Purpose

The primary research engine for individual stocks and tickers. Given a ticker, this skill: (1) checks Anvil for prior research and applies regime gating, (2) decides whether the signal is worth pursuing, (3) invokes a three-persona council in parallel, where each persona independently decides which sub-agents to call, (4) synthesises an aggregate verdict, and (5) writes an immutable Ticker Research Brief to Anvil. After the brief is stored, it triggers the Map Keeper to update the knowledge hierarchy (fire-and-forget).

This is the end of the critical-path research loop. The Research Lead is the router; this skill is where the actual ticker work happens.

## Primary user

Invoked by the Research Lead when it routes a ticker request. Can also be invoked directly via `/per-ticker-research` for testing or by a power user who wants to skip the pre-check.

## Input interface

Received from the Research Lead (or from the user when invoked directly):

```
ticker: <ticker symbol, e.g. "NVDA">
regime: <current regime from Research Lead pre-check>
context: <optional free-text from user — the "why am I asking" signal>
prior_regime_check: <tape-reader summary from Research Lead>
```

If invoked directly without a regime, call `finance-regime-classifier` once at the start to populate it. If `context` is missing, treat it as empty (not an error).

## Step 1 — Memory check

Query Anvil for prior research-briefs on this ticker:

```
anvil_search({type: "research-brief", query: "<TICKER>", limit: 20})
```

Filter the results to entries whose `subject` field equals the ticker. Order by `research_date` descending (most recent first).

For each prior brief:

- Compare `regime` field of prior brief to current regime.
- **Same regime** → flag as **valid context**. This brief is a foundation to extend or confirm.
- **Different regime** → flag as **potentially stale**. Surface explicitly in the council input: *"Prior research from [date] written under [old regime]; current regime is [new regime] — treat as context only, not foundation."*

Build a `prior_research_summary` string for the council: the most recent valid-context brief's verdict + thesis summary, plus an inventory line listing how many briefs exist in this ticker's history and how many are stale under the current regime.

If no prior briefs exist, set `prior_research_summary` to: *"Initial research — no prior work for this ticker."*

Hold onto the `noteId` of the most recent prior brief (regardless of regime) — it becomes the `prior_brief` field in Step 5.

## Step 2 — Signal gate

Decide whether to proceed:

- `prior_regime_check` shows no setup AND `context` is empty → **stand down**. Return a brief stand-down message to the caller and exit. Do not write a brief.
- `prior_regime_check` shows a setup OR `context` is non-empty → **proceed**.

**Phase 1 rule:** the tape-reader runs in shell mode and returns a placeholder. Treat any placeholder/shell response as **mild signal — proceed with low-conviction flag**. This is intentional: it allows end-to-end pipeline testing while live data is still wired up. Do NOT stand down on a Phase 1 placeholder.

## Step 3 — Persona council (parallel invocations)

Invoke the three personas as **parallel** Agent tool calls in a single message. Do not run them sequentially — the council loses its independence-of-thought property if the personas can see each other's drafts.

Common input passed to all three:

- `ticker`
- `regime`
- `prior_research_summary`
- `context`
- A note that this is Phase 1 and sub-agents return structured placeholders

### finance-equity-analyst

- **Focus:** thesis, catalyst, variant perception, bear case
- **Sub-agents the persona may call (its choice, not prescribed):** `finance-filings-diff`, `finance-transcript-parser`, `finance-fcf-bridge`, `finance-consensus-scraper`
- **Returns:**
  - `thesis` — the one-line thesis
  - `catalyst` — the specific event that forces the re-rate
  - `variant_perception` — where the analyst differs from consensus
  - `bear_case` — the strongest argument against, and why the analyst still holds the view
  - `sub_agents_invoked` — list of agent IDs the persona actually called
  - `analysis` — the body of the read (a few paragraphs)
  - `verdict` — one of `actionable`, `monitor`, `no-edge`

### finance-swing-trader

- **Focus:** setup quality, stop placement, market phase, conviction sizing
- **Sub-agents the persona may call:** `finance-tape-reader`, `finance-stop-and-size`, plus the `finance-phase-of-market` skill
- **Returns:**
  - `setup_assessment` — pristine / clean / messy / no-setup
  - `stop_level` — placeholder in Phase 1 (e.g. "stop placeholder — wired in Phase 2"); structured field still present
  - `conviction_tier` — A+ / A / B+ / B / pass
  - `phase_of_market` — accumulation / markup / distribution / markdown / unclear
  - `sub_agents_invoked`
  - `analysis`
  - `verdict` — `actionable`, `monitor`, or `no-edge`

### finance-quant

- **Focus:** signal validation, base rates, statistical caveats
- **Sub-agents the persona may call:** `finance-regime-classifier`, `finance-edge-decay-monitor`
- **Returns:**
  - `signal_quality` — the persona's read on whether this is signal vs noise
  - `base_rate_questions` — the empirical questions that need answering before sizing
  - `statistical_caveats` — sample-size / overfitting / regime-dependence flags
  - `sub_agents_invoked`
  - `analysis`
  - `verdict` — `actionable`, `monitor`, or `no-edge`

The skill does NOT prescribe sub-agents to the personas. The lists above are the *menu*, not the *order*. Each persona decides what it actually needs based on the input. A persona is allowed to call zero sub-agents if it has enough to form a view.

## Step 4 — Synthesis

**Aggregate verdict** — majority rule:

- 2-or-more `actionable` → `actionable`
- 2-or-more `no-edge` → `no-edge`
- Anything else (including 1 of each, or a 2-1 `monitor` split) → `monitor`

**Relation type** — set based on prior briefs:

| Condition | `relation_type` |
|---|---|
| No prior brief | `initial` |
| Prior brief, same regime, same directional verdict | `confirms` |
| Prior brief, same regime, adds new angle | `extends` |
| Prior brief, same regime, contradicts | `counter-argues` |
| Prior brief, different regime (most recent) | `stale` |

"Same directional verdict" = `actionable` matches `actionable`, or `no-edge` matches `no-edge`. `monitor` is treated as a new angle (`extends`) when paired with anything actionable, and as `confirms` when paired with `monitor`. When in genuine doubt between `confirms` and `extends`, prefer `extends` — it's the safer label for the Map Keeper to act on.

## Step 5 — Store research-brief in Anvil

Create the brief using `anvil_create_note` (NOT `anvil_create_entity` — that fails validation in this Anvil version):

```
anvil_create_note({
  type: "research-brief",
  title: "{TICKER} research brief — {YYYY-MM-DD}",
  tags: ["{ticker-lowercase}", "ticker-research", "{regime}"],
  fields: {
    subject: "{TICKER}",
    research_date: "{ISO date}",
    regime: "{current regime}",
    source_signals: "{trigger info from Research Lead — pre-check summary + user context}",
    personas_invoked: "equity-analyst, swing-trader, quant",
    sub_agents_invoked: "equity-analyst: [{agents}]; swing-trader: [{agents}]; quant: [{agents}]",
    verdict: "{aggregate verdict}",
    relation_type: "{relation_type}",
    prior_brief: "{noteId of most recent prior brief, or empty string if initial}"
  },
  body: "<full structured brief — see body template below>"
})
```

**Body template** (markdown):

```markdown
## Brief metadata
- Ticker: {TICKER}
- Date: {ISO date}
- Regime: {current regime}
- Aggregate verdict: {verdict}
- Relation to prior: {relation_type}{ — links to prior_brief id if any}

> **Phase 1 note:** sub-agents are operating in shell mode; outputs in this brief are structured placeholders, not live data. The brief is real; the underlying signal data is not yet wired up.

## Prior research summary
{prior_research_summary}

## Equity Analyst read
- Thesis: {thesis}
- Catalyst: {catalyst}
- Variant perception: {variant_perception}
- Bear case: {bear_case}
- Sub-agents invoked: {list}
- Verdict: {verdict}

{analysis}

## Swing Trader read
- Setup: {setup_assessment}
- Stop level: {stop_level}
- Conviction tier: {conviction_tier}
- Phase of market: {phase_of_market}
- Sub-agents invoked: {list}
- Verdict: {verdict}

{analysis}

## Quant read
- Signal quality: {signal_quality}
- Base rate questions: {base_rate_questions}
- Statistical caveats: {statistical_caveats}
- Sub-agents invoked: {list}
- Verdict: {verdict}

{analysis}

## Synthesis
{2–4 sentences explaining how the three reads fit together, where they agree, where they disagree, and why the aggregate verdict landed where it did}
```

The brief is **immutable** by convention. If new evidence emerges, write a new brief and let the `prior_brief` chain handle history. Never mutate a stored brief in-place.

## Step 6 — Trigger Map Keeper (fire-and-forget)

Invoke the `finance-map-keeper` agent with the new brief's `noteId`. Do not wait for it to complete. Do not block the user's response on its result. If the agent is unavailable or errors, log a one-line note in the user-facing output but treat the brief itself as the deliverable.

## Output to user

```
Research brief created for {TICKER} — {brief_id}

Verdict: {aggregate verdict}
Regime: {current regime}
Relation to prior: {relation_type}{ ({prior_brief_date}) if applicable}

Equity Analyst: {one-line summary — thesis or stand-down reason}
Swing Trader: {one-line summary — setup or stand-down reason}
Quant: {one-line summary — signal quality or stand-down reason}

Full brief: anvil_get_note({brief_id})
Map Keeper: updating knowledge hierarchy...
```

If the Map Keeper failed to launch, replace the last line with: `Map Keeper: not triggered ({reason})`.

## Dependencies

- `finance-regime-classifier` (sub-agent) — invoked directly when the caller did not provide a regime
- `finance-tape-reader` (sub-agent) — referenced by swing-trader; the skill does not call it
- `finance-equity-analyst`, `finance-swing-trader`, `finance-quant` (personas) — the three council seats
- `finance-map-keeper` (agent) — fire-and-forget post-write trigger
- Persona-chosen sub-agents (menu listed in Step 3) — invoked transitively, not directly

All sub-agents operate in shell mode in Phase 1. Handle placeholder returns gracefully — do not stand down on them, do not crash on missing fields.

## Anti-patterns

- **Sequential persona invocations** — destroys independence-of-thought. The council must be parallel.
- **Prescribing sub-agents to personas** — the persona's autonomy IS the value. Pass context, not orders.
- **Mutating an existing brief** — briefs are immutable. Write a new one and chain it via `prior_brief`.
- **Standing down on Phase 1 placeholder responses** — defeats the point of end-to-end pipeline testing.
- **Skipping the memory check** — even a fast same-regime confirmation is cheaper than re-deriving a thesis from scratch.
- **Waiting on the Map Keeper** — it's a knowledge-graph maintainer, not a gating step. The brief is the deliverable.
- **Using `anvil_create_entity`** — fails validation in this Anvil version. Always `anvil_create_note` with `type: "research-brief"`.
- **Forgetting the `prior_brief` field on initial briefs** — set it to empty string explicitly so downstream consumers don't see undefined.

## Caveats

This skill is a coordinator, not an analyst. Its value is in (1) memory-aware regime gating, (2) parallel persona invocation with persona-chosen tooling, (3) deterministic synthesis rules, and (4) immutable, chain-linked storage. The actual reads come from the personas; the actual data (eventually) comes from the sub-agents. If the brief looks shallow in Phase 1, that is the shell-mode sub-agents talking — the structure is what we are validating.
