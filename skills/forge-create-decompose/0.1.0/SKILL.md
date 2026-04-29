---
name: forge-create-decompose
description: >
  Internal expert skill for forge-create. Maps structured user stories to Forge artifact
  recommendations. Searches the registry for existing artifacts, explains why each
  artifact type was chosen, and produces an artifact plan. Not invoked directly by
  users — called by forge-create orchestrator.
---

# Forge Create — Decomposition Expert

You take structured user stories (from the intake expert) and determine which Forge
artifacts should be created to fulfill them. You search the registry first, explain
your reasoning, and produce a concrete artifact plan.

## Input

Structured user stories from the intake expert (markdown format with Story titles,
actors, actions, outcomes, and details).

## Forge Artifact Types

Use these definitions to map user stories to the right artifact types:

| Type | Content File | When to Use |
|------|-------------|-------------|
| **skill** | `SKILL.md` | Reusable capability. Domain expertise, workflows, tool integrations. The default choice for most functionality. |
| **plugin** | `PLUGIN.md` | Bundle of related skills + agents that form a cohesive package. Use when multiple skills work together as a unit. |
| **agent** | `AGENT.md` | Orchestrator with a root skill + dependencies. Use when multi-step workflows need autonomous coordination. |
| **persona** | `PERSONA.md` | Character profile (name, tone, expertise, behavior). Use when distinct personality or role-specific behavior is needed. |
| **workspace-config** | `WORKSPACE.md` | Environment template (MCP servers, skills, inheritance). Use when artifacts need to be wired together as a working environment. |

### Decision Heuristics

| Signal in User Stories | Recommended Artifact |
|----------------------|---------------------|
| Single capability, reusable | **skill** |
| External API integration | **skill** (with API details in references/) |
| Multiple related capabilities that ship together | **plugin** (bundles skills) |
| Multi-step orchestrated workflow | **agent** + supporting **skills** |
| "Run on schedule" / autonomous behavior | **agent** |
| Distinct personality or role | **persona** |
| Need to wire multiple artifacts together | **workspace-config** |
| Complex domain requiring structured references | **skill** with references/ directory |

## Process

### Step 1: Search Registry for Existing Artifacts

Before recommending anything new, search the Forge registry:

```
forge_search(query: "<relevant terms from user stories>")
```

For each result, assess:
- **Exact match:** Recommend using the existing artifact (no need to build)
- **Partial match:** Recommend extending or forking the existing artifact
- **No match:** Recommend building new

### Step 2: Map Stories to Artifacts

For each user story, determine which artifact(s) are needed. A single story may require
multiple artifacts. Multiple stories may be served by a single artifact.

**Mapping rules:**
- Every distinct capability becomes a **skill** (default)
- If stories describe a multi-step flow, add an **agent** to orchestrate
- If stories mention specific personality/tone needs, add a **persona**
- If 3+ skills work as a unit, consider wrapping in a **plugin**
- If the result needs environment wiring, add a **workspace-config**

### Step 3: Produce Artifact Plan

Output a structured plan:

```
## Artifact Plan

### 1. skill:email-reader
**Purpose:** Read and parse emails via IMAP/Gmail API
**Covers stories:** Story 1
**Registry match:** None found
**Rationale:** This is a distinct, reusable capability — best served as a standalone skill.
**Dependencies:** None
**Estimated complexity:** Medium

### 2. skill:action-extractor
**Purpose:** Extract action items from text using LLM analysis
**Covers stories:** Story 2
**Registry match:** skill:text-analyzer@1.0.0 (partial — handles text but not action extraction)
**Rationale:** Similar to text-analyzer but specialized for action items. Could extend, but the scope is different enough to warrant a new skill.
**Dependencies:** None
**Estimated complexity:** Small

### 3. agent:email-task-processor
**Purpose:** Orchestrate the end-to-end flow: read emails → extract actions → create tasks
**Covers stories:** Story 3, overall orchestration
**Registry match:** None found
**Rationale:** The user wants an automated pipeline. An agent coordinates the skills and handles the Anvil integration.
**Dependencies:** skill:email-reader, skill:action-extractor
**Estimated complexity:** Medium

## Summary
| # | Type | ID | Purpose | New/Extend |
|---|------|----|---------|------------|
| 1 | skill | email-reader | Read and parse emails | New |
| 2 | skill | action-extractor | Extract action items from text | New |
| 3 | agent | email-task-processor | Orchestrate email → task flow | New |
```

## Output Format — Artifact Spec

Each artifact in the plan must include these fields (this is the contract consumed by
creator experts):

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | skill, plugin, agent, persona, workspace-config |
| `id` | string | kebab-case identifier |
| `purpose` | string | One-line description of what it does |
| `stories` | list | Which user stories it covers |
| `registry_match` | string/null | Existing artifact ref if found, null if new |
| `rationale` | string | Why this artifact type was chosen |
| `dependencies` | list | Other artifacts in this plan it depends on |
| `complexity` | string | Small, Medium, Large |
| `details` | string | Key implementation details from user stories |

## Guidelines

- **Prefer fewer artifacts.** Don't over-decompose. If one skill can cover two stories, do that.
- **Always explain why.** The user should understand why you chose skill vs agent vs plugin.
- **Surface registry matches prominently.** Avoiding duplicate work is high value.
- **Respect dependency order.** Skills before agents that use them. Workspace-configs last.
- **Flag uncertainty.** If a mapping is ambiguous, say so and offer alternatives.
