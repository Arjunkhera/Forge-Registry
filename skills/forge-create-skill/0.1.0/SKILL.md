---
name: forge-create-skill
description: >
  Internal expert skill for forge-create. Creates Forge skill artifacts with best
  practices baked in. Generates SKILL.md with proper frontmatter, body structure,
  and optional scripts/references/assets. Follows the Anthropic skill creator patterns.
  Not invoked directly by users — called by forge-create orchestrator.
---

# Forge Create — Skill Creator Expert

You create production-quality Forge skill artifacts. You follow proven patterns from
the Anthropic skill creator and Forge registry conventions.

## Input

Artifact spec from the decomposition plan:
- `id`: kebab-case skill name
- `purpose`: what the skill does
- `stories`: user stories it covers
- `details`: key implementation details
- `dependencies`: other artifacts it depends on

## Skill Anatomy

Every skill you create follows this structure:

```
{id}/
├── {version}/
│   ├── SKILL.md          (required — frontmatter + instructions)
│   ├── metadata.yaml     (required — registry metadata)
│   ├── references/       (optional — loaded on-demand)
│   ├── scripts/          (optional — executable code)
│   └── assets/           (optional — templates, files used in output)
```

## Creation Process

### Step 1: Plan the Skill Contents

Analyze the artifact spec and determine:

| Question | Decision |
|----------|----------|
| What procedural knowledge does the agent need? | → SKILL.md body |
| What reference material is needed on-demand? | → references/ |
| What code needs deterministic execution? | → scripts/ |
| What templates or files are used in output? | → assets/ |

**Default:** Most skills need only SKILL.md. Only add references/scripts/assets when
there's a clear reason.

### Step 2: Write the SKILL.md

#### Frontmatter (YAML)

```yaml
---
name: {id}
description: >
  {What the skill does — 1-2 sentences.}

  {When to use it — trigger phrases, contexts, user intents. Be specific.
  This is the primary mechanism for skill activation.}
---
```

**Rules:**
- `name` and `description` are the only frontmatter fields
- Description must include WHAT the skill does AND WHEN to use it
- Include trigger phrases the user might say
- Keep description under 200 words

#### Body (Markdown)

Structure the body with these principles:

1. **Concise is key.** The context window is shared. Only add what the agent doesn't
   already know. Challenge each paragraph: does this justify its token cost?

2. **Progressive disclosure.** Keep SKILL.md under 500 lines. Split detailed reference
   material into `references/` files. Link to them from SKILL.md with clear descriptions
   of when to read them.

3. **Degrees of freedom.** Match specificity to task fragility:
   - High freedom (text guidance) for tasks with many valid approaches
   - Medium freedom (pseudocode) for tasks with a preferred pattern
   - Low freedom (exact scripts) for fragile operations

4. **Structure:**
   ```markdown
   # {Skill Title}

   {One-line description of what this skill does.}

   ## Input
   {What the skill receives — format, fields, examples}

   ## Process
   {Step-by-step workflow — the core of the skill}

   ## Output
   {What the skill produces — format, examples}

   ## Guidelines
   {Guardrails, edge cases, things to watch for}
   ```

### Step 3: Write metadata.yaml

```yaml
id: {id}
name: {Human-Readable Name}
version: 0.1.0
description: >
  {Same as SKILL.md description but shorter — 1-2 sentences max}
type: skill
author: Arjun Khera
license: MIT
tags:
  - {relevant tags, 3-6}
dependencies: {}
files: []
```

### Step 4: Validate

Check before presenting to user:
- [ ] Frontmatter has only `name` and `description`
- [ ] Description includes what AND when (trigger phrases)
- [ ] Body is under 500 lines
- [ ] No extraneous files (README, CHANGELOG, etc.)
- [ ] `metadata.yaml` fields match SKILL.md
- [ ] Skill name is kebab-case
- [ ] No hardcoded paths or environment-specific values

## What NOT to Include

- README.md, INSTALLATION_GUIDE.md, CHANGELOG.md
- User-facing documentation (the skill IS the documentation)
- Setup procedures or testing instructions
- Comments about the creation process

## Examples of Good Skills

**Simple skill** (SKILL.md only):
- Formatting tools, code generators, analysis workflows
- Single-purpose, clear input/output

**Skill with references/**:
- Domain-heavy skills (finance schemas, API docs, company policies)
- Skills supporting multiple frameworks (reference per framework)

**Skill with scripts/**:
- PDF processing, file manipulation, deterministic transforms
- Operations that fail silently when done wrong

## Output

Present the complete skill to the user:
1. Show the SKILL.md content
2. Show metadata.yaml
3. List any references/scripts/assets created
4. Note the target path: `skills/{id}/0.1.0/`
