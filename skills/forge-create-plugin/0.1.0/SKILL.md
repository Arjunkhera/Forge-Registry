---
name: forge-create-plugin
description: >
  Internal expert skill for forge-create. Creates Forge plugin artifacts that bundle
  related skills and agents into cohesive packages with PLUGIN.md. Handles dependency
  wiring between bundled components. Not invoked directly by users — called by
  forge-create orchestrator.
---

# Forge Create — Plugin Creator Expert

You create Forge plugin artifacts. Plugins bundle related skills and agents into a
cohesive package that ships and installs as a unit.

## Input

Artifact spec from the decomposition plan:
- `id`: kebab-case plugin name
- `purpose`: what the plugin provides
- `stories`: user stories it covers
- `details`: key implementation details
- `dependencies`: skills and agents it bundles

## When to Create a Plugin vs Individual Skills

| Scenario | Create |
|----------|--------|
| 3+ skills that always work together | **Plugin** |
| Skills with shared configuration | **Plugin** |
| Skills that make no sense individually | **Plugin** |
| Independent reusable capability | **Skill** (not a plugin) |

## Plugin Anatomy

```
{id}/
├── {version}/
│   ├── PLUGIN.md         (optional — plugin-level instructions)
│   ├── metadata.yaml     (required — lists bundled artifacts)
│   └── skills/           (bundled skill folders)
│       ├── sub-skill-a/
│       │   └── SKILL.md
│       └── sub-skill-b/
│           └── SKILL.md
```

## Creation Process

### Step 1: Identify Bundled Components

From the artifact spec and plan, determine:
- Which skills are bundled in this plugin
- Which agents are bundled (if any)
- Dependency order between components

### Step 2: Write PLUGIN.md (Optional)

Only create PLUGIN.md if the plugin needs coordination instructions beyond what
individual skills provide. This might include:
- How the bundled skills work together
- Shared configuration or state
- Plugin-level workflow

```yaml
---
name: {id}
description: >
  {What the plugin provides as a bundle. When to install it.}
---
```

### Step 3: Create Bundled Skills

For each bundled skill, create a SKILL.md following the same patterns as the
skill creator expert. Each skill should still work independently where possible.

### Step 4: Write metadata.yaml

```yaml
id: {id}
name: {Human-Readable Name}
version: 0.1.0
description: >
  {What the plugin bundles and why}
type: plugin
author: Arjun Khera
license: MIT
tags:
  - {relevant tags}
dependencies:
  skill:sub-skill-a: "0.1.0"
  skill:sub-skill-b: "0.1.0"
files: []
```

### Step 5: Validate

- [ ] Each bundled skill has valid SKILL.md with frontmatter
- [ ] metadata.yaml lists all dependencies correctly
- [ ] No circular dependencies between bundled components
- [ ] Plugin name is kebab-case
- [ ] Total bundle is coherent — skills belong together

## Output

Present the complete plugin:
1. Show PLUGIN.md (if created)
2. Show metadata.yaml with dependency list
3. List each bundled skill with its SKILL.md
4. Note the target path: `plugins/{id}/0.1.0/`
