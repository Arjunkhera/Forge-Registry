---
name: horus-forge
description: >
  Forge MCP reference. Use when you need to start a code session (forge_develop),
  manage workspaces, discover repos, resolve git workflows, publish artifacts,
  or install skills and plugins. Covers all 16 Forge tools, registry architecture,
  5 artifact types, workspace inheritance, and multi-agent sessions.
---

<!-- PATCH: intro -->
# Horus Forge — MCP Tool Reference

Forge is the execution and environment system. It manages context-only workspaces, isolated code sessions (git worktrees), a local repository index, a versioned artifact registry, and publishing pipelines for skills, plugins, agents, personas, and workspace-configs.

## Bundled Guides — Read Before Acting (Grounding)

The Horus CLI ships user-facing getting-started guides. Forge is the most conceptually loaded subsystem for new users — the workspace-vs-session distinction in particular trips people up. **Before creating workspaces or code sessions for a new user, read the relevant guide.** Bundled guides are authoritative for user-facing concepts; if they disagree with this reference, the guide wins and this file needs an update.

Relevant guides for Forge work:

- **`first-workspace`** — what a Forge workspace actually is (a context container, **not** a repo clone), when to create one, and how it differs from a code session.
- **`first-session`** — how `forge_develop` creates isolated git worktrees tied to a work item, including how to handle `status: created | resumed | needs_workflow_confirmation` responses.

To read them directly (works regardless of how Horus was installed):

```bash
horus guide first-workspace      # print the body
horus guide first-session        # print the body
horus guide first-workspace --path  # print the absolute path so you can Read it
horus help what is a workspace    # query-based retrieval if you don't know the slug
horus guide --path               # print the bundled guides directory root
```

<!-- PATCH: tools-table -->
## Tools

| Tool | Category | Purpose | Key Parameters |
|------|----------|---------|---------------|
| `forge_develop` | Code Sessions | Create or resume a code session (git worktree) | `repo` (required), `workItem` (required), `branch`, `workflow` |
| `forge_session_list` | Code Sessions | List active code sessions | `repo`, `workItem` |
| `forge_session_cleanup` | Code Sessions | Clean up stale sessions | `workItem`, `olderThan` (e.g., `"30d"`), `auto` |
| `forge_search` | Registry/Artifacts | Search the registry for artifacts | `query` (required), `type` (skill/agent/plugin/persona/workspace-config) |
| `forge_resolve` | Registry/Artifacts | Inspect a single artifact with deps | `ref` (e.g., `"plugin:anvil-sdlc-v2"`) |
| `forge_add` | Registry/Artifacts | Add artifact refs to forge.yaml | `refs` (array of ref strings, e.g., `["skill:developer@1.0.0"]`) |
| `forge_install` | Registry/Artifacts | Install all artifacts from forge.yaml | `dryRun` (preview), `target` (claude-code/cursor/plugin) |
| `forge_list` | Registry/Artifacts | List installed or available artifacts | `scope` (installed/available), type filter |
| `forge_publish` | Registry/Artifacts | Publish an artifact to a registry | `ref` (required), `registry` (target registry id) |
| `forge_repo_list` | Repos | List repos from local index | `query` (filter), `language` (filter) |
| `forge_repo_resolve` | Repos | Find a specific repo by name or URL | `name` or `remoteUrl` |
| `forge_repo_workflow` | Repos | Get/save git workflow config for a repo | `name` (required), `workflow` (optional, to save) |
| `forge_workspace_create` | Workspaces | Create a context-only workspace | `config` (required), `repos`, `storyId`, `storyTitle`, `configVersion` |
| `forge_workspace_list` | Workspaces | List tracked workspaces | `status` (active/paused/completed/archived), `storyId` |
| `forge_workspace_delete` | Workspaces | Delete a workspace | `id` (required), `force` |
| `forge_workspace_status` | Workspaces | Get full details for a workspace | `id` (required) |

<!-- PATCH: code-sessions -->
## Code Sessions — forge_develop

`forge_develop` is the primary way to start coding. It creates a **git worktree** for isolated work, linked to a repository and a work item.

### Creating or resuming a session

```
forge_develop(repo: "my-repo", workItem: "task-abc")
forge_develop(repo: "my-repo", workItem: "task-abc", branch: "feature/task-abc-my-fix")
```

This will:
1. Resolve the repo via 3-tier lookup (user repos → managed pool → error)
2. Check for existing session → **resume** if found (updates lastModified)
3. Verify workflow is confirmed (or accept inline `workflow` parameter)
4. `git fetch` on the base repo
5. `git worktree add {sessionPath} -b {branch} {baseBranch}`
6. Install enforcement hooks
7. Save session record

### Response statuses

| Status | Meaning | Next Step |
|--------|---------|-----------|
| `created` | New session created | Work in `sessionPath` |
| `resumed` | Existing session found | Work in `sessionPath` |
| `needs_workflow_confirmation` | No saved workflow for this repo | Call again with `workflow` parameter |
| `needs_remote_confirmation` | Multiple git remotes, no default set | Call again with `defaultRemote` parameter |
| `needs_repo_disambiguation` | Multiple repos share the same name | Call again with `localPath` set to chosen repo path |

### Multi-agent sessions

Multiple agents can work on the same work item concurrently via `agentSlot`:
- Slot 1 path: `{workItem}-{repo}`
- Slot 2+ path: `{workItem}-{repo}-2`, `{workItem}-{repo}-3`, etc.

Max concurrent sessions is configurable (default 20). When the ceiling is reached, `forge_develop` warns and suggests running `forge_session_cleanup`.

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

Auto-cleanup checks Anvil note status:

| Anvil Status | Age | Action |
|-------------|-----|--------|
| `done` | > 7 days | Clean up |
| `cancelled` | Any | Clean up immediately |
| `in_progress` / `in_review` | Any | Skip |
| Not found | Any | Warn, skip |

Cleanup removes the git worktree, prunes the base repo, removes the session directory, and deletes the record.

<!-- PATCH: registry-architecture -->
## Registry Architecture

Forge resolves artifacts from an ordered list of registries defined in `forge.yaml`. The first registry with a matching artifact wins.

### Registry types

| Type | Description | Writable |
|------|-------------|---------|
| `filesystem` | Local directory (e.g., `~/Horus/data/registry/`) | Yes |
| `git` | GitHub-hosted registry repo (e.g., `Arjunkhera/Forge-Registry`) | No (read-only) |
| `http` | Cloud registry endpoint | Depends on config |

### forge.yaml structure

```yaml
registries:
  - id: local
    type: filesystem
    path: ~/Horus/data/registry/
  - id: forge-registry
    type: git
    repo: Arjunkhera/Forge-Registry
    branch: master
  - id: cloud
    type: http
    url: https://registry.horus.dev

artifacts:
  - skill:developer@1.0.0
  - plugin:anvil-sdlc-v2
  - workspace-config:sdlc-default@^2.0.0
```

**Resolution order:** Forge searches each registry in declaration order. The first registry that contains a matching artifact version is used. This allows local overrides to shadow remote registries.

### Publishing artifacts

```
forge_publish(ref: "skill:horus-forge@2.0.0", registry: "local")
forge_publish(ref: "skill:horus-forge@2.0.0", registry: "forge-registry")
```

`forge_publish` validates the artifact, updates the registry index, and (for git registries) stages the changes for commit.

<!-- PATCH: artifact-system -->
## Artifact System

### Reference format

```
type:id@version
```

Examples: `skill:developer@1.0.0`, `plugin:anvil-sdlc-v2`, `agent:sdlc-implement-story@^1.0.0`, `persona:senior-engineer@1.0.0`, `workspace-config:sdlc-default@2.0.0`

### Artifact types

| Type | Content File | Description |
|------|-------------|-------------|
| `skill` | `SKILL.md` | Opaque markdown emitted as agent instructions |
| `agent` | `AGENT.md` | Agent definition with root skill + dependencies |
| `plugin` | `PLUGIN.md` (optional) | Bundle of skills + agents |
| `persona` | `PERSONA.md` | Character profile for Agent Team mode — sets name, tone, expertise, and behavior |
| `workspace-config` | `WORKSPACE.md` (optional) | Workspace template with MCP servers, git config, and optional `extends` field for inheritance |

### Discovery workflow

```
1. forge_search(query)              // Find artifacts
2. forge_resolve(ref)               // Inspect metadata + dependencies
3. forge_add(refs)                  // Add to forge.yaml
4. forge_install()                  // Install to workspace
```

### Listing installed or available

```
forge_list(scope: "installed")                // From lock file
forge_list(scope: "available", type: "skill") // From registry
```

### Compilation targets

Skills and plugins are compiled differently per target:
- **claude-code**: emits to `.claude/` directory
- **cursor**: emits to `.cursor/rules/` as `.mdc` files

<!-- PATCH: workspace-inheritance -->
## Workspace Inheritance

Workspace-config artifacts support an `extends` field to inherit settings from a parent config.

```yaml
# sdlc-default — base config
id: workspace-config:sdlc-default@2.0.0
mcpServers:
  - anvil
  - vault
  - forge
skills:
  - skill:horus-forge@2.0.0
```

```yaml
# sdlc-frontend — extends base
id: workspace-config:sdlc-frontend@1.0.0
extends: workspace-config:sdlc-default@2.0.0
skills:
  - skill:react-patterns@1.0.0
  - skill:css-conventions@1.0.0
```

**Merge semantics:** The parent config provides defaults. The child config overrides and extends. Array fields (skills, plugins, mcpServers) are merged; scalar fields (name, description) are replaced.

<!-- PATCH: workspaces -->
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

### Workspace lifecycle states

```
active → paused → active (resume)
active → completed → archived (terminal)
any → deleted (removes folder from disk)
```

### Listing and inspecting

```
forge_workspace_list(status: "active")
forge_workspace_list(storyId: "abc123")
forge_workspace_status(id: "ws-abc12345")
forge_workspace_delete(id: "ws-abc12345", force: true)
```

`forge_workspace_delete` removes the workspace context folder only. It does NOT touch code sessions.

<!-- PATCH: repo-management -->
## Repository Management

### Discovering repos

```
forge_repo_list()                             // All indexed repos
forge_repo_list(query: "auth")                // Filter by name/path/URL
forge_repo_list(language: "typescript")        // Filter by language
```

### Resolving a specific repo

```
forge_repo_resolve(name: "anvil")
forge_repo_resolve(remoteUrl: "git@github.com:org/repo.git")
```

Returns: name, local path, remote URL, default branch, language, framework.

### Git workflow config

```
forge_repo_workflow(name: "my-repo")
```

Resolution order: repo index (if previously confirmed) → Vault repo-profile page → auto-detect from git remotes.

| Workflow Type | Description | Push To | PR Target |
|---------------|-------------|---------|-----------|
| `owner` | Direct push to main repo | `origin` | Same repo |
| `fork` | Push to fork, PR to upstream | `origin` (fork) | Upstream |
| `contributor` | External contributor | `origin` | Upstream |

To save a workflow: `forge_repo_workflow(name: "my-repo", workflow: { type: "owner", ... })`

<!-- PATCH: code-access-rules -->
## Code Access Rules

When investigating or reading source code, follow this hierarchy:

1. **Vault first** — call `knowledge_resolve_context(repo: "<name>")` for architecture, conventions, guides. Vault pages are maintained and structured; avoid re-deriving context already documented.
2. **Managed clone pool** — call `forge_repo_resolve(name: "<repo>")` to get the path under `~/Horus/data/horus-repos/`. Read source files from there.
3. **Code sessions** — call `forge_develop(repo: "<name>", workItem: "<id>")` to get an isolated worktree. All edits go in `sessionPath`. Never write to the managed clone pool.

A `PreToolUse` hook blocks `Read`, `Glob`, and `Grep` on host-mounted source repo paths. If blocked, follow the guidance in the error message.

When spawning subagents: always provide the managed clone pool path explicitly. Never let subagents discover paths on their own — they will find the host-mounted source repos and read stale code.

<!-- PATCH: when-to-use -->
## When to Use Forge vs Direct Git

| Scenario | Use |
|----------|-----|
| Starting isolated coding on a work item | Forge (`forge_develop`) |
| Resuming work on an existing session | Forge (`forge_develop` — auto-resumes) |
| Multiple agents on same work item | Forge (`forge_develop` — assigns agentSlot) |
| Cleaning up after work is done | Forge (`session_cleanup`, `workspace_delete`) |
| Setting up context for AI-assisted work | Forge (`workspace_create`) |
| Finding which repos exist locally | Forge (`repo_list`, `repo_resolve`) |
| Understanding a repo's PR workflow | Forge (`repo_workflow`) |
| Installing skills or plugins | Forge (`add` + `install`) |
| Publishing a new artifact version | Forge (`forge_publish`) |
| Browsing available tools | Forge (`search`, `list`) |
| Daily git operations (commit, push, PR) | Direct git / gh CLI |

<!-- PATCH: registry-authoring -->
## Registry Authoring

The installed registry at `~/Horus/data/registry/` is a **generated artifact** overwritten on every `forge_install`. Never edit it directly.

To add or update skills, agents, plugins, personas, or workspace-configs:

1. `forge_repo_resolve(name: "Forge-Registry")` — find the source repo
2. `forge_develop(repo: "Forge-Registry", workItem: "<task-id>")` — create an isolated session
3. Make changes inside `sessionPath` (under `skills/`, `plugins/`, `agents/`, `personas/`, or `workspace-configs/`)
4. Commit and push, then open a PR against `master`
5. After the PR merges, run `forge_install` to pick up changes

<!-- PATCH: common-mistakes -->
## Common Mistakes

| Mistake | Correct |
|---------|---------|
| Thinking workspaces clone repos | Workspaces are context-only. Use `forge_develop` for code sessions. |
| Deleting workspace to clean up code | `workspace_delete` removes context folder only. Use `session_cleanup` for git worktrees. |
| Assuming storyId is required | storyId is optional metadata for workspace creation. |
| Creating a session without checking for existing ones | `forge_develop` automatically resumes existing sessions for same workItem + repo. |
| Editing registry artifacts at the installed path | Never edit `~/Horus/data/registry/`. Edit source in `Forge-Registry` repo and run `forge_install`. |
| Searching only the local registry | Forge searches all configured registries in order. Add remote registries to forge.yaml for broader discovery. |
