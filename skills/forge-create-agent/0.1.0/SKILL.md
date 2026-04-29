---
name: forge-create-agent
description: >
  Internal expert skill for forge-create. Creates Forge agent artifacts with AGENT.md
  defining root skill, dependencies, and orchestration behavior. Not invoked directly
  by users — called by forge-create orchestrator.
---

# Forge Create — Agent Creator Expert

You create Forge agent artifacts. Agents are orchestrators that coordinate multi-step
workflows using a root skill and declared dependencies.

## Input

Artifact spec from the decomposition plan:
- `id`: kebab-case agent name
- `purpose`: what the agent orchestrates
- `stories`: user stories it covers
- `details`: key workflow details
- `dependencies`: skills and plugins it requires

## When to Create an Agent

| Signal | Agent Needed? |
|--------|--------------|
| Multi-step workflow requiring coordination | Yes |
| Autonomous/scheduled execution | Yes |
| Single capability, no orchestration | No — use a skill |
| Just bundling skills together | No — use a plugin |

## Agent Anatomy

```
{id}/
├── {version}/
│   ├── AGENT.md          (required — agent definition)
│   └── metadata.yaml     (required — registry metadata)
```

## Creation Process

### Step 1: Define the Agent's Role

An agent needs:
- **Root skill**: The primary skill that defines the agent's core behavior
- **Dependencies**: Other skills/plugins the agent coordinates
- **Orchestration logic**: How the agent sequences work across its dependencies

### Step 2: Write AGENT.md

```yaml
---
name: {id}
description: >
  {What this agent does. What workflows it orchestrates. When to use it.}
---
```

**Body structure:**

```markdown
# {Agent Name}

{One-line: what this agent orchestrates.}

## Role

{What this agent is responsible for. What decisions it makes autonomously
vs what it escalates to the user.}

## Dependencies

| Artifact | Purpose |
|----------|---------|
| skill:{dep-1} | {Why this agent needs it} |
| skill:{dep-2} | {Why this agent needs it} |

## Workflow

{Step-by-step description of how the agent orchestrates its dependencies.
Include decision points, error handling, and user interaction points.}

### Step 1: {Phase}
{What happens, which skill is invoked, what output is expected}

### Step 2: {Phase}
...

## Behavior

- {Autonomy level: what it does without asking}
- {Escalation: when it asks the user}
- {Error handling: what it does on failure}
```

### Step 3: Write metadata.yaml

```yaml
id: {id}
name: {Human-Readable Name}
version: 0.1.0
description: >
  {What the agent orchestrates — 1-2 sentences}
type: agent
author: Arjun Khera
license: MIT
tags:
  - {relevant tags}
dependencies:
  skill:{dep-1}: ">=0.1.0"
  skill:{dep-2}: ">=0.1.0"
files: []
```

### Step 4: Validate

- [ ] AGENT.md has valid frontmatter (name, description)
- [ ] All dependencies exist or are being created in the same plan
- [ ] Workflow is concrete — not hand-wavy
- [ ] Agent has clear autonomy boundaries
- [ ] Agent name is kebab-case

## Output

Present the complete agent:
1. Show AGENT.md content
2. Show metadata.yaml with dependencies
3. Note which dependencies are new vs existing
4. Note the target path: `agents/{id}/0.1.0/`
