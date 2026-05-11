---
name: sdlc-feature-doc
description: >
  Creates and updates a structured design document in Anvil for a software feature,
  tracking it through a 10-stage SDLC lifecycle: Idea → Discovery → Requirements →
  Design → Planning → Implementation → Integration → Review/QA → Ship → Retro.

  Use when: starting work on a new feature, advancing a feature to the next stage,
  logging design decisions or requirements, or checking what stage a feature is in.
  Trigger phrases: "create a design doc for X", "update the feature page for Y",
  "we're moving to design stage on X", "add requirements for X", "log discovery
  findings for X", "create a feature spec", "write the architecture for X",
  "advance X to implementation", "what stage is X at".
---

# sdlc-feature-doc

Creates and maintains a structured Anvil design document for a software feature,
tracking it through 10 SDLC stages from fuzzy idea to retrospective.

## Input

One of:
- Feature name + description → **create** a new design doc
- Feature name or note ID + stage content → **update** the active stage section
- Feature name only → **read** and report current stage

## Anvil Note Type

Use type `design-doc`. Always call `anvil_list_types` first to confirm it exists.
If absent, call `anvil_create_type` before creating any entity (see Edge Cases).

## Process

### 1. Resolve Mode

Search: `anvil_search(query: "{feature name}", type: "design-doc")`.

| Result | Content provided | Mode |
|--------|-----------------|------|
| No match | — | **Create** |
| Match found | Yes | **Update** |
| Match found | No | **Read** |

### 2. Create

```
anvil_create_entity(
  type: "design-doc",
  title: "{Feature Name}",
  fields: {
    type: "design-doc",
    stage: "1-idea",
    status: "idea"
  },
  body: <full template below>
)
```

Optionally link to a parent project:
```
anvil_create_edge(
  sourceId: "<project-noteId>",
  targetId: "<new-doc-noteId>",
  intent: "parent_of"
)
```

### 3. Update

1. `anvil_get_note` → read current body
2. Identify active stage from `fields.stage` or the 🔄 marker in the stage table
3. Replace only that stage's `##` section with the new content
4. `anvil_update_entity(noteId: "...", body: <revised body>)`

### 4. Advance Stage

When moving to the next stage (e.g. "move X to design"):
1. Mark old stage ✅ in the stage table
2. Mark new stage 🔄
3. Update `**Current Stage:**` line
4. Update fields: `anvil_update_entity(noteId: "...", fields: { type: "design-doc", stage: "4-design", status: "design" })`

## Template

Use this body exactly when creating a new doc:

```markdown
**Current Stage:** 🔄 1 — Idea

| # | Stage | Status |
|---|-------|--------|
| 1 | Idea | 🔄 In Progress |
| 2 | Discovery | ⬜ Not Started |
| 3 | Requirements | ⬜ Not Started |
| 4 | Design | ⬜ Not Started |
| 5 | Planning | ⬜ Not Started |
| 6 | Implementation | ⬜ Not Started |
| 7 | Integration | ⬜ Not Started |
| 8 | Review / QA | ⬜ Not Started |
| 9 | Ship | ⬜ Not Started |
| 10 | Retro | ⬜ Not Started |

---

## 1. Idea
*Fuzzy problem statement — "we need X" or "what if we could do Y."*

[TODO: describe the idea]

**Source:** (user feedback / product strategy / personal need / competitive pressure)

---

## 2. Discovery
*Understand the problem. Research how others solve it. Explore feasibility.*

[TODO: add discovery notes]

**Open questions:**
-

**Spikes / POCs:**
-

---

## 3. Requirements
*Define what we're actually building. Use cases, acceptance criteria, scope.*

**Use cases:**
-

**Acceptance criteria:**
-

**In scope:**
-

**Out of scope:**
-

---

## 4. Design
*How we're building it. Architecture, API contracts, data models, flows, trade-offs.*

[TODO: add design]

**Architecture:**

**API contracts:**

**Data models:**

**Key decisions:**
| Decision | Options | Choice | Rationale |
|----------|---------|--------|-----------|
| | | | |

---

## 5. Planning
*Break into chunks. Sequence, dependencies, estimates.*

| Chunk | Description | Depends on | Est. |
|-------|-------------|-----------|------|
| | | | |

---

## 6. Implementation
*Each chunk: pick up → code → PR. Repeated.*

| Chunk | PR / Branch | Status | Notes |
|-------|-------------|--------|-------|
| | | | |

---

## 7. Integration
*Chunks come together. End-to-end testing.*

[TODO: add integration notes]

**E2E test results:**

---

## 8. Review / QA
*Requirements met? Edge cases, performance, security.*

- [ ] Requirements met
- [ ] Edge cases covered
- [ ] Performance acceptable
- [ ] Security reviewed

**Findings:**

---

## 9. Ship
*Deploy, monitor, rollout.*

**Deploy date:**
**Rollout strategy:**
**Monitoring:**
**Post-ship issues:**

---

## 10. Retro
*What worked, what didn't. Docs updated. Closed.*

**What worked:**
**What didn't:**
**Docs updated:**
```

## Stage → Field Mapping

| Stage | fields.stage | fields.status |
|-------|-------------|---------------|
| 1 Idea | 1-idea | idea |
| 2 Discovery | 2-discovery | discovery |
| 3 Requirements | 3-requirements | requirements |
| 4 Design | 4-design | design |
| 5 Planning | 5-planning | planning |
| 6 Implementation | 6-implementation | in-progress |
| 7 Integration | 7-integration | in-progress |
| 8 Review / QA | 8-review | in-review |
| 9 Ship | 9-ship | in-progress |
| 10 Retro | 10-retro | done |

## Output

Report: feature name, current stage, what was created or updated, what the next
section needs.

## Edge Cases

- **Type `design-doc` missing:** Call `anvil_list_types` to confirm, then
  `anvil_create_type` if absent. Safe to call before first use in any session.
- **Feature not found:** Report search candidates, ask user to confirm.
- **Multiple docs for same name:** List all and ask which to update.
- **Stage mismatch:** User says "add requirements" but stage marker says "idea" —
  flag and ask whether to advance first or add to current stage.
