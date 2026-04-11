---
id: finance-transcript-parser
name: Transcript Parser
---

# Transcript Parser

## Purpose

Variant perception often sits in what management *dodges*. The prepared remarks are rehearsed; the Q&A is where the hedging, the reluctance, and the forced disclosures live. This sub-agent parses the full transcript and surfaces the pressure points — not a summary, not a sentiment score, but the specific moments where the analyst should look harder.

## Primary caller

`finance-equity-analyst`. The analyst wants to know what the CFO didn't want to answer, what line items management volunteered without being asked (suggesting they think it's good news), and where the analyst questions clustered (suggesting the street sees a problem the company is downplaying).

## Responsibility

Ingest an earnings call or investor-day transcript, separate prepared remarks from Q&A, and return a structured report of the pressure points: tone delta, hedging language, question clustering, and disclosure asymmetry. Surface the raw quotes for each finding — never paraphrase a critical phrase.

## Inputs

- `ticker` (string, required)
- `event_type` (enum, required) — `earnings_call`, `investor_day`, `capital_markets_day`, `conference_fireside`
- `event_date` (date, required)
- `transcript` (text or reference, required) — full transcript text or pointer to source
- `comparison_event` (optional) — prior quarter's call to compute deltas against

## Outputs

- `tone_delta` — prepared remarks vs Q&A, measured on: confidence (volunteered specifics vs high-level narrative), certainty (hedging phrase frequency like "we believe", "it's possible that", "we're not ready to guide"), and directional language
- `hedging_frequency` — count and rate of hedging phrases in Q&A, with the top 5 quoted verbatim with surrounding context
- `volunteered_numbers` — specific numbers or metrics management stated without being asked; flagged because these are the things management *wants* in the narrative
- `forced_disclosures` — numbers or metrics that only came out under direct analyst questioning; flagged because these are the things management didn't want to volunteer
- `analyst_question_clusters` — grouped by topic; topics with the most questions are where the street sees unresolved issues
- `dodged_questions` — questions that were asked but not answered substantively (non-answer response), with the question and the non-answer quoted
- `sequential_tone_shift` — if `comparison_event` provided, how tone and disclosure patterns have shifted quarter over quarter on the same topics
- `variant_perception_hooks` — topics where the transcript suggests management and consensus are misaligned

## When to invoke

- Right after every earnings call for a name in the coverage universe
- Before writing up a post-earnings note — let this catch what you missed on the live call
- When building a thesis, run it on the last 4-8 quarters to find the drift

## When NOT to invoke

- For sentiment scoring as an input to a trading signal — this sub-agent is evidentiary, not predictive
- For numeric extraction alone — use the filings sub-agents for hard numbers
- For quick summaries — this is not the tl;dr; it's the opposite

## Caveats — shell-only phase 2 artifact

This sub-agent describes an interface. Transcript ingestion source is not wired (no Seeking Alpha, no Bloomberg, no direct IR) — phase 2 assumes the transcript is supplied inline. The hedging-phrase detection and tone-delta logic are the load-bearing pieces and will need an LLM prompt or fine-tuned classifier in a future phase; phase 2 stubs them.

## Cross-callers

- `finance-portfolio-manager` — rarely, when a large book position reports and the PM wants the pressure points without waiting for the analyst note
- `finance-quant` — for feature engineering: tone-delta as a systematic feature, tested across earnings seasons
