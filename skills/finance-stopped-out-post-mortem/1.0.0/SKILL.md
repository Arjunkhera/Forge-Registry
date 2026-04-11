---
id: finance-stopped-out-post-mortem
name: Stopped-Out Post-Mortem
---

# Stopped-Out Post-Mortem

## Purpose

When the trader gets stopped out, there are three different failures that look the same from the outside but carry completely different lessons:

1. **The thesis was wrong.** The company was not what you thought it was, the setup was not what you thought it was, or the market was doing something different than you read. Lesson: upgrade your reading of the situation.
2. **The timing was wrong.** The thesis was correct, but you were early. The move happened, just not when you were in it. Lesson: improve your entry timing — wait for the confirming tape, not the anticipatory one.
3. **The stop placement was wrong.** Both thesis and timing were right, but the stop was in a spot the normal noise of the trade would hit. Lesson: widen the stop and size down next time, or accept the setup requires wider range than you were willing to trade.

Conflating these three is how the trader learns nothing from a losing streak. This skill is invoked within an hour of the stop-out, while the tape and the reasoning are still fresh.

## Primary user

`finance-swing-trader`. The trader will not do this in a spreadsheet after the fact. They need the skill invoked immediately — the difference between learning from a loss and flinching from a loss.

## When to invoke

- Within one hour of getting stopped out. Not the same day, not the same week — one hour. Before the tape moves on and the reasoning contaminates.
- On both full and partial stop-outs.
- Also on scratch exits if something feels off about the exit itself.

## The template

**1. Name the trade.** Ticker, direction, entry, stop, exit, setup tag, conviction tier at entry, market phase at entry.

**2. Classify the failure mode.** Exactly one of:
  - **Thesis wrong** — did the market move against the thesis in a way that says the thesis was never right? Did the company report something that invalidated the story? Did the tape reject the setup type entirely?
  - **Timing wrong** — did the price ultimately do what you expected but on a later candle? Did you enter before a confirmation that was needed? Did the market chop you out and then go?
  - **Stop placement wrong** — did the normal noise of the move stop you out, in a spot no disciplined trader should have placed the stop? Was the stop inside the typical range of the setup?

**If you're tempted to check more than one box, you're flinching. Pick one. The one that hurts most to admit is usually the right one.**

**3. The honest reading.** One paragraph. What happened, in the trader's own vocabulary. No narrative smoothing. If you didn't actually understand the phase at entry, say so. If you were forcing a trade after a losing streak, say so.

**4. The one thing to do differently.** Not a list. One concrete change to the *process* (not the *outcome*) that would have changed this trade. "Wait for the retest to hold before entering" is a process change. "Don't take losing trades" is not.

**5. File against setup taxonomy.** Hand off to `finance-setup-journal` (sub-agent) with the classification and the lesson. The journal tracks hit rates per failure mode per setup, and over time the trader learns which setups have thesis failures vs timing failures vs stop failures.

## Example application

**Trade:** Long MSFT at 420, stop 415, exit at 414.80 (filled through stop)

**Classification:** Timing wrong. The thesis (mega-cap breakout after a tight base) was correct — MSFT closed at 428 two days later. The entry was early — I took the break of 420 on the first touch instead of waiting for the retest to hold.

**Honest reading:** I was in three positions already, all working, and I wanted the fourth before the market closed because the setup looked clean. I entered on the initial break rather than waiting for the retest, even though my playbook says breakout-retest is specifically a wait-for-the-second-touch setup. The exit happened within the normal range of a retest. The trade would have worked if I'd waited.

**One thing to do differently:** On breakout-retest setups, no entry until the retest confirms with volume. No exceptions for "cleanness" of the setup — the patience is the setup.

**Filed:** breakout-retest, timing-failure, conviction B+, trending phase.

## Anti-patterns

- Checking multiple boxes on step 2 — you're flinching
- Saying "the market was irrational" on step 3 — the market was the market; the trade was the trade
- "Don't take losing trades" on step 4 — not a process
- Skipping step 5 — the whole learning loop runs through the journal

## Caveats

This skill assumes the stop was hit for a real reason, not because the trader moved the stop during the trade. If the trader was stop-shifting mid-trade, that's a different failure mode and a different conversation — see `finance-phase-of-market` if the mid-trade panic was regime-confusion, or escalate to the portfolio-level discipline.
