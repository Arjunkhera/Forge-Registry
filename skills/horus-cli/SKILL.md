---
name: horus-cli
description: >
  Horus CLI reference. Use when you need to manage the Horus stack — start/stop
  services, check status, configure settings, update, backup, or troubleshoot.
  Covers all CLI commands, common workflows, and Docker/Podman differences.
---

# Horus CLI — Command Reference

The `horus` CLI manages the Horus Docker/Podman Compose stack (Anvil, Vault, Forge, QMD). It handles setup, lifecycle, configuration, and diagnostics.

## Commands

| Command | Description |
|---------|-------------|
| `horus setup` | Interactive first-run setup |
| `horus up` | Start the Horus stack |
| `horus down` | Stop the Horus stack |
| `horus status` | Show service status |
| `horus config` | View or modify configuration |
| `horus connect` | Configure AI client MCP integration |
| `horus update` | Update Horus to latest version |
| `horus doctor` | Diagnose common issues |
| `horus backup` | Backup or restore Horus data |

---

## `horus setup`

Interactive first-run setup. Detects available runtimes, gathers configuration, clones repos, pulls images, starts services, and configures AI clients.

```
horus setup [options]
```

| Flag | Description |
|------|-------------|
| `-y, --yes` | Non-interactive mode (use defaults + env vars) |
| `--runtime <runtime>` | Container runtime: `docker` or `podman` |
| `--data-dir <path>` | Data directory path (default: `~/.horus/data`) |
| `--repos-path <path>` | Host repos path for Forge scanning |
| `--git-host <host>` | Git server hostname (default: `github.com`) |
| `--anvil-repo <url>` | Anvil notes repository URL (HTTPS) |
| `--vault-repo <url>` | Vault knowledge-base repository URL (HTTPS) |
| `--forge-repo <url>` | Forge registry repository URL (HTTPS) |
| `--github-token <token>` | GitHub PAT for private repos |

**Setup flow:**
1. Check existing config
2. Detect & select container runtime
3. Gather configuration (data dir, repos, ports, tokens)
4. Save config to `~/.horus/config.yaml`
5. Generate `.env` file
6. Install `docker-compose.yml` (with Podman overrides if needed)
7. Clone repositories to data directory
8. Pull container images
9. Start services (`compose up -d`)
10. Poll health checks until all services are healthy
11. Configure detected AI clients (Claude Desktop/Code, Cursor)

**Non-interactive example:**
```bash
horus setup -y \
  --runtime podman \
  --anvil-repo https://github.com/user/horus-notes \
  --vault-repo https://github.com/user/knowledge-base \
  --forge-repo https://github.com/user/forge-registry \
  --github-token ghp_xxx
```

---

## `horus up`

Start the Horus stack.

```
horus up [--no-pull]
```

| Flag | Description |
|------|-------------|
| `--no-pull` | Skip pulling latest images before starting |

Detects runtime, optionally pulls images, then runs `compose up -d`.

---

## `horus down`

Stop the Horus stack. Data volumes are preserved.

```
horus down
```

---

## `horus status`

Show status of all Horus services.

```
horus status
```

Displays: CLI version, runtime, config path, and a table of services with status, ports, and uptime.

---

## `horus config`

View or modify Horus configuration.

```
horus config              # Show current configuration
horus config get <key>    # Get a specific value
horus config set <key> <value>  # Set a value
```

**Available config keys:**
- `data-dir` — Data directory path
- `host-repos-path` — Host repos path for Forge scanning
- `host-repos-extra-scan-dirs` — Extra scan directories (comma-separated)
- `runtime` — Container runtime (`docker` or `podman`)
- `port.anvil` — Anvil port (default: 8100)
- `port.vault-rest` — Vault REST port (default: 8000)
- `port.vault-mcp` — Vault MCP port (default: 8300)
- `port.forge` — Forge port (default: 8200)
- `github-token` — GitHub PAT
- `git-host` — Git server hostname
- `repo.anvil-notes` — Anvil notes repo URL
- `repo.vault-knowledge` — Vault knowledge-base repo URL
- `repo.forge-registry` — Forge registry repo URL

---

## `horus connect`

Configure Claude Desktop, Claude Code, or Cursor to use Horus MCP servers.

```
horus connect [options]
```

| Flag | Description |
|------|-------------|
| `--target <client>` | `claude-desktop`, `claude-code`, `cursor`, or `all` (default: auto-detect) |
| `--host <host>` | MCP host (default: `localhost`) |
| `-y, --yes` | Skip confirmation prompts |

Registers MCP servers (Anvil, Vault, Forge) and syncs skills to the appropriate client config directory.

---

## `horus update`

Update Horus to the latest version.

```
horus update [options]
```

| Flag | Description |
|------|-------------|
| `--rollback` | Roll back to the previous version |
| `-y, --yes` | Skip confirmation prompts |

Checks for latest version, saves pre-update snapshot, pulls latest images, restarts services. Use `--rollback` to restore from saved snapshot.

---

## `horus doctor`

Diagnose common Horus issues. Checks:

1. Container runtime (Docker/Podman) is running
2. Compose plugin is available
3. Config file exists
4. Compose file exists
5. Required ports are free (or held by Horus)
6. Data directory exists and is writable
7. Sufficient disk space (5GB recommended)
8. Service health status

```
horus doctor
```

Exit code 1 if any checks fail. Hints are provided for each failure.

---

## `horus backup`

Backup or restore Horus data.

```
horus backup              # Create a backup
horus backup restore <file>  # Restore from backup
```

| Flag | Description |
|------|-------------|
| `-y, --yes` | Skip confirmation prompts |

Backup stops services, archives the data directory as `.tar.gz`, then restarts. Restore extracts the archive and waits for services.

---

## Common Workflows

### First-time setup
```bash
horus setup
```

### Daily start/stop
```bash
horus up        # Start
horus down      # Stop (data preserved)
```

### Check health
```bash
horus status    # Quick overview
horus doctor    # Full diagnostic
```

### Reconfigure
```bash
horus config set port.anvil 9100
horus down && horus up
```

### Connect a new AI client
```bash
horus connect --target claude-code
```

### Update
```bash
horus update          # Update to latest
horus update --rollback  # Roll back if needed
```

### Backup before risky changes
```bash
horus backup
# ... make changes ...
horus backup restore ~/.horus/backups/horus-backup-2026-03-12.tar.gz
```

---

## Docker vs Podman Notes

Horus supports both Docker and Podman. The runtime is selected during `horus setup` and saved in config.

**Key differences handled by the CLI:**

| Concern | Docker | Podman |
|---------|--------|--------|
| Volume permissions | Works out of the box | CLI injects `user: "0:0"` override (safe in rootless mode) |
| Health checks | Uses `HEALTHCHECK` directive | Falls back to container state (`running`) when no HEALTHCHECK |
| Container naming | `horus-service-1` | `horus-service-1` or `horus_service_1` |
| `compose ps` JSON | Newline-delimited objects | JSON array |

**Podman-specific troubleshooting:**
- If `podman compose` fails: ensure Podman machine is running (`podman machine start`)
- If services don't start: check that Podman Desktop or the Podman VM is active
- If permission errors occur in containers: re-run `horus setup` to regenerate compose file with UID overrides

---

## File Locations

| File | Purpose |
|------|---------|
| `~/.horus/config.yaml` | Main configuration |
| `~/.horus/.env` | Generated environment variables for compose |
| `~/.horus/docker-compose.yml` | Installed compose file (may have Podman overrides) |
| `~/.horus/data/` | Data directory (notes, knowledge-base, registry) |
| `~/.horus/backups/` | Backup archives |

## Environment Variables

The CLI reads these environment variables as fallbacks during non-interactive setup:

- `ANVIL_REPO_URL`
- `VAULT_KNOWLEDGE_REPO_URL`
- `FORGE_REGISTRY_REPO_URL`
- `GITHUB_TOKEN`
