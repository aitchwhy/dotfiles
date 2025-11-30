"""
Context management for analysis continuity.

Handles loading previous analysis context and generating context for next analysis.
"""

import json
from dataclasses import asdict
from datetime import date, datetime
from pathlib import Path

import numpy as np

from .schema import (
    AlertSeverity,
    HealthProfile,
    Priority,
    RecommendationStatus,
)


def serialize_for_json(obj):
    """Custom JSON serializer for dataclasses and special types."""
    if isinstance(obj, (date, datetime)):
        return obj.isoformat()
    if isinstance(obj, (Priority, RecommendationStatus, AlertSeverity)):
        return obj.value
    if isinstance(obj, (np.bool_, np.integer)):
        return int(obj)
    if isinstance(obj, np.floating):
        return float(obj)
    if isinstance(obj, np.ndarray):
        return obj.tolist()
    if hasattr(obj, "__dataclass_fields__"):
        return asdict(obj)
    raise TypeError(f"Object of type {type(obj)} is not JSON serializable")


def find_latest_snapshot(snapshots_path: Path) -> Path | None:
    """Find the most recent snapshot directory."""
    if not snapshots_path.exists():
        return None

    snapshots = sorted(snapshots_path.iterdir(), reverse=True)
    for snapshot in snapshots:
        if snapshot.is_dir() and (snapshot / "context_for_next.json").exists():
            return snapshot

    return None


def load_previous_context(snapshots_path: Path) -> dict | None:
    """Load context from the most recent snapshot."""
    latest = find_latest_snapshot(snapshots_path)
    if latest is None:
        return None

    context_path = latest / "context_for_next.json"
    if not context_path.exists():
        return None

    with open(context_path) as f:
        return json.load(f)


def load_specific_context(context_path: Path) -> dict | None:
    """Load context from a specific file."""
    if not context_path.exists():
        return None

    with open(context_path) as f:
        return json.load(f)


def compare_with_previous(current_profile: HealthProfile, previous_context: dict) -> dict:
    """Compare current analysis with previous context."""
    if previous_context is None:
        return {"has_previous": False}

    key = current_profile.individual.key
    previous_data = previous_context.get("individuals", {}).get(key)

    if previous_data is None:
        return {"has_previous": False}

    comparison = {
        "has_previous": True,
        "previous_snapshot": previous_context.get("snapshot_id"),
        "previous_date": previous_context.get("analysis_date"),
        "score_changes": {},
        "metric_changes": {},
        "recommendation_status": [],
    }

    # Compare health scores
    prev_scores = previous_data.get("health_scores", {})
    curr_scores = current_profile.health_scores

    for score_name in ["overall", "cardiovascular", "respiratory", "sleep", "recovery", "activity"]:
        prev_val = prev_scores.get(score_name, 0)
        curr_val = getattr(curr_scores, score_name, 0)
        change = curr_val - prev_val

        comparison["score_changes"][score_name] = {
            "previous": prev_val,
            "current": curr_val,
            "change": change,
            "direction": "improved" if change > 0 else "declined" if change < 0 else "stable",
        }

    # Compare key metrics
    prev_metrics = previous_data.get("key_metrics", {})
    curr_cv = current_profile.cardiovascular
    curr_sleep = current_profile.sleep

    metric_comparisons = [
        ("rhr_30day_avg", curr_cv.rhr_30day_avg, "lower_better"),
        ("hrv_30day_avg", curr_cv.hrv_30day_avg, "higher_better"),
        ("sleep_duration_hours", curr_sleep.duration_hours, "higher_better"),
        ("sleep_efficiency", curr_sleep.efficiency, "higher_better"),
    ]

    for metric_name, curr_val, direction in metric_comparisons:
        prev_val = prev_metrics.get(metric_name)
        if prev_val is not None and curr_val is not None:
            change = curr_val - prev_val
            improved = change < 0 if direction == "lower_better" else change > 0

            comparison["metric_changes"][metric_name] = {
                "previous": prev_val,
                "current": curr_val,
                "change": round(change, 2),
                "direction": "improved" if improved else "declined" if change != 0 else "stable",
            }

    # Check previous recommendations
    prev_recs = previous_data.get("recommendations", [])
    for prev_rec in prev_recs:
        rec_status = {
            "id": prev_rec.get("id"),
            "category": prev_rec.get("category"),
            "action": prev_rec.get("action"),
            "status": "needs_review",
        }

        # Simple heuristic: check if related metrics improved
        category = prev_rec.get("category", "").lower()
        if "sleep" in category:
            if comparison["score_changes"].get("sleep", {}).get("direction") == "improved":
                rec_status["status"] = "likely_followed"
            else:
                rec_status["status"] = "needs_attention"
        elif (
            "activity" in category
            and comparison["score_changes"].get("activity", {}).get("direction") == "improved"
        ):
            rec_status["status"] = "likely_followed"

        comparison["recommendation_status"].append(rec_status)

    return comparison


def generate_context_for_next(
    snapshot_id: str, profiles: dict[str, HealthProfile], previous_context: dict | None = None
) -> dict:
    """Generate context JSON for the next analysis."""
    context = {
        "snapshot_id": snapshot_id,
        "analysis_date": date.today().isoformat(),
        "individuals": {},
        "family_insights": {
            "shared_concerns": [],
            "shared_strengths": [],
        },
    }

    # Collect concerns and strengths across all individuals
    all_concerns = []
    all_strengths = []

    for key, profile in profiles.items():
        individual_context = {
            "health_scores": {
                "overall": profile.health_scores.overall,
                "cardiovascular": profile.health_scores.cardiovascular,
                "respiratory": profile.health_scores.respiratory,
                "sleep": profile.health_scores.sleep,
                "recovery": profile.health_scores.recovery,
                "activity": profile.health_scores.activity,
            },
            "key_metrics": {
                "rhr_mean": profile.cardiovascular.rhr_mean,
                "rhr_30day_avg": profile.cardiovascular.rhr_30day_avg,
                "hrv_mean": profile.cardiovascular.hrv_mean,
                "hrv_30day_avg": profile.cardiovascular.hrv_30day_avg,
                "spo2_mean": profile.respiratory.spo2_mean,
                "spo2_low_pct": profile.respiratory.low_readings_pct,
                "sleep_duration_hours": profile.sleep.duration_hours,
                "sleep_efficiency": profile.sleep.efficiency,
                "deep_sleep_pct": profile.sleep.deep_sleep_pct,
                "recovery_mean": profile.recovery.recovery_mean,
                "recovery_green_pct": profile.recovery.green_pct,
                "strain_mean": profile.recovery.strain_mean,
            },
            "recommendations": [
                {
                    "id": rec.rec_id,
                    "category": rec.category,
                    "priority": rec.priority.value,
                    "action": rec.action,
                    "status": rec.status.value,
                    "created": rec.created.isoformat(),
                }
                for rec in profile.recommendations
            ],
            "alerts": [
                {
                    "id": alert.alert_id,
                    "type": alert.alert_type,
                    "severity": alert.severity.value,
                    "message": alert.message,
                    "value": alert.value,
                }
                for alert in profile.alerts
            ],
        }

        # Compare with previous if available
        if previous_context:
            individual_context["comparison"] = compare_with_previous(profile, previous_context)

        context["individuals"][key] = individual_context

        # Track concerns and strengths
        for rec in profile.recommendations:
            if rec.priority == Priority.HIGH:
                all_concerns.append(rec.category.lower())

        if profile.health_scores.sleep >= 80:
            all_strengths.append("sleep")
        if profile.health_scores.cardiovascular >= 80:
            all_strengths.append("cardiovascular")
        if profile.sleep.deep_sleep_pct >= 20:
            all_strengths.append("deep_sleep")

    # Find shared patterns
    from collections import Counter

    concern_counts = Counter(all_concerns)
    strength_counts = Counter(all_strengths)

    # Concerns shared by 2+ people
    context["family_insights"]["shared_concerns"] = [
        c for c, count in concern_counts.items() if count >= 2
    ]

    # Strengths shared by 2+ people
    context["family_insights"]["shared_strengths"] = [
        s for s, count in strength_counts.items() if count >= 2
    ]

    return context


def save_context(context: dict, output_path: Path):
    """Save context to JSON file."""
    with open(output_path, "w") as f:
        json.dump(context, f, indent=2, default=serialize_for_json)
