id: finance
name: Finance Research Workspace
version: 1.0.0
description: >
  Workspace configuration for finance-domain research and agentic-finance product
  development. Provides the full SDLC v2 workflow (planning, design, discovery,
  implementation, testing, review, docs) via the anvil-sdlc-v2 plugin, with a
  five-voice finance-specialist persona council replacing the generalist personas
  used in sdlc-default. Designed for building agent-first finance systems where
  domain-specific critique is needed in discovery and design conversations.

  Workspace is context-only — it installs skills, MCP configs, CLAUDE.md, and
  environment variables. It does not clone repos. Use forge_develop to start an
  isolated code session (git worktree) when you need to make code changes.
type: workspace-config
author: Arjun Khera
license: MIT
tags:
  - finance
  - sdlc
  - horus
  - research
  - agentic-finance

# Plugin references — Forge resolves and installs these during workspace creation
plugins:
  - anvil-sdlc-v2

# Individual skills (if any standalone skills beyond the plugin)
skills: []

# Personas — finance-specialist council.
# Each persona is a thin, sharp voice with one worldview, one signature fear,
# and one characteristic interrupt question. Personas delegate heavy task work
# to sub-agents rather than carrying deep domain capability internally.
# No generalist personas — the human plays the frame-level skeptic role in the room.
personas:
  - finance-swing-trader
  - finance-equity-analyst
  - finance-portfolio-manager
  - finance-allocator
  - finance-quant

# MCP server connections — URLs resolved from ~/.forge/config.yaml at creation time
mcp_servers:
  anvil:
    description: "Anvil note management — work items, plans, projects, scratch journals. Required for all SDLC operations."
    required: true
  vault:
    description: "Vault knowledge service — architecture docs, repo profiles, conventions. Optional but recommended for full context."
    required: false
  forge:
    description: "Forge execution layer — workspace management, repo index, code sessions (forge_develop), session lifecycle. Optional but recommended."
    required: false

# Workspace settings
settings:
  retention_days: 30
  naming_convention: "{subtype}/{id}-{slug}"
  auto_archive_on_done: false

# Git workflow configuration — emitted as env vars for skill scripts and session enforcement
git_workflow:
  branch_pattern: "{subtype}/{id}-{slug}"
  base_branch: main
  stash_before_checkout: true
  commit_format: conventional
  pr_template: true
  signed_commits: false

# Environment variables emitted into the workspace for skill scripts
env:
  SDLC_BRANCH_PATTERN: "{subtype}/{id}-{slug}"
  SDLC_BASE_BRANCH: main
  SDLC_STASH_BEFORE_CHECKOUT: "true"
  SDLC_COMMIT_FORMAT: conventional

# Rules emitted into the workspace
rules:
  global: "resources/rules/global-rules.md"

# Anvil type definitions contributed by this workspace config
# Anvil picks these up via the plugin's resources/types/ directory
anvil_types:
  - work-item
  - plan
