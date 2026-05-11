---
name: sdlc-spec
description: >
  Creates and maintains structured product specification documents in Anvil using
  the "spec" type. Solves the unnavigable monolith problem by enforcing 9 clearly
  delimited, independently updatable sections.

  Use when: writing requirements for a new feature, adding a user story, logging a
  council decision, marking a spec as locked, or updating any individual section.
  Trigger phrases: "create a spec for X", "write requirements for X", "add user
  story to X spec", "log a decision on X spec", "lock the X spec", "add a design
  note to X", "mark the spec as in-review", "advance the spec to locked".
---

# sdlc-spec

Creates and maintains structured product spec documents in Anvil. Each spec has 9
distinct navigable sections that can be updated independently without touching the rest.

## Input

One of:
- Feature/project name + description → **create** new spec
- Spec name or note ID + section name + content → **update** a section
- Spec name + new status (and optional version label) → **advance** status
- Spec name only → **read** and summarize current state

## Anvil Note Type

Use type `spec`. Always call `anvil_list_types` first to confirm it exists.
If absent, call `anvil_create_type` (see Edge Cases).

## Process

### 1. Resolve Mode

Search: `anvil_search(query: "{name}", type: "spec")`.

| Result | Content | Mode |
|--------|---------|------|
| No match | — | **Create** |
| Match found | Section + content | **Update section** |
| Match found | New status only | **Advance status** |
| Match found | Nothing | **Read** |

### 2. Create

```
anvil_create_entity(
  type: "spec",
  title: "{Feature Name} — Spec",
  fields: {
    type: "spec",
    version: "v0.1",
    status: "draft"
  },
  body: <full template below>
)
```

Optionally link to a parent project or design doc:
```
anvil_create_edge(sourceId: "<project-id>", targetId: "<spec-id>", intent: "parent_of")
```

### 3. Update Section

Each section has a stable H2 header. To update one:
1. `anvil_get_note` → read the full body
2. Locate the target section by its H2 header (see stable headers below)
3. Replace only that section's content
4. **Exception — Decisions Log and Observations:** prepend new entries (newest first),
   never delete old ones
5. Update the version label in the header line if this is a meaningful revision
6. `anvil_update_entity(noteId: "...", body: <revised body>)`

**Stable section headers — never rename these:**
- `## Personas`
- `## Scope`
- `## User Stories`
- `## Requirements`
- `## Non-goals`
- `## Decisions Log`
- `## Design Notes`
- `## Observations`

### 4. Advance Status

```
anvil_update_entity(
  noteId: "...",
  fields: { type: "spec", status: "locked", version: "v1.0" }
)
```

Also update the `> **Version:** … | **Status:** …` header line in the body to match.

**Valid transitions:** `draft → in-review → locked → superseded`

Never move backward. If the user asks to reopen a locked spec, create a new version
(supersede the old one, create a fresh entity at v2.0 draft).

## Template

Use this body exactly when creating a new spec:

```markdown
> **Version:** v0.1 | **Status:** Draft

## Personas

| ID | Name | Context | Cares about |
|----|------|---------|-------------|
| P1 | [TODO: name] | [TODO: who they are, one sentence] | [TODO: what matters most to them] |

## Scope

**In scope for v1:**
| Story | Title | Notes |
|-------|-------|-------|
| S1 | [TODO] | |

**Deferred:**
| Story | Title | Why deferred |
|-------|-------|-------------|
| — | [TODO] | |

## User Stories

---

### S1 — [TODO: Title]
**Who:** P1
**What:** I want to [TODO]
**Why:** so that [TODO]
**Acceptance:**
- [TODO]

**Why current model struggles:** [TODO or N/A]

---

## Requirements

Cross-cutting constraints. Outcome-only statements — no design choices embedded.

| ID | Requirement |
|----|-------------|
| R1 | [TODO: outcome statement] |

## Non-goals

| ID | What we are NOT doing | Why |
|----|----------------------|-----|
| NG1 | [TODO] | [TODO] |

## Decisions Log

Append-only. Newest entry first. Add entries — never delete.

---

### [TODO: Decision title] — [YYYY-MM-DD]
**Decision:** [TODO]
**Rationale:** [TODO]
**Decided by:** [TODO: author / council]

---

## Design Notes

Open "how" questions for the design phase. Not requirements. Remove a note here
once it is resolved and the answer is captured in the design doc.

**Note 1 — [TODO: topic]**
[TODO: open question or constraint for the design phase]

## Observations

Real-world anecdotes, bug reports, or user feedback that inform the requirements.
Append-only. Newest entry first.

---

### [TODO: Observation title] — [YYYY-MM-DD]
**Context:** [TODO: what was happening]
**Observed:** [TODO: what happened]
**Why it matters:** [TODO: requirement implication]

---
```

## Stage → Status Mapping

| Status | Meaning | Who sets it |
|--------|---------|------------|
| `draft` | Being written, not yet reviewed | Author |
| `in-review` | Under council or stakeholder review | Author |
| `locked` | Requirements frozen — design phase begins | Author / council |
| `superseded` | Replaced by a newer version | Author |

## Output

Report: spec title, version, status, what was created or updated, which sections
still have `[TODO]` placeholders.

## Edge Cases

- **Type `spec` missing:** `anvil_list_types` → `anvil_create_type` if absent. Safe
  to call on every new session before first spec creation.
- **Spec not found by name:** List search candidates, ask user to confirm.
- **Adding a story to a locked spec:** Flag — ask whether to supersede first or just
  note the story in Design Notes until a new version is started.
- **Status regression (locked → draft):** Refuse. Supersede the old spec and create
  a new draft entity instead. Never mutate a locked spec's status backward.
