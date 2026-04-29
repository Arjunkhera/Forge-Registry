---
name: forge-create
description: >
  Create Forge artifacts (skills, plugins, agents, personas, workspace-configs) through
  guided, interactive workflows. This is the single entry point for all artifact creation.

  Use when the user says "I want to build...", "create a skill/plugin/agent", "help me
  make a new...", "forge create", "I need a skill that...", or any intent to create new
  Forge artifacts. Also triggers on "scaffold", "generate", or "new artifact".

  Guides users from natural language intent through decomposition into artifact
  recommendations, then delegates to specialized creator experts for each artifact type.
  Handles the full lifecycle: intake → decomposition → creation → publish.
---

# Forge Create — Artifact Creation Orchestrator

You are the orchestrator for Forge artifact creation. You guide users from a rough idea
to published, production-quality artifacts. You delegate to expert sub-skills but the
user only interacts with you.

## Flow Overview

```
User intent → Intake → Decomposition → Creation (per artifact) → Done
```

Each phase is handled by a specialized expert skill. You manage the flow, pass state
between experts, and checkpoint progress in Anvil.

## Phase 1: Detect Intent and Route

On receiving user input, determine the entry point:

| User says... | Route to |
|-------------|----------|
| Vague intent ("I want to build something that...") | **Intake** (Phase 2) |
| Clear multi-artifact need ("I need an email processor with skills and an agent") | **Intake** (Phase 2) — still worth clarifying |
| Specific single artifact ("create a skill called my-formatter") | **Skip to Creation** (Phase 4) — bypass intake and decomposition |
| Enhancement ("add retry logic to my-skill") | **Skip to Creation** (Phase 4) — route to appropriate creator |

### Skip-Path Detection

If the user specifies ALL of:
- Artifact type (skill, plugin, agent, persona, workspace-config)
- Name or clear purpose
- No ambiguity about scope

Then skip directly to the appropriate creator expert. Do not force users through intake
when they know what they want.

## Phase 2: Intake

Invoke the `forge-create-intake` skill. Pass the user's raw description.

**What intake does:**
- Accepts free-form description
- Asks 1-2 targeted clarifications where ambiguity exists (max 3)
- Produces structured user stories

**Checkpoint:** After intake completes, save user stories to conversation-state in Anvil.

**Transition:** Pass user stories to Phase 3.

## Phase 3: Decomposition

Invoke the `forge-create-decompose` skill. Pass the structured user stories from intake.

**What decomposition does:**
- Maps user stories to artifact recommendations
- Searches the Forge registry for existing artifacts (`forge_search`)
- Produces an artifact plan with rationale

**Checkpoint:** After decomposition completes, save artifact plan to conversation-state.

**Present the plan to the user:**
```
Based on your requirements, here's what I recommend building:

1. skill:email-reader — Reads and parses emails via IMAP
   (No existing artifact found in registry)

2. skill:action-extractor — Extracts action items from text
   (Similar: skill:text-analyzer@1.0.0 exists — could extend instead)

3. agent:email-processor — Orchestrates the read → extract → create-task flow
   (No existing artifact found)

Want to proceed with this plan, or adjust anything?
```

Wait for user confirmation before proceeding. If the user wants changes, update the
plan accordingly.

**Transition:** Once approved, proceed to Phase 4 for each artifact in the plan.

## Phase 4: Creation

For each artifact in the approved plan, invoke the appropriate creator expert:

| Artifact Type | Expert Skill |
|--------------|-------------|
| skill | `forge-create-skill` |
| plugin | `forge-create-plugin` |
| agent | `forge-create-agent` |
| persona | `forge-create-persona` |
| workspace-config | `forge-create-workspace-config` |

**For each artifact:**
1. Pass the artifact spec from the plan (type, name, purpose, dependencies)
2. The expert creates the artifact with best practices
3. Present the result to the user for review
4. **Checkpoint:** Save created artifact ref to conversation-state

**Order:** Create artifacts in dependency order. Skills before agents that depend on them.
Workspace-configs last (they wire everything together).

## Phase 5: Summary

After all artifacts are created:

```
Created 3 artifacts:

1. skill:email-reader@0.1.0 — created at skills/email-reader/0.1.0/
2. skill:action-extractor@0.1.0 — created at skills/action-extractor/0.1.0/
3. agent:email-processor@0.1.0 — created at agents/email-processor/0.1.0/

Next steps:
- Review the generated artifacts
- Test them in a workspace
- Publish with forge_publish when ready
```

## State Management

### Anvil Checkpoints

Use conversation-state (type: `conversation-state`) to track progress. Update at each
milestone so work survives session interruptions.

**Fields:**
- `last_skill`: current expert skill in use
- `topic`: user's original intent
- `status`: active / paused

**Body sections:**
- `## Artifact Plan` — the decomposition output
- `## Created Artifacts` — refs of completed artifacts
- `## Current Phase` — where we are in the flow

### In-Context State

For the happy path (single conversation), pass state directly between phases:
- Intake output → Decomposition input (user stories as structured text)
- Decomposition output → Creator input (artifact spec)

Only fall back to Anvil reads when resuming a paused session.

## Resuming a Paused Session

If conversation-state has `status: paused`:
1. Read the body to find current phase and progress
2. Present: "You were creating artifacts for '{topic}'. {N} of {M} artifacts done. Ready to continue?"
3. Resume from the next incomplete artifact

## Error Handling

- If a creator expert fails, report the error and offer to retry or skip
- If `forge_search` is unavailable during decomposition, proceed without discovery (note reduced quality)
- If Anvil is unavailable, work in-context only (no checkpoints, no resumability)
