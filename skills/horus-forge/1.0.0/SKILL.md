---
name: horus-forge
description: >
  Forge MCP reference. Use when you need to manage workspaces (context containers),
  create code sessions (forge_develop), discover repos, resolve git workflows,
  or install plugins and skills. Covers workspaces, sessions, repo index, and
  the artifact system.
---

# Horus Forge — MCP Tool Reference

Forge is the execution and environment system. It manages context-only workspaces, isolated code sessions (git worktrees), a local repository index, and a versioned artifact system for skills, plugins, and agents.

## Tools

| Tool | Purpose | Key Parameters |
|------|---------|---------------|
| `forge_workspace_create` | Create a context-only workspace | `config` (required), `repos`, `storyId`, `storyTitle`, `configVersion` |
| `forge_workspace_list` | List tracked workspaces | `status` (active/paused/completed/archived), `storyId` |
| `forge_workspace_status` | Get full details for a workspace | `id` (required) |
| `forge_workspace_delete` | Delete a workspace | `id` (required), `force` |
| `forge_develop` | Create or resume a code session (git worktree) | `repo` (required), `workItem` (required), `branch`, `workflow` |
| `forge_session_list` | List active code sessions | `repo`, `workItem` |
| `forge_session_cleanup` | Clean up stale sessions | `workItem`, `olderThan` (e.g., `"30d"`), `auto` |
| `forge_repo_list` | List repos from local index | `query` (filter), `language` (filter) |
| `forge_repo_resolve` | Find a specific repo by name or URL | `name` or `remoteUrl` |
| `forge_repo_workflow` | Get/save git workflow config for a repo | `name` (required), `workflow` (optional, to save) |
| `forge_search` | Search the registry for artifacts | `query` (required), `type` (skill/agent/plugin) |
| `forge_add` | Add artifact refs to forge.yaml | `refs` (array of ref strings, e.g., `["skill:developer@1.0.0"]`) |
| `forge_install` | Install all artifacts from forge.yaml | `dryRun` (preview), `target` (claude-code/cursor/plugin) |
| `forge_resolve` | Inspect a single artifact with deps | `ref` (e.g., `"plugin:anvil-sdlc-v2"`) |
| `forge_list` | List installed or available artifacts | `scope` (installed/available), type filter |

## Workspaces — Context Containers

Workspaces are **context-only folders** that configure an AI agent's environment. They do NOT clone repositories or create git worktrees. Use `forge_develop` for isolated code sessions.

A workspace provides:
- MCP server connections (Anvil, Vault, Forge endpoints)
- Installed skills and plugins
- CLAUDE.md / .cursorrules context files
- workspace.env with SDLC git workflow variables
- Claude permissions (allow/deny rules)
- PreToolUse guard hook (prevents edits to files outside workspace)

### Creating a workspace

```
forge_workspace_create(config: "sdlc-default")
forge_workspace_create(config: "sdlc-default", repos: ["my-repo"])
forge_workspace_create(config: "sdlc-default", storyId: "abc123", storyTitle: "Add auth")
```

This will:
1. Resolve the workspace-config artifact from the registry
2. Create a folder at `~/Horus/data/workspaces/{name}/`
3. Install plugins and skills (for both Claude Code and Cursor targets)
4. Configure MCP server connections in `.claude/settings.local.json` and `.cursor/mcp.json`
5. Emit guard hook to block edits outside workspace directories
6. Write context files (CLAUDE.md, .cursorrules, workspace.env)
7. Register workspace in the metadata store

**storyId is optional** — it's metadata, not a requirement. Without it, the workspace name uses the generated ID.

### Workspace folder structure

```
sdlc-default-ws-abc12345/
├── forge.yaml                  # Artifact declarations
├── forge.lock                  # Installed versions + file hashes
├── CLAUDE.md                   # Agent context
├── .cursorrules                # Cursor equivalent
├── workspace.env               # SDLC env vars
├── .claude/
│   ├── settings.json           # Project-level permissions
│   ├── settings.local.json     # MCP server URLs
│   ├── mcp-servers/
│   ├── scripts/guard-source-repos.sh
│   └── commands/               # Installed skill files
└── .cursor/
    ├── mcp.json
    └── rules/                  # Installed skill files (.mdc)
```

### Lifecycle states

```
active → paused → active (resume)
active → completed → archived (terminal)
any → deleted (removes folder from disk)
```

Retention cleanup: removes active/paused workspaces older than N days (default 30).

### Listing workspaces

```
forge_workspace_list(status: "active")       // Active only
forge_workspace_list()                        // All non-archived
forge_workspace_list(storyId: "abc123")       // By linked story
```

### Getting workspace details

```
forge_workspace_status(id: "ws-abc12345")
```
Returns: name, config, status, path, repos (with local paths), story link, timestamps.

### Deleting a workspace

```
forge_workspace_delete(id: "ws-abc12345", force: true)
```
Removes workspace folder from disk. Does NOT touch code sessions (those are managed separately).

## Code Sessions — forge_develop

Sessions create **git worktrees** for isolated coding. Each session is linked to a repository and a work item (Anvil note).

### Creating/resuming a session

```
forge_develop(repo: "my-repo", workItem: "task-abc")
```

This will:
1. Resolve the repo via 3-tier lookup:
   - Tier 1: User repos (from configured scan paths)
   - Tier 2: Managed pool (`~/Horus/data/repos/`)
   - Tier 3: NOT YET SUPPORTED (would clone from remote)
2. Check for existing session → **resume** if found (updates lastModified)
3. Verify workflow is confirmed (or accept inline `workflow` parameter)
4. `git fetch` on the base repo
5. `git worktree add {sessionPath} -b {branch} {baseBranch}`
6. Install enforcement hooks
7. Save session record

Returns: `{ sessionId, sessionPath, hostSessionPath, branch, baseBranch, workflow, resumed }`

### Multiple agents on same work item

Same workItem can have multiple concurrent sessions (agent slots):
- Slot 1 path: `{slug}-{repo}`
- Slot 2+ path: `{slug}-{repo}-2`, `{slug}-{repo}-3`, etc.

Max sessions ceiling: configurable (default 20). Warns when reached, suggests cleanup.

### Listing sessions

```
forge_session_list()                          // All sessions
forge_session_list(repo: "my-repo")           // By repo
forge_session_list(workItem: "task-abc")      // By work item
```

### Cleaning up sessions

```
forge_session_cleanup(workItem: "task-abc")   // Clean specific work item
forge_session_cleanup(olderThan: "30d")       // Clean old sessions
forge_session_cleanup(auto: true)             // Auto-cleanup by Anvil status
```

**Auto-cleanup checks Anvil note status:**

| Anvil Status | Age | Action |
|-------------|-----|--------|
| `done` | > 7 days | Clean up |
| `cancelled` | Any | Clean up immediately |
| `in_progress` / `in_review` | Any | Skip |
| Not found | Any | Warn, skip |

Cleanup removes the git worktree, prunes the base repo, removes the session directory, and deletes the record.

## Repository Management

Forge maintains a local index of git repositories for quick lookup.

### Discovering repos

```
forge_repo_list()                             // All indexed repos
forge_repo_list(query: "auth")                // Filter by name/path/URL
forge_repo_list(language: "typescript")        // Filter by language
```

### Resolving a specific repo

```
forge_repo_resolve(name: "anvil")             // By name
forge_repo_resolve(remoteUrl: "git@github.com:org/repo.git")  // By URL
```

Returns: name, local path, remote URL, default branch, language, framework.

### Getting/saving git workflow config

```
forge_repo_workflow(name: "my-repo")
```

Resolution order:
1. Repo index (if workflow previously confirmed)
2. Vault repo-profile page (extracts hosting + workflow fields)
3. Auto-detect from git remotes ("upstream" → fork, no upstream → owner)

Returns: `{ workflow: { type, pushTo, prTarget, branchPattern, commitFormat, ... } }`

To save/confirm a workflow:
```
forge_repo_workflow(name: "my-repo", workflow: { type: "owner", pushTo: "origin", ... })
```

**Workflow types:**

| Type | Description | Push To | PR Target |
|------|-------------|---------|-----------|
| `owner` | Direct push to main repo | `origin` | Same repo |
| `fork` | Push to fork, PR to upstream | `origin` (fork) | Upstream |
| `contributor` | External contributor | `origin` | Upstream |

## Artifact System

Forge manages skills, agents, plugins, and workspace-configs as versioned artifacts.

### Reference format

```
type:id@version
```
Examples: `skill:developer@1.0.0`, `plugin:anvil-sdlc-v2`, `agent:sdlc-implement-story@^1.0.0`

### Discovery workflow

```
1. forge_search(query)              // Find artifacts
2. forge_resolve(ref)               // Inspect metadata + dependencies
3. forge_add(refs)                  // Add to forge.yaml
4. forge_install()                  // Install to workspace
```

### Listing what's installed

```
forge_list(scope: "installed")                // From lock file
forge_list(scope: "available", type: "skill") // From registry
```

### Artifact types

| Type | Content File | Description |
|------|-------------|-------------|
| `skill` | `SKILL.md` | Opaque markdown emitted as agent instructions |
| `agent` | `AGENT.md` | Agent definition with root skill + dependencies |
| `plugin` | `PLUGIN.md` (optional) | Bundle of skills + agents |
| `workspace-config` | `WORKSPACE.md` (optional) | Workspace template with MCP servers, git config |

### Compilation targets

Skills and plugins are compiled differently per target:
- **claude-code**: emits to `.claude/` directory
- **cursor**: emits to `.cursor/rules/` as `.mdc` files

## Code Access Rules

When investigating or reading source code, always follow this hierarchy:

### 1. Vault First — Conceptual Understanding
Before reading raw source code, check Vault for existing knowledge:
- `knowledge_resolve_context(repo: "<name>")` — returns repo profile, architecture, conventions, related guides
- `knowledge_search(query: "<topic>")` — finds guides, procedures, learnings across the knowledge base

Vault pages are maintained, verified, and structured. Raw source code requires you to re-derive context that may already be documented.

### 2. Managed Clone Pool — Current Source Code
When you need to read actual source files:
- Call `forge_repo_resolve(name: "<repo>")` to find the repo in the managed clone pool
- Read files from the returned path (under `~/Horus/data/horus-repos/`)
- This pool is maintained by Forge and is the canonical source for agent reads

### 3. Code Sessions — Writing Code
When you need to write or modify code:
- Call `forge_develop(repo: "<name>", workItem: "<id>")` to create an isolated git worktree
- All edits go in the returned `sessionPath`
- Never write to the managed clone pool or source repos

### What Is Blocked

A `PreToolUse` hook blocks `Read`, `Glob`, and `Grep` operations on files in the host-mounted source repos path. If you see a "BLOCKED: Cannot read files from source repository" error, follow the guidance in the error message.

### Subagent Briefing

When spawning Explore or research subagents to investigate code:
- **Always** provide the managed clone pool path from `forge_repo_resolve`, not a source repo path
- **Never** let subagents discover paths on their own — they will find the host-mounted source repos and read stale code
- **Include** the repo path in your subagent prompt: "Search in /Users/.../horus-repos/Horus for..."

This is critical — the original incident that motivated these rules was caused by a subagent reading stale code from the host mount.

## When to Use Forge vs Direct Git

| Scenario | Use |
|----------|-----|
| Setting up context for AI-assisted work | Forge (`workspace_create`) |
| Starting isolated coding on a work item | Forge (`forge_develop`) |
| Cleaning up after work is done | Forge (`session_cleanup`, `workspace_delete`) |
| Finding which repos exist locally | Forge (`repo_list`, `repo_resolve`) |
| Understanding a repo's PR workflow | Forge (`repo_workflow`) |
| Installing skills or plugins | Forge (`add` + `install`) |
| Daily git operations (commit, push, PR) | Direct git / gh CLI |
| Browsing available tools | Forge (`search`, `list`) |

## Common Mistakes

| Mistake | Correct |
|---------|---------|
| Thinking workspaces clone repos | Workspaces are context-only. Use `forge_develop` for code sessions. |
| Deleting a workspace to clean up code | `workspace_delete` only removes the context folder. Use `session_cleanup` for git worktrees. |
| Assuming storyId is required for workspace creation | storyId is optional metadata |
| Creating a session without checking for existing ones | `forge_develop` automatically resumes existing sessions for the same workItem + repo |
| Editing registry artifacts at the installed path | **Never** edit files under `~/Horus/data/registry/`. Those are generated. Edit source in `Forge-Registry` repo and run `forge_install`. |

## Registry Authoring

> **Warning:** The installed registry at `~/Horus/data/registry/` is a generated artifact. Files there are overwritten on every `forge_install`. **Never edit them directly.**

To add or update skills, agents, plugins, or workspace-configs:

1. Find the `Forge-Registry` repo via `forge_repo_resolve(name: "Forge-Registry")`
2. Use `forge_develop` to create an isolated session: `forge_develop(repo: "Forge-Registry", workItem: "<your-task-id>")`
3. Make changes inside `sessionPath` (under `skills/`, `plugins/`, `agents/`, or `workspace-configs/`)
4. Commit and push, then open a PR against `master`
5. After the PR merges, run `forge_install` in your workspace to pick up the changes

The installed path (`~/Horus/data/registry/`) mirrors the registry after install — it is not the source of truth.
