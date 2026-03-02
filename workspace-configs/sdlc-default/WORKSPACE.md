id: sdlc-default
name: SDLC v2 Default Workspace
version: 1.0.0
description: >
  Default workspace configuration for the Horus SDLC v2 workflow. Provides a complete software
  development lifecycle with 9 skills, 6 subagents, and skill scripts for planning, implementing,
  testing, reviewing, documenting, and shipping software. All SDLC state lives in Anvil as typed
  notes; architecture knowledge comes from Vault; workspaces are managed by Forge.
type: workspace-config
author: Arjun Khera
license: MIT
tags:
  - sdlc
  - development
  - horus
  - default

# Plugin references — Forge resolves and installs these during workspace creation
plugins:
  - anvil-sdlc-v2

# Individual skills (if any standalone skills beyond the plugin)
skills: []

# MCP server connections — URLs resolved from ~/.forge/config.yaml at creation time
mcp_servers:
  anvil:
    description: "Anvil note management — work items, plans, projects, scratch journals. Required for all SDLC operations."
    required: true
  vault:
    description: "Vault knowledge service — architecture docs, repo profiles, conventions. Optional but recommended for full context."
    required: false
  forge:
    description: "Forge workspace and package manager — workspace creation, repo resolution, skill discovery. Optional but recommended."
    required: false

# Workspace settings
settings:
  retention_days: 30
  naming_convention: "{subtype}/{id}-{slug}"
  auto_archive_on_done: false

# Git workflow configuration — Forge emits these as env vars for skill scripts
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
  # These are resolved per-repo from Vault repo profiles at workspace creation:
  # SDLC_TEST_CMD: (from Vault repo profile, e.g. "npm test", "pytest -x")
  # SDLC_LINT_CMD: (from Vault repo profile, e.g. "npm run lint", "ruff check .")
  # SDLC_PR_TEMPLATE: (from Vault repo profile, e.g. ".github/pull_request_template.md")

# Rules emitted into the workspace
rules:
  global: "resources/rules/global-rules.md"

# Anvil type definitions contributed by this workspace config
# Anvil picks these up via the plugin's resources/types/ directory
anvil_types:
  - work-item
  - plan
