---
name: sdlc-retrospective
description: >
  The learning extractor. Reviews session journals and scratch entries to surface patterns,
  decisions, and reusable insights from a working session. Promotes findings into Vault pages,
  skill doc updates, or new stories. Use this skill when the user wants to wrap up a session,
  capture learnings, run a retrospective, or review what happened in a session.

  Also use when the user says "what did we learn?", "retrospective", "wrap up", "what patterns
  did we find?", "session review", "capture learnings", or similar reflection-intent phrases.

  Can be triggered manually at any time or naturally at session boundaries.
---

# Retrospective Skill

You surface and formalise learnings from a working session. You review the session's journal entries, identify patterns and insights, and promote each finding to the right destination: a Vault page, a skill doc update, or a new story.

## MCP Tools Used

| Tool | Purpose |
|------|---------|
| `anvil_search` | Find journal entries tagged with learning signals |
| `anvil_get_note` | Read full journal entry content |
| `anvil_create_note` | Create a retrospective summary note |
| `knowledge_search` | Check if a learning already exists in Vault |
| `knowledge_resolve_context` | Load existing Vault pages to update |
| `knowledge_write_page` | Promote a learning to a Vault guide or concept page |

## Core Workflow

### Phase 1: Collect Session Signals

Search for journal entries from the current session (or a specified time window, default: last 24 hours) that carry learning signals:

1. `anvil_search` for type `journal` with tags: `#learning`, `#gotcha`, `#deviation`, `#decision`, `#pattern`, `#edge-case`, `#question`
2. `anvil_search` for type `journal` with tags: `#pivot`, `#scope-change`, `#blocker` — these often carry implicit learnings
3. Read full content of each entry via `anvil_get_note`
4. If the user specifies a work item or project, also search for journals tagged with that reference

### Phase 2: Synthesize

Group the raw journal entries into categories:

| Category | What it contains |
|----------|-----------------|
| **Gotchas** | Traps, pitfalls, surprising behaviours — tagged `#gotcha` |
| **Patterns** | Recurring structures or approaches — tagged `#pattern`, `#learning` |
| **Decisions** | Choices made and their rationale — tagged `#decision` |
| **Deviations** | Where the plan diverged from reality — tagged `#deviation` |
| **Open Questions** | Unresolved items — tagged `#question` |
| **Skill Gaps** | Moments where a skill gave bad guidance or was missing a step |

For each entry, determine:
- Is this **project-specific** (only relevant for one repo/project)?
- Is this **cross-project** (reusable across multiple projects or codebases)?
- Does this **reveal a gap in an existing skill**?

### Phase 3: Present Summary

Output a structured retrospective summary:

```
## Retrospective Summary — {date}

### Gotchas
- {description} — #{tag} [{journal-id}]

### Patterns
- {description} — #{tag} [{journal-id}]

### Decisions
- {description} — rationale: {rationale} [{journal-id}]

### Deviations
- {work-item}: {description} [{journal-id}]

### Open Questions
- {question} [{journal-id}]

### Skill Gaps Identified
- {skill}: {gap description}
```

Ask the user: "Which of these should we promote?" (or proceed automatically if in autonomous mode).

### Phase 4: Promote Findings

For each finding the user wants to promote:

**A. Cross-project learning → Vault page**

1. `knowledge_search` to check if a similar page already exists
2. If yes: update the existing page via `knowledge_write_page` (append the new insight)
3. If no: create a new `learning` type page via the Vault write-path (check duplicates → suggest metadata → validate → write)
4. Log in retrospective summary: "Promoted to Vault: {page-title}"

**B. Skill gap → Skill doc update**

1. Identify which SKILL.md in Forge-Registry needs updating
2. Present the proposed change to the user for approval
3. Edit the SKILL.md via the Edit tool
4. Log in retrospective summary: "Updated skill: {skill-name} — {change}"

**C. Follow-up action needed → New story**

1. If a learning reveals a bug, improvement, or missing feature, hand off to the **story** skill to create a tracked work item
2. Log in retrospective summary: "Created story: #{id} — {title}"

**D. Project-specific learning → Agent config**

1. Add to the project's `agent-config.md` under "Learned Mistakes" or "Known Patterns"
2. Log in retrospective summary: "Updated agent config for {project}"

### Phase 5: Create Retrospective Note

After promotions are complete, create a summary note in Anvil:

- Type: `journal`
- Title: `Retrospective: {session-date} — {work-item or project if scoped}`
- Tags: `#retrospective`, plus tags from promoted findings
- Body: the full retrospective summary with promotion outcomes

## Triggering

The retrospective skill can be triggered:

- **Manually:** "What did we learn this session?" / "Run retrospective"
- **At session end:** After a developer→tester→reviewer flow completes, suggest running retrospective as a final step
- **On demand for a specific work item:** "Retrospective for story #{id}"
- **Periodically:** "Retrospective for this week"

## What Not To Do

- Do not promote every single journal entry — only entries with genuine reusability or fix value
- Do not create Vault pages for project-specific quirks — those belong in agent config
- Do not create follow-up stories without user confirmation (unless explicitly in autonomous mode)
- Do not re-promote learnings that are already in Vault — update the existing page instead
