# Forge-Registry

This is the **source repository** for all Forge artifacts: skills, agents, plugins, personas, and workspace-configs.

## Authoring Workflow

> **IMPORTANT:** The installed registry at `~/Horus/data/registry/` is generated. Never edit files there — they are overwritten on every `forge_install`.

To add or modify artifacts:

1. Make changes in this repo (in `skills/`, `plugins/`, `agents/`, `workspace-configs/`, or `personas/`)
2. Commit and push to a feature branch
3. Open a PR against `master` and get it merged
4. After merge, run `forge_install` in each workspace to pick up the changes

## Structure

The registry uses a **directory-per-version** layout:

```
{type}/{id}/{version}/
    metadata.yaml      # Artifact metadata (id, name, version, etc.)
    manifest.yaml      # Auto-generated file list with SHA256 checksums
    SKILL.md|AGENT.md|PLUGIN.md|PERSONA.md|WORKSPACE.md  # Main definition
    scripts/           # Optional scripts directory
    mcp-servers/       # Optional MCP server configs (plugins)
    resources/         # Optional resources (plugins)
```

### Artifact type directories

```
skills/               # Skill definitions (SKILL.md per skill)
agents/               # Agent definitions (AGENT.md per agent)
plugins/              # Plugin bundles (skills + MCP servers + resources)
workspace-configs/    # Workspace templates
personas/             # Persona definitions
```

### Example paths

```
skills/sdlc-designer/1.1.0/SKILL.md
plugins/horus-core/1.0.0/mcp-servers/anvil.json
personas/skeptic/1.0.0/PERSONA.md
workspace-configs/sdlc-default/1.2.0/metadata.yaml
```

### manifest.yaml

Each version directory contains an auto-generated `manifest.yaml` listing all files with SHA256 checksums and a generation timestamp. This enables integrity verification during `forge_install`.

### Reserved entries

- `_template/` directories are skipped during migration/processing
- `README.md` files at the type level are preserved as-is
