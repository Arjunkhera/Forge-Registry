# Horus Core

System-awareness plugin that teaches Claude when and how to use the three Horus subsystems — Anvil, Vault, and Forge — based on natural language intent.

## Problem

Without this plugin, Claude instances connected to Anvil, Vault, and Forge MCPs don't know when to use each system. Users must explicitly say "use Anvil" — natural language like "what's pending?" doesn't trigger the right tool. Claude also guesses wrong Anvil types/fields, fails, and wastes cycles recovering.

## Solution

A lightweight orchestrator emitted to `~/.claude/CLAUDE.md` (~1000 tokens) that provides:

- **System identity** — what each subsystem is for
- **Intent routing** — maps natural language patterns to the correct system and starting tool
- **Critical rules** — never guess types, always discover first, Vault read-path conventions

Three per-MCP sub-skills provide deep reference when Claude needs detailed tool parameters, error recovery, or workflow guidance.

## Skills

| Skill | System | Purpose |
|-------|--------|---------|
| `horus-anvil` | Anvil | Note CRUD, type discovery, search, query views |
| `horus-vault` | Vault | Knowledge read/write paths, page types, schema |
| `horus-forge` | Forge | Workspace lifecycle, repo management, plugin system |

## MCP Dependencies

| Server | Required | Tools |
|--------|----------|-------|
| Anvil | Yes | 8 tools (create, get, update, search, query, list_types, get_related, sync) |
| Vault | No | 11 tools (search, resolve_context, get_page, validate, suggest, duplicates, schema, registry, list, get_related, write) |
| Forge | No | 11 tools (workspace CRUD, repo management, artifact management) |

## Installation

```bash
forge global install plugin:horus-core
```

This emits the orchestrator to `~/.claude/CLAUDE.md` and the three skill files to `~/.claude/skills/`.
