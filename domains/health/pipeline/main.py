#!/usr/bin/env python3
"""
Health Analysis Pipeline - Main Orchestrator

A deterministic, reproducible health data analysis pipeline.

Usage:
    python -m pipeline.main                    # Run full pipeline
    python -m pipeline.main --stage extract    # Run specific stage
    python -m pipeline.main --dry-run          # Show what would be done
    python -m pipeline.main --force            # Force regeneration
"""

import argparse
import json
import sys
import time
from dataclasses import asdict
from datetime import datetime
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from pipeline.analyze import analyze_all
from pipeline.comprehensive_report import generate_comprehensive_reports
from pipeline.config import Config
from pipeline.consolidate import consolidate_all, load_consolidated_data
from pipeline.context import (
    generate_context_for_next,
    load_previous_context,
    load_specific_context,
    save_context,
    serialize_for_json,
)
from pipeline.extract import compute_data_hash, extract_all, get_data_summary
from pipeline.schema import HealthProfile


def create_snapshot_id(data_hash: str) -> str:
    """Create snapshot ID from date and data hash."""
    date_str = datetime.now().strftime("%Y%m%d")
    return f"{date_str}_{data_hash[:8]}"


def create_manifest(
    snapshot_id: str,
    data_hash: str,
    data_summary: dict,
    output_files: list[str],
    previous_snapshot: str | None,
    duration: float,
) -> dict:
    """Create pipeline execution manifest."""
    return {
        "version": "1.0.0",
        "snapshot_id": snapshot_id,
        "created_at": datetime.now().isoformat(),
        "data_hash": data_hash,
        "input": {
            "individuals": data_summary.get("individuals", []),
            "data_files": data_summary.get("data_files", {}),
            "total_records": data_summary.get("total_records", 0),
            "previous_snapshot": previous_snapshot,
        },
        "output": {
            "files": output_files,
        },
        "pipeline": {
            "version": "1.0.0",
            "modules": ["extract", "consolidate", "analyze", "visualize", "report"],
            "duration_seconds": round(duration, 2),
        },
    }


def profiles_to_json(profiles: dict[str, HealthProfile]) -> dict:
    """Convert profiles to JSON-serializable format."""
    result = {}
    for key, profile in profiles.items():
        result[key] = {
            "individual": {
                "key": profile.individual.key,
                "name": profile.individual.name,
                "age": profile.individual.age,
            },
            "data_range": {
                "start": profile.data_range.start.isoformat(),
                "end": profile.data_range.end.isoformat(),
                "days": profile.data_range.days,
            },
            "health_scores": asdict(profile.health_scores),
            "cardiovascular": asdict(profile.cardiovascular),
            "respiratory": asdict(profile.respiratory),
            "sleep": asdict(profile.sleep),
            "recovery": asdict(profile.recovery),
            "recommendations": [
                {
                    "id": r.rec_id,
                    "category": r.category,
                    "priority": r.priority.value,
                    "finding": r.finding,
                    "action": r.action,
                    "medical_note": r.medical_note,
                    "status": r.status.value,
                    "created": r.created.isoformat(),
                }
                for r in profile.recommendations
            ],
            "alerts": [
                {
                    "id": a.alert_id,
                    "type": a.alert_type,
                    "severity": a.severity.value,
                    "message": a.message,
                    "value": a.value,
                    "threshold": a.threshold,
                }
                for a in profile.alerts
            ],
            "lifestyle_patterns": profile.lifestyle_patterns,
        }
    return result


def run_pipeline(
    base_path: Path,
    context_path: Path | None = None,
    stages: list[str] | None = None,
    force: bool = False,
    dry_run: bool = False,
) -> dict:
    """
    Run the health analysis pipeline.

    Args:
        base_path: Project root directory
        context_path: Optional path to specific previous context
        stages: Optional list of stages to run (default: all)
        force: Force regeneration even if snapshot exists
        dry_run: Show what would be done without executing

    Returns:
        Pipeline execution summary
    """
    start_time = time.time()

    print("\n" + "=" * 70)
    print("HEALTH ANALYSIS PIPELINE v1.0.0")
    print("=" * 70)
    print(f"Base path: {base_path}")
    print(f"Timestamp: {datetime.now().isoformat()}")
    print()

    # Load configuration
    config = Config(base_path)
    print(f"Loaded configuration for {len(config.individuals)} individuals")

    # Determine stages to run
    all_stages = ["extract", "consolidate", "analyze", "visualize", "report"]
    stages_to_run = stages if stages else all_stages

    if dry_run:
        print(f"\n[DRY RUN] Would run stages: {stages_to_run}")
        return {"dry_run": True, "stages": stages_to_run}

    # Stage 1: Extract
    if "extract" in stages_to_run:
        print("\n--- STAGE 1: EXTRACT ---")
        extract_all(config)

    # Compute data hash for snapshot identification
    data_hash = compute_data_hash(config)
    snapshot_id = create_snapshot_id(data_hash)
    print(f"\nData hash: {data_hash}")
    print(f"Snapshot ID: {snapshot_id}")

    # Check if snapshot already exists
    snapshot_path = config.get_snapshots_path() / snapshot_id
    if snapshot_path.exists() and not force:
        print(f"\nSnapshot {snapshot_id} already exists. Use --force to regenerate.")
        return {
            "snapshot_id": snapshot_id,
            "status": "exists",
            "path": str(snapshot_path),
        }

    # Create snapshot directory
    snapshot_path.mkdir(parents=True, exist_ok=True)

    # Load previous context
    if context_path:
        previous_context = load_specific_context(context_path)
        print(f"Loaded context from: {context_path}")
    else:
        previous_context = load_previous_context(config.get_snapshots_path())
        if previous_context:
            print(f"Loaded previous context: {previous_context.get('snapshot_id')}")
        else:
            print("No previous context found (first run)")

    previous_snapshot_id = previous_context.get("snapshot_id") if previous_context else None

    # Stage 2: Consolidate
    if "consolidate" in stages_to_run:
        print("\n--- STAGE 2: CONSOLIDATE ---")
        all_data = consolidate_all(config)
    else:
        all_data = load_consolidated_data(config)

    # Stage 3: Analyze
    profiles = {}
    if "analyze" in stages_to_run:
        print("\n--- STAGE 3: ANALYZE ---")
        profiles = analyze_all(all_data, config)

    # Stage 4: Generate Reports (combines visualizations into PDFs)
    output_files = []
    if "visualize" in stages_to_run or "report" in stages_to_run:
        print("\n--- STAGE 4: GENERATE REPORTS ---")

        # Generate comprehensive PDF reports (per-person + summary)
        report_files = generate_comprehensive_reports(
            profiles, all_data, previous_context, snapshot_path, config, snapshot_id
        )
        output_files.extend(report_files)

        # Save health profiles JSON (for programmatic access)
        profiles_json = profiles_to_json(profiles)
        profiles_path = snapshot_path / "health_profiles.json"
        with open(profiles_path, "w") as f:
            json.dump(profiles_json, f, indent=2, default=serialize_for_json)
        output_files.append("health_profiles.json")
        print("Saved: health_profiles.json")

        # Generate and save context for next analysis
        context = generate_context_for_next(snapshot_id, profiles, previous_context)
        context_out_path = snapshot_path / "context_for_next.json"
        save_context(context, context_out_path)
        output_files.append("context_for_next.json")
        print("Saved: context_for_next.json")

    # Create and save manifest
    duration = time.time() - start_time
    data_summary = get_data_summary(config)
    manifest = create_manifest(
        snapshot_id, data_hash, data_summary, output_files, previous_snapshot_id, duration
    )
    manifest_path = snapshot_path / "manifest.json"
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2)
    print("Saved: manifest.json")

    # Update latest symlink
    latest_path = config.get_latest_symlink_path()
    if latest_path.is_symlink():
        latest_path.unlink()
    elif latest_path.exists():
        import shutil

        shutil.rmtree(latest_path)
    latest_path.symlink_to(snapshot_path.relative_to(base_path))
    print(f"\nUpdated symlink: {latest_path.name} -> {snapshot_path.name}")

    # Summary
    print("\n" + "=" * 70)
    print("PIPELINE COMPLETE")
    print("=" * 70)
    print(f"Snapshot ID: {snapshot_id}")
    print(f"Output path: {snapshot_path}")
    print(f"Duration: {duration:.1f} seconds")
    print(f"Files generated: {len(output_files)}")

    if previous_context:
        print(f"\nCompared with previous: {previous_snapshot_id}")

    # Print score summary
    print("\n--- HEALTH SCORES ---")
    print(f"{'Person':<25} {'Overall':>8} {'CV':>6} {'Sleep':>6} {'Recovery':>8}")
    print("-" * 55)
    for _key, profile in profiles.items():
        s = profile.health_scores
        print(
            f"{profile.individual.name:<25} {s.overall:>8.0f} {s.cardiovascular:>6.0f} "
            f"{s.sleep:>6.0f} {s.recovery:>8.0f}"
        )

    return {
        "snapshot_id": snapshot_id,
        "status": "completed",
        "path": str(snapshot_path),
        "duration": duration,
        "files": output_files,
    }


def main():
    """CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Health Analysis Pipeline - Deterministic health data analysis"
    )
    parser.add_argument(
        "--stage",
        choices=["extract", "consolidate", "analyze", "visualize", "report"],
        help="Run only a specific stage",
    )
    parser.add_argument("--skip-extract", action="store_true", help="Skip extraction stage")
    parser.add_argument("--skip-visualize", action="store_true", help="Skip visualization stage")
    parser.add_argument("--context", type=Path, help="Path to specific previous context file")
    parser.add_argument(
        "--force", action="store_true", help="Force regeneration even if snapshot exists"
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Show what would be done without executing"
    )
    parser.add_argument(
        "--base-path",
        type=Path,
        default=Path(__file__).parent.parent,
        help="Base path for the project",
    )

    args = parser.parse_args()

    # Determine stages
    if args.stage:
        stages = [args.stage]
    else:
        stages = ["extract", "consolidate", "analyze", "visualize", "report"]
        if args.skip_extract:
            stages.remove("extract")
        if args.skip_visualize:
            stages.remove("visualize")

    result = run_pipeline(
        base_path=args.base_path,
        context_path=args.context,
        stages=stages,
        force=args.force,
        dry_run=args.dry_run,
    )

    # Exit with appropriate code
    if result.get("status") == "completed" or result.get("status") == "exists":
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
