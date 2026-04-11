id: finance
name: Finance Research Workspace
version: 1.1.0
description: >
  Phase 2 of the finance workspace configuration. Extends phase 1 (five
  finance-specialist personas installed via sdlc-default workflow) with a
  full catalogue of 12 methodology skills and 16 specialised sub-agents,
  authored in voice for each persona after direct consultation with each
  one about what they would actually delegate.

  The workspace remains context-only — it installs plugins, skills, personas,
  sub-agents, MCP configs, CLAUDE.md, and environment variables. It does not
  clone repos. Use forge_develop to start an isolated code session (git
  worktree) when you need to make code changes.
type: workspace-config
author: Arjun Khera
license: MIT
tags:
  - finance
  - sdlc
  - horus
  - research
  - agentic-finance
  - phase-2

# Plugin references — Forge resolves and installs these during workspace creation
plugins:
  - anvil-sdlc-v2

# Phase 2 skills — methodology packages per persona
# Trader (3): pre-trade checklist, stopped-out post-mortem, phase-of-market framework
# Analyst (3): thesis-catalyst-variant, thesis pre-mortem, unit-economics teardown
# PM (2): position-fit pre-mortem, regime-change playbook
# Allocator (2): opportunity-set filter, rebalancing discipline
# Quant (2): pre-registration checklist, backtest autopsy
skills:
  - finance-pre-trade-checklist
  - finance-stopped-out-post-mortem
  - finance-phase-of-market
  - finance-thesis-catalyst-variant
  - finance-thesis-pre-mortem
  - finance-unit-economics-teardown
  - finance-position-fit-pre-mortem
  - finance-regime-change-playbook
  - finance-opportunity-set-filter
  - finance-rebalancing-discipline
  - finance-pre-registration-checklist
  - finance-backtest-autopsy

# Phase 2 sub-agents — specialised executors per persona
# Trader (3): tape-reader, stop-and-size, setup-journal
# Analyst (4): filings-diff, transcript-parser, fcf-bridge, consensus-scraper
# PM (3): factor-decomposer, stress-runner, risk-budget-reconciler
# Allocator (2): macro-regime-tracker, drift-monitor
# Quant (4): walk-forward-backtester, multiple-testing-adjuster, edge-decay-monitor, regime-classifier
agents:
  - finance-tape-reader
  - finance-stop-and-size
  - finance-setup-journal
  - finance-filings-diff
  - finance-transcript-parser
  - finance-fcf-bridge
  - finance-consensus-scraper
  - finance-factor-decomposer
  - finance-stress-runner
  - finance-risk-budget-reconciler
  - finance-macro-regime-tracker
  - finance-drift-monitor
  - finance-walk-forward-backtester
  - finance-multiple-testing-adjuster
  - finance-edge-decay-monitor
  - finance-regime-classifier

# Personas — finance-specialist council (unchanged from 1.0.0)
# Each persona is a thin, sharp voice with one worldview, one signature fear,
# and one characteristic interrupt question. Personas delegate heavy task work
# to the sub-agents listed above and reach for the skills listed above.
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

# Git workflow configuration
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
anvil_types:
  - work-item
  - plan
