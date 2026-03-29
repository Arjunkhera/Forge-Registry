# Forge-Registry

This is the **source repository** for all Forge artifacts: skills, agents, plugins, and workspace-configs.

## Authoring Workflow

> **IMPORTANT:** The installed registry at `~/Horus/data/registry/` is generated. Never edit files there — they are overwritten on every `forge_install`.

To add or modify artifacts:

1. Make changes in this repo (in `skills/`, `plugins/`, `agents/`, or `workspace-configs/`)
2. Commit and push to a feature branch
3. Open a PR against `master` and get it merged
4. After merge, run `forge_install` in each workspace to pick up the changes

## Structure

```
skills/           # Skill definitions (SKILL.md per skill)
agents/           # Agent definitions (AGENT.md per agent)
plugins/          # Plugin bundles (skills + resources)
workspace-configs/ # Workspace templates
personas/         # Persona definitions
```
