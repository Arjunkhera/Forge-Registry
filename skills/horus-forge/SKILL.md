---
name: horus-forge
description: >
  Forge MCP reference. Use when you need to manage workspaces, discover repos,
  or install plugins and skills. Covers workspace lifecycle, repo index, and
  the artifact system.
---

# Horus Forge — MCP Tool Reference

Forge is the execution and environment system. It manages workspaces, tracks repositories, and installs plugins/skills.

## Tools

| Tool | Purpose | Key Parameters |
|------|---------|---------------|
| `forge_search` | Search the registry for artifacts | `query` (required), `type` (skill/agent/plugin) |
| `forge_add` | Add artifact refs to forge.yaml | `refs` (array of ref strings, e.g., `["skill:developer@1.0.0"]`) |
| `forge_install` | Install all artifacts from forge.yaml | `dryRun` (preview), `target` (claude-code/cursor/plugin) |
| `forge_resolve` | Inspect a single artifact with deps | `ref` (e.g., `"plugin:anvil-sdlc-v2"`) |
| `forge_list` | List installed or available artifacts | `scope` (installed/available), type filter |
| `forge_repo_list` | List repos from local index | `query` (filter), `language` (filter) |
| `forge_repo_resolve` | Find a specific repo by name or URL | `name` or `remoteUrl` |
| `forge_repo_workflow` | Get git workflow config for a repo | `name` (required) — returns strategy, default branch, PR target |
| `forge_workspace_create` | Create a new workspace from config | `config` (required), `repos`, `storyId`, `storyTitle` |
| `forge_workspace_list` | List tracked workspaces | `status` (active/paused/completed/archived), `storyId` |
| `forge_workspace_delete` | Delete a workspace | `id` (required), `force` |
| `forge_workspace_status` | Get full details for a workspace | `id` (required) |

## Workspace Lifecycle

Workspaces are isolated development environments bootstrapped from workspace configs.

### Creating a workspace
```
forge_workspace_create(config: "sdlc-default", repos: ["my-repo"], storyId: "abc123")
```
This will:
1. Resolve the workspace config artifact
2. Install plugins and skills
3. Create git worktrees for specified repos
4. Set up MCP server connections
5. Register the workspace in the metadata store

### Lifecycle states
```
active → paused → active (resume)
active → completed → archived
any → deleted
```

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
Returns: name, config, status, path, repos (with worktree paths), story link, timestamps.

### Deleting a workspace
```
forge_workspace_delete(id: "ws-abc12345", force: true)
```
Removes git worktrees and workspace folder from disk.

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

### Getting git workflow config
```
forge_repo_workflow(name: "my-repo")
```
Returns: strategy (owner/fork/direct), default branch, PR target, hosting info.
Resolution order: Vault repo profile → auto-detect from git remotes → defaults.

## Artifact System

Forge manages skills, agents, and plugins as versioned artifacts.

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

## When to Use Forge vs Direct Git

| Scenario | Use |
|----------|-----|
| Starting work on a new story/feature | Forge (`workspace_create`) |
| Switching between work items | Forge (workspace lifecycle) |
| Finding which repos exist locally | Forge (`repo_list`, `repo_resolve`) |
| Understanding a repo's PR workflow | Forge (`repo_workflow`) |
| Daily git operations (commit, push, PR) | Direct git / gh CLI |
| Installing skills or plugins | Forge (`add` + `install`) |
| Browsing available tools | Forge (`search`, `list`) |
