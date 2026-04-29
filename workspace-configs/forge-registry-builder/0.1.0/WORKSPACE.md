---
name: forge-registry-builder
description: >
  Workspace for building and publishing Forge artifacts. Provides guided artifact
  creation through the forge-create skill suite. Use when you want to create new
  skills, plugins, agents, personas, or workspace-configs for the Forge registry.
---

# Forge Registry Builder

Workspace for creating and publishing Forge artifacts.

## Getting Started

Say what you want to build:

```
"I want to create a skill that formats markdown tables"
"I need a plugin that bundles my email tools"
"Help me build an agent that automates code review"
```

The `forge-create` skill guides you through the full process:
1. **Intake** — clarifies what you want to build
2. **Decomposition** — recommends which artifacts to create and why
3. **Creation** — builds each artifact with best practices
4. **Review** — presents artifacts for your approval

## Installed Skills

| Skill | Role |
|-------|------|
| `forge-create` | Main entry point — orchestrates the full flow |
| `forge-create-intake` | Helps clarify intent into user stories |
| `forge-create-decompose` | Maps stories to artifact recommendations |
| `forge-create-skill` | Creates skill artifacts |
| `forge-create-plugin` | Creates plugin artifacts |
| `forge-create-agent` | Creates agent artifacts |
| `forge-create-persona` | Creates persona artifacts |
| `forge-create-workspace-config` | Creates workspace-config artifacts |

## Skip Path

If you already know what you want, go direct:

```
"Create a skill called my-formatter"
"Make a persona called senior-backend-engineer"
```

The orchestrator detects specific requests and skips straight to the creator.
