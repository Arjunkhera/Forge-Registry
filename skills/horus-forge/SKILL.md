---
name: horus-forge
description: >
  Forge MCP reference. Use when you need to manage workspaces, start code sessions,
  discover repos, or install plugins and skills. Covers workspace lifecycle, code session
  lifecycle, repo index, and the artifact system.
---

# Horus Forge — MCP Tool Reference

Forge is the execution and environment system. It manages workspaces, tracks repositories, creates isolated code sessions (git worktrees), and installs plugins/skills.

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
| `forge_develop` | Create or resume a code session (git worktree) for a repo + work item | `repo` (required), `workItem` (required), `workflow` (optional, for confirmation) |
| `forge_session_list` | List active code sessions | `repo` (filter), `workItem` (filter), `status` (active/stale/all) |
| `forge_session_cleanup` | Clean up sessions by work item status or age | `auto` (boolean), `sessionId` (specific session), `olderThanDays` |
| `forge_workspace_create` | Create a new workspace from config | `config` (required), `storyId`, `storyTitle` |
| `forge_workspace_list` | List tracked workspaces | `status` (active/paused/completed/archived), `storyId` |
| `forge_workspace_delete` | Delete a workspace | `id` (required), `force` |
| `forge_workspace_status` | Get full details for a workspace | `id` (required) |

## Code Sessions (`forge_develop`)

Code sessions are isolated git worktrees tied to a work item. They are the primary way to get a working copy of a repo for implementation.

### Creating or resuming a session
```
forge_develop({ repo: "my-repo", workItem: "WI-42" })
```
This will:
1. Resolve the repo from the index (3-tier: user index → managed pool → fresh clone)
2. Check for an existing session for this repo + work item combination
3. **Resume** if found — returns existing `sessionPath` and `branch`
4. **Create** if not found — creates a git worktree, installs enforcement scripts, returns new `sessionPath` and `branch`

### Response: session ready
```json
{
  "status": "created",   // or "resumed"
  "sessionPath": "/Users/arkhera/Horus/data/sessions/my-repo/WI-42/",
  "branch": "feature/wi-42-my-feature",
  "workflow": { "type": "owner", "defaultBranch": "main" }
}
```
All code changes go into `sessionPath`. The session includes enforcement scripts at `.forge/scripts/`.

### Response: workflow confirmation needed
```json
{
  "status": "needs_workflow_confirmation",
  "detected": {
    "type": "fork",
    "upstream": "git@github.com:org/repo.git",
    "fork": "git@github.com:myuser/repo.git"
  },
  "message": "Workflow not confirmed for my-repo. Please confirm or correct the detected values."
}
```
Present detected values to user. On confirmation, re-call with `workflow` parameter:
```
forge_develop({ repo: "my-repo", workItem: "WI-42",
                workflow: { type: "fork", upstream: "git@github.com:org/repo.git" } })
```
This saves the workflow and creates the session in one shot.

### Session enforcement scripts
Each session has `.forge/scripts/` containing:
- `push.sh` — pushes to the correct remote for this repo's workflow type
- `create-pr.sh` — creates a PR against the correct target (handles fork→upstream, owner→same-repo, contributor→same-repo)
- `pre-push` hook — installed in `.git/hooks/`, rejects pushes to wrong remotes
- `commit-msg` hook — validates conventional commits when configured

### Multi-agent isolation
If two agents call `forge_develop` with the same `repo` + `workItem`, they get separate sessions (`-2` suffix). No collisions.

## Session Lifecycle (`forge_session_list`, `forge_session_cleanup`)

### Listing sessions
```
forge_session_list()                              // All active sessions
forge_session_list({ repo: "my-repo" })           // For a specific repo
forge_session_list({ workItem: "WI-42" })         // For a specific work item
forge_session_list({ status: "stale" })           // Sessions with no recent activity
```
Returns: sessionId, repo, workItem, branch, sessionPath, createdAt, lastModified, status.

### Cleaning up sessions
```
forge_session_cleanup({ auto: true })             // Auto-clean sessions whose work items are done/cancelled
forge_session_cleanup({ sessionId: "abc123" })    // Clean a specific session
forge_session_cleanup({ olderThanDays: 30 })      // Clean sessions older than 30 days
```
Auto-cleanup queries Anvil for work item status. Sessions tied to `done` or `cancelled` work items are removed. Returns a summary of what was cleaned and what was skipped (with reasons).

## Workspace Lifecycle

Workspaces are context envelopes — they install skills, MCP configs, CLAUDE.md, and environment variables. They do **not** clone repos. Code sessions (`forge_develop`) handle code isolation separately.

### Creating a workspace
```
forge_workspace_create({ config: "sdlc-default", storyId: "abc123" })
```
This will:
1. Resolve the workspace config artifact
2. Install plugins and skills
3. Set up MCP server connections
4. Emit CLAUDE.md and workspace.env
5. Register the workspace in the metadata store

### Lifecycle states
```
active → paused → active (resume)
active → completed → archived
any → deleted
```

### Listing workspaces
```
forge_workspace_list({ status: "active" })       // Active only
forge_workspace_list()                           // All non-archived
forge_workspace_list({ storyId: "abc123" })      // By linked story
```

### Getting workspace details
```
forge_workspace_status({ id: "ws-abc12345" })
```
Returns: name, config, status, path, story link, timestamps.

### Deleting a workspace
```
forge_workspace_delete({ id: "ws-abc12345", force: true })
```
Removes the workspace folder from disk. Does **not** remove code sessions — clean those separately with `forge_session_cleanup`.

## Repository Management

Forge maintains a local index of git repositories for quick lookup.

### Discovering repos
```
forge_repo_list()                             // All indexed repos
forge_repo_list({ query: "auth" })            // Filter by name/path/URL
forge_repo_list({ language: "typescript" })   // Filter by language
```

### Resolving a specific repo
```
forge_repo_resolve({ name: "anvil" })         // By name
forge_repo_resolve({ remoteUrl: "git@github.com:org/repo.git" })  // By URL
```
Returns: name, local path, remote URL, default branch, language, framework.

### Getting git workflow config
```
forge_repo_workflow({ name: "my-repo" })
```
Returns: strategy (owner/fork/contributor), default branch, PR target, hosting info.
Resolution order: saved workflow metadata → auto-detect from git remotes → defaults.

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
forge_list({ scope: "installed" })                // From lock file
forge_list({ scope: "available", type: "skill" }) // From registry
```

## When to Use Forge vs Direct Git

| Scenario | Use |
|----------|-----|
| Starting work on a new story/feature | Forge (`forge_develop`) |
| Switching between work items | Forge (`forge_develop` — resumes or creates) |
| Finding which repos exist locally | Forge (`repo_list`, `repo_resolve`) |
| Understanding a repo's PR workflow | Forge (`repo_workflow`) |
| Daily git operations (commit, diff, log) | Direct git inside session path |
| Pushing a branch | Session's `.forge/scripts/push.sh` |
| Creating a PR | Session's `.forge/scripts/create-pr.sh` |
| Installing skills or plugins | Forge (`add` + `install`) |
| Cleaning up finished work | Forge (`session_cleanup`) |
| Bootstrapping a new workspace | Forge (`workspace_create`) |
