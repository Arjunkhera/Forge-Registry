# Test Integration Skill

This skill verifies that an agent can successfully reach and interact with all three Horus products (Anvil, Vault, and Forge).

## Purpose

Provides an automated test of the full Horus integration by calling MCP endpoints across all three services in sequence.

## Description

The Test Integration Skill performs the following verifications:

1. **Anvil (Note Management)** — Calls `anvil_search` to query test notes with the tag `test-fixture`
2. **Vault (Semantic Search)** — Calls Vault's `/search` endpoint to fetch repository profiles from the knowledge-base repo
3. **Forge (Package/Workspace Manager)** — Calls `forge_repo_list` to enumerate indexed repositories

## Prerequisites

- Anvil service running on `http://localhost:8100`
- Vault service running on `http://localhost:8000`
- Forge service running on `http://localhost:8200`
- All services must have MCP server capabilities enabled

## Instructions

### Step 1: Search Anvil for Test Notes

Query Anvil for all notes tagged with `test-fixture`:

```
Call anvil_search with query: "test-fixture"
Expected result: Returns 4 test notes (note, task, work-item, project)
Verify: All notes have titles starting with "Test-"
```

### Step 2: Search Vault for Repository Profiles

Query Vault's semantic search for repository information:

```
Call /search endpoint on Vault (http://localhost:8000/search)
Expected result: Returns repository metadata from knowledge-base repo
Verify: Response includes repo profiles and index information
```

### Step 3: List Repositories in Forge

Query Forge for all indexed repositories:

```
Call forge_repo_list to enumerate registered repositories
Expected result: Returns list of indexed repos
Verify: List includes at least the test repositories
```

### Step 4: Verify Integration

Confirm all three services responded successfully:

```
- [ ] Anvil responded with test note data
- [ ] Vault returned semantic search results
- [ ] Forge provided repository listing
- [ ] All responses matched expected structure
```

## Success Criteria

All three services respond without errors and return data matching the expected format. This confirms the Horus system is fully integrated and operational.

## Notes

This is a test fixture for Story 003: Sample Test Workspace and Test Data. Use this skill as part of integration testing and verification pipelines.
