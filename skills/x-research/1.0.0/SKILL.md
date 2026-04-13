---
id: x-research
name: X Research
---

# X Research

## Purpose

Research module for X (Twitter) content. Given a tweet URL, X account handle, or pre-fetched tweet text, this skill: (1) acquires the content (Phase 1: user-paste fallback), (2) runs a content assessment quality gate, (3) invokes a two-persona council (swing-trader + equity-analyst) in parallel, (4) synthesises an aggregate verdict and the set of tickers/themes flagged, and (5) writes an immutable X Research Brief to Anvil. The Map Keeper is triggered fire-and-forget after the brief is stored.

Structurally simpler than the Per-Ticker Research Module: no memory check, no prior-brief chain, two personas instead of three. The content assessment gate is the critical quality mechanism — without it, this module creates briefs for every noise tweet.

## Primary user

Invoked by the Research Lead when it routes an X-shaped input. Can also be invoked directly via `/x-research` with pre-fetched text for testing.

## Input interface

Received from the Research Lead (or direct invocation):

```
input_type: "tweet_url" | "account_handle" | "text"
input: <tweet URL, @handle, or raw tweet text>
context: <optional free-text context from user>
regime: <current regime from Research Lead pre-check>
fetch_result: <pre-fetched content if available, otherwise null>
```

## Step 1 — Content acquisition

Resolve the content to analyse:

- `fetch_result` is non-null → use it directly.
- `input_type == "text"` → use `input` directly as the content.
- `input_type in ("tweet_url", "account_handle")` AND `fetch_result` is null → **user-paste fallback**. Log to the user:

```
Note: automatic X content fetching is not yet implemented (Phase 1).
Please paste the tweet text below.
```

Wait for the user's paste and use that as the content. Do NOT guess at tweet content from the URL. If the user declines to paste, return a stand-down to the Research Lead — no brief created.

**Phase 1 fetch decision:** user-paste IS the implementation. WebFetch on x.com is blocked (HTTP 402), public Nitter instances are unreliable, and the X API v2 has no free tier for new developers. The graceful fallback is sufficient for Phase 1. Phase 2 will switch to Chrome DevTools MCP for authenticated browser fetch — that is explicitly out of scope here.

## Step 2 — Content assessment (quality gate)

Before invoking the persona council, do a quick scan of the content:

1. **Specificity** — does it mention concrete tickers, companies, sectors, or themes? (Yes/No)
2. **Substance** — does it contain a specific claim, catalyst, number, filing reference, or notable event? (Yes/No)
3. **Financial signal** — is this substantive financial content vs generic commentary? (Yes/No)

**Gate:**
- At least one "Yes" on specificity AND one "Yes" on substance or financial signal → **proceed**.
- All "No" (e.g., "markets are crazy today", "watch your risk folks") → **stand down**. Return to Research Lead with the reason: "content assessed as generic commentary with no specific financial signal." No brief created.

Be firm on this gate. The cost of a noise brief is high — it pollutes the knowledge graph and desensitises downstream consumers. When in doubt, stand down.

## Step 3 — Persona council (parallel invocations)

Invoke both personas as **parallel** Agent tool calls in a single message. Do not run them sequentially.

Common input passed to both:

- `content` (the tweet text)
- `context` (any user context)
- `regime` (current market regime)
- `source` (the original tweet URL / account handle / "pasted text")
- A note that this is Phase 1 and sub-agents operate in shell mode

### finance-swing-trader

- **Focus:** is there a setup signal? Does this content change the tape picture for any mentioned ticker?
- **Sub-agents the persona may call (its choice):** `finance-tape-reader` for each mentioned ticker, `finance-phase-of-market` (skill) for broader market read
- **Returns:**
  - `signal_assessment` — real-signal / maybe / no-signal
  - `tickers_flagged` — list of tickers referenced that the trader now wants to watch
  - `themes_flagged` — list of sectors/themes worth tracking
  - `conviction_level` — A+ / A / B / pass
  - `sub_agents_invoked` — list of agent IDs actually called
  - `analysis` — body of the read
  - `verdict` — `actionable`, `monitor`, or `no-edge`

### finance-equity-analyst

- **Focus:** fundamental signal, catalyst identification, variant perception. Does this tweet cite a filing, a number, or a claim worth verifying?
- **Sub-agents the persona may call:** `finance-filings-diff` (if tweet references a filing), `finance-transcript-parser` (if tweet cites an earnings call quote), `finance-consensus-scraper` (to sanity-check "street view" claims)
- **Returns:**
  - `fundamental_assessment` — strong-claim / weak-claim / noise
  - `tickers_flagged` — list of companies referenced worth further work
  - `themes_flagged` — list of sectors/themes worth tracking
  - `catalyst` — identified catalyst (if any), with date/trigger
  - `variant_perception` — where the analyst differs from the tweet's framing
  - `sub_agents_invoked`
  - `analysis`
  - `verdict` — `actionable`, `monitor`, or `no-edge`

The skill does NOT prescribe sub-agents — the sub-agent lists are a menu the persona may draw from. Each persona decides what it actually needs. Zero sub-agents is a valid persona choice.

## Step 4 — Synthesis

**Flagged set** (deduplicated union):

- `tickers_flagged = swing_trader.tickers_flagged ∪ equity_analyst.tickers_flagged`
- `themes_flagged = swing_trader.themes_flagged ∪ equity_analyst.themes_flagged`

**Aggregate verdict:**

- Both `no-edge` → **stand down**. Do NOT write a brief. Return to Research Lead with "both personas returned no-edge after content review."
- Otherwise → higher-conviction verdict wins: `actionable` > `monitor` > `no-edge`.

X research briefs always have `relation_type = "initial"`. There is no prior-brief chaining for X research.

**Subject field rule:**
- Exactly one ticker flagged → use that ticker (e.g., "NVDA").
- Exactly one theme flagged and no tickers → use that theme (e.g., "semiconductors").
- Multiple flags, or zero flags → "X research".

## Step 5 — Store X Research Brief in Anvil

Use `anvil_create_note` (NOT `anvil_create_entity` — that fails validation in this Anvil version):

```
anvil_create_note({
  type: "research-brief",
  title: "X research brief — {source} — {YYYY-MM-DD}",
  tags: ["x-research", "{source-slug}", "{regime}"] + [each ticker lowercased],
  fields: {
    subject: "{subject per rule above}",
    research_date: "{ISO date}",
    regime: "{current regime}",
    source_signals: "{tweet URL or @handle or 'pasted text'}",
    personas_invoked: "swing-trader, equity-analyst",
    sub_agents_invoked: "swing-trader: [{agents}]; equity-analyst: [{agents}]",
    verdict: "{aggregate verdict}",
    relation_type: "initial",
    prior_brief: ""
  },
  body: "<full structured brief — see template below>"
})
```

**Body template** (markdown):

```markdown
## Brief metadata
- Source: {tweet URL / @handle / pasted text}
- Date: {ISO date}
- Regime: {current regime}
- Aggregate verdict: {verdict}
- Tickers flagged: {comma-separated list or "none"}
- Themes flagged: {comma-separated list or "none"}

> **Phase 1 note:** sub-agents are operating in shell mode; outputs in this brief are structured placeholders, not live data. The brief is real; the underlying signal data is not yet wired up.

## Content summary
{2–3 sentences paraphrasing the tweet content — do not paste the raw tweet verbatim if it contains PII or speculation that shouldn't live in the knowledge graph}

## Swing Trader read
- Signal assessment: {signal_assessment}
- Tickers flagged: {list}
- Themes flagged: {list}
- Conviction: {conviction_level}
- Sub-agents invoked: {list}
- Verdict: {verdict}

{analysis}

## Equity Analyst read
- Fundamental assessment: {fundamental_assessment}
- Tickers flagged: {list}
- Themes flagged: {list}
- Catalyst: {catalyst or "none identified"}
- Variant perception: {variant_perception}
- Sub-agents invoked: {list}
- Verdict: {verdict}

{analysis}

## Synthesis
{2–3 sentences on how the two reads fit together, what the combined flagged set means, and why the aggregate verdict landed where it did}
```

The brief is **immutable** by convention. X research runs never chain — each is its own initial brief.

## Step 6 — Trigger Map Keeper (fire-and-forget)

Invoke the `finance-map-keeper` agent with the new brief's `noteId`. Do not wait for completion. If the agent is unavailable, include a one-line note in the user output.

## Output to user

```
X research brief created — {brief_id}

Source: {tweet URL / @handle / "pasted text"}
Tickers flagged: {list or "none"}
Themes flagged: {list or "none"}
Verdict: {aggregate verdict}
Regime: {current regime}

Swing Trader: {one-line summary}
Equity Analyst: {one-line summary}

Full brief: anvil_get_note({brief_id})
Map Keeper: updating knowledge hierarchy...
```

If the content gate stood down, return instead:

```
X research stand-down — {source}

Reason: {content assessment reason}
Regime: {current regime}

No brief created.
```

## Dependencies

- `finance-swing-trader`, `finance-equity-analyst` (personas) — the two council seats
- `finance-map-keeper` (agent) — fire-and-forget post-write trigger
- Persona-chosen sub-agents (menu listed in Step 3) — invoked transitively, not directly

All sub-agents operate in shell mode in Phase 1. Handle placeholder returns gracefully.

## Anti-patterns

- **Guessing tweet content from a URL** — never. Ask the user to paste.
- **Creating a brief when both personas return `no-edge`** — the stand-down IS the output.
- **Skipping the content assessment gate** — the gate is the value. Without it, the knowledge graph fills with noise.
- **Mutating a stored brief** — briefs are immutable.
- **Pasting the raw tweet verbatim into the brief body** — paraphrase instead. Tweets can contain PII, emoji noise, or speculation that shouldn't be graph-indexed.
- **Chaining X briefs via `prior_brief`** — X research is always `relation_type = initial`.
- **Waiting on the Map Keeper** — fire-and-forget. The brief is the deliverable.
- **Using `anvil_create_entity`** — fails validation. Always `anvil_create_note` with `type: "research-brief"`.

## Caveats

X is high-volume, low-signal by default. This module's job is to be a strict filter with enough structure that the legitimate signals get properly processed. The fetch mechanism (user-paste) is deliberately manual in Phase 1 — that friction is a feature, not a bug, while the content gate is still being calibrated. Phase 2 will automate the fetch via Chrome DevTools MCP but will NOT relax the content gate.
