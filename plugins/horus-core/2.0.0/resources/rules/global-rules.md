# Horus System Awareness

You have access to three interconnected systems. Route requests to the correct system based on user intent.

## Systems

| System | Purpose | When to use |
|--------|---------|-------------|
| **Anvil** | Live state — notes, tasks, journals, stories | Creating, reading, updating, or querying work items and structured notes |
| **Vault** | Knowledge base — guides, procedures, repo profiles | Understanding codebases, finding conventions, documenting decisions |
| **Forge** | Execution — workspaces, repos, plugins | Setting up dev environments, managing repos, installing tools |

## Intent Routing

| User says something like... | System | Start with |
|----------------------------|--------|------------|
| "what's pending?", "show my tasks", "what am I working on?" | Anvil | `anvil_search` or `anvil_query_view` with status filter |
| "create a task/note/story", "log this", "track this" | Anvil | `anvil_list_types` first, then `anvil_create_note` |
| "update the status", "mark as done", "add a note to..." | Anvil | `anvil_update_note` |
| "how does X work?", "what are the conventions for...?" | Vault | `knowledge_resolve_context` or `knowledge_search` |
| "document this decision", "write a guide for..." | Vault | `knowledge_check_duplicates` then full write path |
| "set me up to work on X", "create a workspace" | Forge | `forge_workspace_create` |
| "what repos do I have?", "find the repo for..." | Forge | `forge_repo_list` or `forge_repo_resolve` |
| "install/add a plugin or skill" | Forge | `forge_search` then `forge_add` then `forge_install` |

## Critical Rules

1. **Never guess Anvil types or fields.** Always call `anvil_list_types` before creating notes. Use only the types and fields it returns.
2. **Vault read-path first.** Before writing new knowledge, search for existing pages: `knowledge_resolve_context` (for repo-scoped) or `knowledge_search` (for general).
3. **Vault write-path is a pipeline.** Always: check duplicates → suggest metadata → validate → write. Never skip steps.
4. **Anvil updates are PATCH.** Only send fields you want to change. Omitted fields are preserved.
5. **Anvil journals append-only.** When updating journal content, new content is appended, not replaced.
6. **Use `anvil_query_view` for structured views.** Use `view: "board"` with `groupBy` for kanban-style views, `view: "table"` with `columns` for tabular data. Use `filters` (not `filter`) and `orderBy` (not `sort`).
7. **Forge workspaces vs direct git.** Use Forge for bootstrapping new work (workspace creation, worktree setup). Use direct git commands for daily operations within an existing workspace.

For detailed tool reference, parameters, and error recovery, refer to the horus-anvil, horus-vault, and horus-forge skills.
