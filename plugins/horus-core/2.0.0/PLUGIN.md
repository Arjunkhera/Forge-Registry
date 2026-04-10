# Horus Core

Horus is a personal operating system built on three MCP subsystems: **Anvil** (structured state — notes, tasks, projects), **Vault** (knowledge graph — pages, relationships, schema), and **Forge** (execution — workspaces, repos, plugins). horus-context provides the interpretation layer that routes intent to the right system.

## Skills

| Skill | Purpose |
|-------|---------|
| `horus-context` | Interpretation layer — mental model + intent routing |
| `horus-anvil` | Anvil MCP — note CRUD, type discovery, search, query views |
| `horus-vault` | Vault MCP — knowledge read/write paths, page types, schema |
| `horus-forge` | Forge MCP — workspace lifecycle, repo management, plugin system |
| `capture` | Quick capture to Anvil inbox |
| `triage` | Inbox triage and routing |

## MCP Dependencies

| Server | Required | Tools |
|--------|----------|-------|
| Anvil | Yes | 28 tools |
| Vault | No | 14 tools |
| Forge | No | 16 tools |

## Installation

```bash
forge global install plugin:horus-core
```

Emits horus-context and all subsystem skills to `~/.claude/skills/` and `~/.cursor/skills/`.
