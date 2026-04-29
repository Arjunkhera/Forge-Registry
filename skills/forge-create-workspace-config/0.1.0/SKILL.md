---
name: forge-create-workspace-config
description: >
  Internal expert skill for forge-create. Creates Forge workspace-config artifacts
  with WORKSPACE.md defining environment templates — MCP servers, skill/plugin
  references, inheritance via extends, and permission rules. Not invoked directly by
  users — called by forge-create orchestrator.
---

# Forge Create — Workspace-Config Creator Expert

You create Forge workspace-config artifacts. Workspace-configs define environment
templates that wire together MCP servers, skills, plugins, and agents into a working
development environment.

## Input

Artifact spec from the decomposition plan:
- `id`: kebab-case workspace-config name
- `purpose`: what environment this configures
- `stories`: user stories it covers
- `details`: which artifacts to wire together
- `dependencies`: skills, plugins, agents to include

## When to Create a Workspace-Config

| Signal | Workspace-Config Needed? |
|--------|-------------------------|
| Multiple artifacts need to work together | Yes |
| Specific MCP servers required | Yes |
| Team needs a shared environment template | Yes |
| Single artifact, no environment setup | No |

## Workspace-Config Anatomy

```
{id}/
├── {version}/
│   ├── WORKSPACE.md      (optional — workspace-level instructions)
│   └── metadata.yaml     (required — registry metadata)
```

## Creation Process

### Step 1: Determine Environment Requirements

From the artifact spec and plan:
- Which MCP servers are needed (anvil, vault, forge, custom)
- Which skills to install
- Which plugins to install
- Which agents to include
- Whether to extend an existing workspace-config

### Step 2: Write WORKSPACE.md (Optional)

Only create if the workspace needs instructions beyond the metadata. This might include:
- Environment setup notes
- How the artifacts work together
- Recommended workflow

```yaml
---
name: {id}
description: >
  {What this workspace provides. What kind of work it's designed for.}
---
```

**Body structure:**

```markdown
# {Workspace Name}

{What this workspace is for.}

## Environment

- **MCP Servers:** {list}
- **Key Skills:** {list with purpose}
- **Agents:** {list with purpose}

## Workflow

{How to use this workspace. What the typical workflow looks like.}

## Notes

{Any setup requirements, gotchas, or tips.}
```

### Step 3: Write metadata.yaml

```yaml
id: {id}
name: {Human-Readable Name}
version: 0.1.0
description: >
  {What environment this configures — 1-2 sentences}
type: workspace-config
author: Arjun Khera
license: MIT
tags:
  - {relevant tags}
extends: workspace-config:sdlc-default@2.0.0  # optional — inherit from parent
mcpServers:
  - anvil
  - vault
  - forge
skills:
  - skill:{skill-1}@0.1.0
  - skill:{skill-2}@0.1.0
plugins: []
agents:
  - agent:{agent-1}@0.1.0
dependencies:
  skill:{skill-1}: ">=0.1.0"
  agent:{agent-1}: ">=0.1.0"
files: []
```

### Step 4: Validate

- [ ] All referenced skills/agents/plugins exist or are being created in the same plan
- [ ] MCP servers are valid (anvil, vault, forge, or custom with URL)
- [ ] If extends is set, the parent config exists
- [ ] Workspace-config name is kebab-case
- [ ] No circular extends chains

## Inheritance

Workspace-configs support `extends` to inherit from a parent:
- Parent provides defaults
- Child overrides and extends
- Array fields (skills, plugins, mcpServers) are merged
- Scalar fields (name, description) are replaced

**Common parent:** `workspace-config:sdlc-default` — provides Anvil, Vault, Forge
MCP servers and base SDLC skills.

## Output

Present the complete workspace-config:
1. Show WORKSPACE.md (if created)
2. Show metadata.yaml with full dependency list
3. Note inheritance chain if extends is used
4. Note the target path: `workspace-configs/{id}/0.1.0/`
