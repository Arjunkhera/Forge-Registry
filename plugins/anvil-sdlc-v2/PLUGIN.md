# Anvil SDLC v2 Plugin

Complete software development lifecycle plugin for the Horus platform (Anvil + Forge + Vault).

## Skills

| Skill | Purpose |
|-------|---------|
| orchestrator | Central command hub, dashboards, routing, search, release |
| project | Project CRUD, Vault/Forge integration |
| story | Work item lifecycle, 7 subtypes, state machine |
| planner | Feature decomposition with context gathering |
| developer | Plan → approve → implement with workspace bootstrapping |
| tester | Test plan → write → execute → report |
| reviewer | Code review, PR creation |
| docs | ADRs, Vault ingestion, doc health audits |
| scratch | Append-only journals, tagged entries |

## Subagents

| Subagent | Workflow |
|----------|----------|
| gather-context | Deep multi-source research |
| implement-story | Full story lifecycle end-to-end |
| plan-feature | Feature → work items breakdown |
| test-suite | Comprehensive testing pipeline |
| doc-sync | Post-implementation documentation sync |
| release | Tag, changelog, version bump, push |

## MCP Dependencies

- **Anvil MCP** (required) — work items, plans, projects, scratch journals
- **Vault MCP** (optional) — architecture docs, repo profiles, conventions
- **Forge MCP** (optional) — workspace creation, repo resolution
