# Data Operations Module (DVC + GCS)
# Usage: just data <command>
set shell := ["bash", "-uc"]

# Health domain path
health_dir := `git rev-parse --show-toplevel` / "domains/health"

# Show available data commands
[private]
default:
    @just --list --justfile {{ source_file() }}

# ═══════════════════════════════════════════════════════════════════════════════
# SYNC OPERATIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Push all data to GCS
push:
    @echo "Pushing data to GCS..."
    @cd {{ health_dir }} && uv run dvc push
    @echo "✓ Data pushed to GCS"

# Pull all data from GCS
pull:
    @echo "Pulling data from GCS..."
    @cd {{ health_dir }} && uv run dvc pull
    @echo "✓ Data pulled from GCS"

# Show DVC status
status:
    @cd {{ health_dir }} && uv run dvc status

# ═══════════════════════════════════════════════════════════════════════════════
# TRACKING
# ═══════════════════════════════════════════════════════════════════════════════

# Add new data directory to DVC tracking
add PATH:
    @cd {{ health_dir }} && uv run dvc add {{ PATH }}
    @echo "✓ Added {{ PATH }} to DVC tracking"
    @echo "Don't forget to commit the .dvc file!"

# Show what's being tracked
list:
    @echo "DVC-tracked data:"
    @ls -la {{ health_dir }}/data/*.dvc 2>/dev/null || echo "  (none)"
    @echo ""
    @echo "GCS remote:"
    @cd {{ health_dir }} && uv run dvc remote list

# ═══════════════════════════════════════════════════════════════════════════════
# MAINTENANCE
# ═══════════════════════════════════════════════════════════════════════════════

# Garbage collect local cache
gc:
    @echo "Cleaning DVC cache..."
    @cd {{ health_dir }} && uv run dvc gc --workspace
    @echo "✓ Cache cleaned"

# Show cache size
cache-size:
    @echo "DVC cache size:"
    @du -sh {{ health_dir }}/.dvc/cache 2>/dev/null || echo "  (no cache)"
