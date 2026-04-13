id: finance
name: Finance Research Workspace
version: 1.3.0
description: >
  Finance-domain workspace configuration for the Horus platform. A focused
  research environment built around the Research Division pipeline, the
  full finance methodology skill set, the finance sub-agent library, and
  a five-voice finance-specialist persona council.

  v1.3.0 changes:
  - Adds the `per-ticker-research` skill — primary research engine for
    individual tickers. Memory-checks prior briefs with regime gating,
    runs a parallel three-persona council (equity-analyst, swing-trader,
    quant), synthesises an aggregate verdict, writes an immutable
    research-brief, and fire-and-forget triggers the Map Keeper.
  - Closes the critical-path Phase 1 research loop: Research Lead routes
    → Per-Ticker Research executes → Map Keeper updates the hierarchy.

  v1.2.0 added the Research Division foundation: `research-lead` skill
  (single entry point with circuit breaker) + `finance-map-keeper` agent
  (knowledge hierarchy maintenance). Removed the `anvil-sdlc-v2` plugin.

  v1.1.0 (master) added the 12 phase-2 methodology skills and 16
  specialised sub-agents wired into the persona council. v1.3.0 keeps
  all of that.

  Workspace is context-only — it installs skills, agents, personas, MCP
  configs, CLAUDE.md, and environment variables. It does not clone repos.
  Use forge_develop to start an isolated code session (git worktree) when
  you need to make code changes.
type: workspace-config
author: Arjun Khera
license: MIT
tags:
  - finance
  - horus
  - research
  - agentic-finance
  - phase-2

# No plugins — finance workspace is a pure research environment.
# (Removed anvil-sdlc-v2 in v1.2.0 — use sdlc-default for SDLC work.)
plugins: []

# Skills
# - research-lead: Research Division entry point. Parses user intent, runs
#   pre-checks (regime-classifier, tape-reader), enforces circuit breaker on
#   noise, and routes to Per-Ticker or X Research modules.
# - Phase 2 methodology skills (per persona):
#   Trader (3): pre-trade checklist, stopped-out post-mortem, phase-of-market framework
#   Analyst (3): thesis-catalyst-variant, thesis pre-mortem, unit-economics teardown
#   PM (2): position-fit pre-mortem, regime-change playbook
#   Allocator (2): opportunity-set filter, rebalancing discipline
#   Quant (2): pre-registration checklist, backtest autopsy
skills:
  - research-lead
  - per-ticker-research
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

# Sub-agents
# - finance-map-keeper: Reads research briefs, extracts market entities,
#   creates missing Anvil entities, wires graph relationships, and updates
#   the Keystone Map dashboard. Invoked by research modules after each brief.
# - Phase 2 specialised executors per persona:
#   Trader (3): tape-reader, stop-and-size, setup-journal
#   Analyst (4): filings-diff, transcript-parser, fcf-bridge, consensus-scraper
#   PM (3): factor-decomposer, stress-runner, risk-budget-reconciler
#   Allocator (2): macro-regime-tracker, drift-monitor
#   Quant (4): walk-forward-backtester, multiple-testing-adjuster, edge-decay-monitor, regime-classifier
agents:
  - finance-map-keeper
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
    description: "Anvil note management — work items, plans, projects, scratch journals. Required for research-brief storage and Keystone Map maintenance."
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
