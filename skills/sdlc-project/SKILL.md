---
name: sdlc-project
description: >
  Create and manage software development projects. Use this skill when the user wants to start a
  new project, configure an existing project, check project status, link projects to programs, or
  archive a project. Also use when the user says "new project", "create project", "project status",
  "set up a project", or similar project-management phrases.

  A project is the primary organizational unit. It contains work items, documentation references,
  and configuration. Each project is an Anvil note of type `project`.

  Projects can optionally belong to a program (a group of related projects).
---

# Project Skill

You manage the lifecycle of development projects in the SDLC system. A project is the primary container for development work — it groups work items, references repos, and links to a program.

All project state lives in Anvil as typed notes (type: `project`). Repo-level information (tech stack, conventions, build commands) comes from Vault repo profiles. Local repo paths come from Forge's local repo index.

## MCP Tools Used

| Tool | Purpose |
|------|---------|
| `anvil_create_note` | Create project notes |
| `anvil_update_note` | Update project configuration |
| `anvil_get_note` | Read project details |
| `anvil_search` | Find projects, check for duplicates |
| `knowledge_resolve_context` | Load Vault repo profiles for project repos |
| `forge_repo_resolve` | Resolve local paths for repos |

## Conversation State

On entry, read the current `conversation-state` note for this workspace:
- Search: `anvil_search` type=conversation-state, workspace=current
- If `status=paused`: read `handoff_note`, brief user, confirm continuation
- If `status=active`: load `decided`, `open`, `last_skill`, `work_items` as context
- If not found: create new conversation-state (topic inferred, status=active)

On exit, update conversation-state before finishing:
- Append decisions made to `decided`
- Remove resolved questions from `open`
- Add new work item IDs to `work_items`
- Set `last_skill` to `sdlc-project`
- If user pauses: write `handoff_note`, set `status=paused`

## Operations

### `create` — Initialize a New Project (Flow 22)

1. **Gather details from user:**
   - Name (slug-friendly: lowercase, hyphens)
   - Description (1-2 sentences)
   - Repos (one or more — each with a role: "Product code", "Data store", etc.)
   - Program membership (optional — which program does this belong to?)

2. **Create project note in Anvil** via `anvil_create_note`:
   - Type: `project`
   - Title: project name
   - Fields: status=active, program reference if applicable
   - Body content:
     - Overview section
     - Goals section
     - Repository table (repos + roles)
     - Status summary (auto-populated from work item queries)
     - Links section

3. **Query Vault** for existing repo profiles via `knowledge_resolve_context` for each repo. If profiles exist, the project already has context.

4. **If Vault profiles don't exist:** Offer to bootstrap them via the docs skill (→ Flow 4: Codebase Exploration).

5. **Resolve local paths** for each repo via `forge_repo_resolve`. Note them in the project overview for reference.

6. **Link to program** if applicable → update program note via `anvil_update_note`.

7. **Confirm** creation with project ID, repos, and Vault status.

### `configure` — Update Project Settings

Update the project note in Anvil:
- Change description or goals
- Add/remove repos from the repository table
- Update program membership
- Mark as active/paused/archived

Always read the current note via `anvil_get_note` before updating to preserve existing content.

### `status` — Get Project Status

Generate a status report by querying Anvil:

1. Read project note via `anvil_get_note`
2. Query work items: `anvil_query_view` with `filter: { type: "work-item", project: "{id}" }`, `groupBy: "status"`
3. Check for blocked items specifically
4. Query recent journal entries: `anvil_search` with project tag, last 7 days
5. Present concise dashboard

### `link-program` — Add Project to a Program

1. Check if program exists via `anvil_search` with type `program`
2. If not, create it via `anvil_create_note` with type `program`
3. Update program note body to include this project
4. Update project note fields to reference the program

### `archive` — Archive a Project

1. Query all work items for the project
2. Verify all are either `done` or `cancelled`
3. If active items remain, warn the user and ask for confirmation
4. Update project status to `archived` via `anvil_update_note`
5. Log archival in project scratch via `anvil_create_note` (journal type)

## Project Note Body Template

The project note body should follow this structure:

```
## Overview

{description}

## Goals

- {goal_1}
- {goal_2}

## Repositories

| Repo | Role | Vault Profile | Local Path |
|------|------|---------------|------------|
| {repo} | {role} | ✅/❌ | {path or "unresolved"} |

## Status Summary

| Status | Count |
|--------|-------|
| Draft | 0 |
| Ready | 0 |
| In Progress | 0 |
| Done | 0 |

## Links

- Program: [[{program}]]
```

## Context Resolution

The project note only declares **which repos are involved and their roles.** Everything else is resolved at runtime:
- **Vault** → tech stack, conventions, build commands, architecture docs
- **Forge** → local repo paths on the developer's machine

This means the project note stays lightweight and portable. A different developer with the same Vault but different local paths can use the same project definition.
