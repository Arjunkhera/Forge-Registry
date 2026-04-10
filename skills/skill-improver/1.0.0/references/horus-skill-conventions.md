# Horus Skill Conventions

Reference for skill authors and the skill-improver. Covers structure, formatting, versioning, and the publish workflow.

---

## Registry Structure

Each skill lives under `skills/<skill-id>/` in the Forge Registry repo. Skills are versioned — each release is a subdirectory:

```
skills/
  <skill-id>/
    <version>/
      metadata.yaml     # required
      SKILL.md          # required
      references/       # optional — detailed conventions, examples
      scripts/          # optional — bundled shell scripts
      manifest.yaml     # optional — explicit file list
```

There is no top-level `SKILL.md` or `metadata.yaml` outside a version directory. The registry resolves the latest version by semver sort.

---

## metadata.yaml Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | string | yes | Matches directory name, kebab-case |
| `name` | string | yes | Human-readable, title case |
| `version` | string | yes | Semver: `x.y.z` |
| `description` | string | yes | One or two sentences, third-person |
| `type` | string | yes | Always `skill` |
| `author` | string | yes | Full name |
| `license` | string | yes | Usually `MIT` |
| `tags` | list | yes | At least `horus` + topic tags |
| `dependencies` | map | yes | Empty `{}` if none |
| `files` | list | yes | Empty `[]` if not using manifest |

---

## SKILL.md Structure

### Frontmatter

Every SKILL.md must begin with YAML frontmatter:

```yaml
---
name: <skill-id>
description: >
  Third-person description of what the skill does and when to use it.
  Include trigger phrases the user might say that should invoke this skill.
---
```

The description is used by the skill router. Be specific about trigger phrases.

### Body Sections (in order)

1. **H1 title** — skill display name
2. **One-line role statement** — "You are the X. Your job is to Y."
3. **MCP Tools Used** — table (see below)
4. **Mode Detection** — table mapping signals to modes (if multi-mode)
5. **Mode sections** — one H2 per mode, with numbered steps
6. **Conventions Reference** — pointer to `references/` if applicable

### MCP Tool Table Format

```markdown
## MCP Tools Used

| Tool | Purpose |
|------|---------|
| `tool_name` | One-line purpose description |
```

- List only tools actually called by this skill
- Use backtick-quoted tool names
- Keep purpose descriptions to one line
- Order: read tools first, write tools last

---

## Writing Style

- **Imperative/infinitive throughout** — "Read the note", "Generate the diff", "Ask the user"
- **No passive voice** — "The note is read" is wrong; "Read the note" is right
- **Short sentences** — one action per line in step lists
- **No hedging** — "Always", "Never", "Do not" — not "You might want to"
- **Code blocks for tool calls** — show exact call shape with placeholder values
- **Tables for decisions** — use Markdown tables for mode detection and tool lists

Target length: **1200–1500 tokens** for SKILL.md. Use `references/` for anything longer.

---

## Progressive Disclosure

Keep SKILL.md lean. Detailed conventions, examples, and edge cases belong in `references/`.

| Belongs in SKILL.md | Belongs in references/ |
|---------------------|------------------------|
| Steps the agent must follow | Detailed format examples |
| Mode detection table | Edge case catalog |
| MCP tool list | Background rationale |
| Version/publish instructions | Extended tool parameter details |
| Pointer to references/ | Naming convention details |

In SKILL.md, end with a "Conventions Reference" section pointing to the relevant file in `references/`.

---

## Naming Conventions

| Thing | Convention | Example |
|-------|-----------|---------|
| Skill ID | kebab-case | `skill-improver`, `sdlc-developer` |
| Skill directory | matches skill ID | `skills/skill-improver/` |
| Version directory | semver | `1.0.0/`, `1.1.0/` |
| References files | kebab-case `.md` | `horus-skill-conventions.md` |
| Script files | kebab-case `.sh` | `commit.sh`, `create-pr.sh` |
| Tags | kebab-case | `horus`, `skill-iteration` |

Skill IDs must be globally unique within the registry. Use a domain prefix for ambiguity (`sdlc-`, `doc-gen-`, `horus-`).

---

## Version Bump Policy

| Change Type | Bump | Example |
|-------------|------|---------|
| Wording, clarity, typos | patch (`x.y.Z+1`) | `1.0.0` → `1.0.1` |
| New examples, added context | patch | `1.0.1` → `1.0.2` |
| New section or step | minor (`x.Y+1.0`) | `1.0.2` → `1.1.0` |
| Changed mode logic or behavior | minor | `1.1.0` → `1.2.0` |
| Breaking change, full rewrite | major (`X+1.0.0`) | `1.2.0` → `2.0.0` |

When in doubt: editorial = patch, behavioral = minor.

---

## Forge Publish Workflow

Publishing a skill version creates a new versioned directory in the registry and updates the registry index.

```
forge_publish({ id: "<skill-id>", version: "<new-version>" })
```

Requirements before publishing:
1. `metadata.yaml` is present and valid
2. `SKILL.md` is present
3. Version in `metadata.yaml` matches the `version` argument
4. The version directory does not already exist in the registry

After publishing, the new version becomes the latest. Previous versions remain in the registry for rollback.

The skill-improver never calls `forge_publish` — always the human.

---

## Friction Tag Convention

Friction notes in Anvil use two tags:
- `friction` — global friction tag (enables cross-skill queries)
- `friction:<skill-id>` — skill-specific tag (enables per-skill queries)

Example: a friction note for `sdlc-developer` gets tags `["friction", "friction:sdlc-developer"]`.

Query all friction for a skill:
```
anvil_search({ type: "note", tags: ["friction:sdlc-developer"] })
```

Query all friction across all skills:
```
anvil_search({ type: "note", tags: ["friction"] })
```
