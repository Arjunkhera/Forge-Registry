#!/usr/bin/env python3
"""
Migrate Forge-Registry to directory-per-version structure.

For each artifact in skills/, agents/, plugins/, personas/, workspace-configs/:
  1. Read version from metadata.yaml
  2. Create {type}/{id}/{version}/ directory
  3. Move all files into the version directory
  4. Generate manifest.yaml with file list, SHA256 checksums, and timestamp
"""

import hashlib
import os
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
ARTIFACT_DIRS = ["skills", "agents", "plugins", "personas", "workspace-configs"]
SKIP_ENTRIES = {"_template", "README.md"}


def read_yaml_version(filepath):
    """Read the version field from a YAML file (simple line-based parser)."""
    with open(filepath) as f:
        for line in f:
            line = line.strip()
            if line.startswith("version:"):
                val = line.split(":", 1)[1].strip().strip("'\"")
                return val
    return None


def sha256_file(filepath):
    """Compute SHA256 hex digest of a file."""
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def collect_relative_files(directory):
    """Collect all files in directory, relative to directory."""
    files = []
    for root, _, filenames in os.walk(directory):
        for fn in sorted(filenames):
            full = Path(root) / fn
            files.append(str(full.relative_to(directory)))
    return files


def generate_manifest_yaml(version_dir, timestamp):
    """Generate manifest.yaml content as a string."""
    files = collect_relative_files(version_dir)
    lines = [
        'generated_at: "' + timestamp + '"',
        "files:",
    ]
    for relpath in files:
        if relpath == "manifest.yaml":
            continue
        fullpath = version_dir / relpath
        checksum = sha256_file(fullpath)
        lines.append('  - path: "' + relpath + '"')
        lines.append('    sha256: "' + checksum + '"')
    return "\n".join(lines) + "\n"


def migrate_artifact(type_dir, artifact_name, timestamp):
    """Migrate a single artifact to directory-per-version structure. Returns True on success."""
    artifact_dir = type_dir / artifact_name
    metadata_path = artifact_dir / "metadata.yaml"

    if not metadata_path.exists():
        print("  WARNING: Skipping " + str(artifact_dir) + " -- no metadata.yaml found")
        return False

    version = read_yaml_version(metadata_path)
    if not version:
        print("  WARNING: Skipping " + str(artifact_dir) + " -- no version field in metadata.yaml")
        return False

    version_dir = artifact_dir / version

    # Collect all entries to move
    entries_to_move = [e.name for e in artifact_dir.iterdir()]

    # Create version directory
    version_dir.mkdir(parents=True)

    # Move all files and dirs into version directory
    for entry_name in entries_to_move:
        src = artifact_dir / entry_name
        dst = version_dir / entry_name
        shutil.move(str(src), str(dst))

    # Generate manifest.yaml
    manifest_content = generate_manifest_yaml(version_dir, timestamp)
    manifest_path = version_dir / "manifest.yaml"
    manifest_path.write_text(manifest_content)

    print("  OK: " + str(artifact_dir) + " -> " + str(version_dir) + "/ (" + str(len(entries_to_move)) + " entries moved)")
    return True


def verify_flat_level_clean(type_dir):
    """Verify no artifact files remain at the flat level."""
    issues = []
    for artifact_entry in sorted(type_dir.iterdir()):
        if not artifact_entry.is_dir():
            continue
        if artifact_entry.name in SKIP_ENTRIES:
            continue
        for child in artifact_entry.iterdir():
            if child.is_file():
                issues.append(str(child.relative_to(REPO_ROOT)))
    return issues


def main():
    timestamp = datetime.now(timezone.utc).isoformat()
    print("Migration timestamp: " + timestamp)
    print("Repo root: " + str(REPO_ROOT))
    print()

    total_migrated = 0
    total_skipped = 0

    for type_name in ARTIFACT_DIRS:
        type_dir = REPO_ROOT / type_name
        if not type_dir.exists():
            print("Skipping " + type_name + "/ -- directory not found")
            continue

        print("Processing " + type_name + "/:")
        for entry in sorted(type_dir.iterdir()):
            if not entry.is_dir():
                print("  Skipping file: " + entry.name)
                continue
            if entry.name in SKIP_ENTRIES:
                print("  Skipping reserved: " + entry.name)
                continue

            if migrate_artifact(type_dir, entry.name, timestamp):
                total_migrated += 1
            else:
                total_skipped += 1
        print()

    print("Migration complete: " + str(total_migrated) + " migrated, " + str(total_skipped) + " skipped")
    print()

    print("Verifying no artifact files remain at flat level...")
    all_issues = []
    for type_name in ARTIFACT_DIRS:
        type_dir = REPO_ROOT / type_name
        if type_dir.exists():
            issues = verify_flat_level_clean(type_dir)
            all_issues.extend(issues)

    if all_issues:
        print("VERIFICATION FAILED -- " + str(len(all_issues)) + " files at flat level:")
        for issue in all_issues:
            print("  " + issue)
        return 1
    else:
        print("VERIFICATION PASSED -- all artifact files are in version directories")
        return 0


if __name__ == "__main__":
    sys.exit(main())
