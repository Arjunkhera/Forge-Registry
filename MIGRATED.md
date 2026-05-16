# Forge Registry — Migrated

This repository was the original git-based Forge artifact registry.

**Migration date:** 2026-05-16

**New registry:** https://d1agcpjabvrj1s.cloudfront.net

All artifacts have been migrated to the live HTTP registry. This repository is now **read-only** and kept as an archive. The URL continues to resolve for any existing references.

## Artifact inventory migrated

| Type | Count |
|------|-------|
| skill | 71 |
| agent | 40 |
| plugin | 4 |
| persona | 9 |
| workspace-config | 8 |
| **Total** | **135** |

## Migration notes

9 sdlc agent metadata files were missing the `rootSkill` field required by the HTTP
registry schema. These were fixed before migration (commit `1aa299d`).

## Using the new registry

Update your `forge.yaml`:

```yaml
registry:
  url: https://d1agcpjabvrj1s.cloudfront.net
```
