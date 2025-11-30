"""
Weekly health analysis module.

Generates week-over-week comparisons with time-weighted insights.
Focus on recent changes with actionable recommendations for the coming week.
"""

import argparse
import json
from dataclasses import asdict, dataclass
from datetime import datetime, timedelta
from enum import Enum
from pathlib import Path

import pandas as pd

from .config import Config
from .consolidate import load_consolidated_data
from .logging_config import setup_logging
from .schema import Individual


class AlertLevel(str, Enum):
    CRITICAL = "CRITICAL"
    WARNING = "WARNING"
    WATCH = "WATCH"
    NONE = "NONE"


class Grade(str, Enum):
    A_PLUS = "A+"
    A = "A"
    B = "B"
    C = "C"
    D = "D"
    F = "F"


@dataclass
class MetricChange:
    """Week-over-week metric change."""
    current: float
    previous: float
    change: float
    change_pct: float
    trend: str
    grade: Grade
    alert_level: AlertLevel


@dataclass
class WeeklyAlert:
    """Alert for weekly review."""
    id: str
    severity: AlertLevel
    category: str
    metric: str
    message: str
    action: str


@dataclass
class WeeklyRecommendation:
    """Recommendation for the coming week."""
    priority: int
    category: str
    action: str
    rationale: str


@dataclass
class WeeklyReview:
    """Complete weekly review for one person."""
    person_key: str
    person_name: str
    review_date: str
    data_period: dict
    week_over_week_changes: dict
    alerts: list[WeeklyAlert]
    recommendations_for_next_week: list[WeeklyRecommendation]
    long_term_context: dict


def compute_grade(change_pct: float, higher_is_better: bool = True) -> Grade:
    """
    Compute grade based on week-over-week percentage change.

    Args:
        change_pct: Percentage change (positive = increase)
        higher_is_better: True for metrics where increase is good (e.g., HRV, sleep)
                         False for metrics where decrease is good (e.g., RHR)
    """
    # Normalize so positive change = improvement
    normalized = change_pct if higher_is_better else -change_pct

    if normalized > 15:
        return Grade.A_PLUS
    elif normalized > 10:
        return Grade.A
    elif normalized > 5:
        return Grade.B
    elif normalized > -5:
        return Grade.C
    elif normalized > -10:
        return Grade.D
    else:
        return Grade.F


def compute_alert_level(change_pct: float, higher_is_better: bool = True) -> AlertLevel:
    """Compute alert level based on week-over-week change."""
    normalized = change_pct if higher_is_better else -change_pct

    if normalized < -20:
        return AlertLevel.CRITICAL
    elif normalized < -10:
        return AlertLevel.WARNING
    elif normalized < -5:
        return AlertLevel.WATCH
    else:
        return AlertLevel.NONE


def analyze_week_over_week(
    current_week_df: pd.DataFrame,
    previous_week_df: pd.DataFrame,
    metric_col: str,
    higher_is_better: bool = True,
) -> MetricChange | None:
    """Analyze a single metric's week-over-week change."""
    current_values = current_week_df[metric_col].dropna()
    previous_values = previous_week_df[metric_col].dropna()

    if len(current_values) == 0 or len(previous_values) == 0:
        return None

    current_mean = current_values.mean()
    previous_mean = previous_values.mean()
    change = current_mean - previous_mean
    change_pct = (change / previous_mean * 100) if previous_mean != 0 else 0

    # Determine trend
    if abs(change_pct) < 2:
        trend = "stable"
    elif (change_pct > 0 and higher_is_better) or (change_pct < 0 and not higher_is_better):
        trend = "improving"
    else:
        trend = "declining"

    return MetricChange(
        current=round(current_mean, 2),
        previous=round(previous_mean, 2),
        change=round(change, 2),
        change_pct=round(change_pct, 2),
        trend=trend,
        grade=compute_grade(change_pct, higher_is_better),
        alert_level=compute_alert_level(change_pct, higher_is_better),
    )


def generate_weekly_review(
    person_key: str,
    individual: Individual,
    data: dict[str, pd.DataFrame],
    end_date: datetime | None = None,
) -> WeeklyReview:
    """Generate weekly review for one person."""
    if end_date is None:
        end_date = datetime.now()

    # Define week boundaries
    current_week_end = end_date
    current_week_start = end_date - timedelta(days=7)
    previous_week_end = current_week_start - timedelta(days=1)
    previous_week_start = previous_week_end - timedelta(days=6)

    # Get physiological data (WHOOP data includes sleep metrics in physiological)
    physio = data.get("physiological", pd.DataFrame())

    week_over_week = {}
    alerts = []
    recommendations = []

    # Determine date column - WHOOP uses "Cycle start time"
    date_col = None
    for col in ["Cycle start time", "date", "Date"]:
        if col in physio.columns:
            date_col = col
            break

    if not physio.empty and date_col:
        physio["_date"] = pd.to_datetime(physio[date_col]).dt.date
        physio["_date"] = pd.to_datetime(physio["_date"])

        current_week = physio[
            (physio["_date"] >= current_week_start) &
            (physio["_date"] <= current_week_end)
        ]
        previous_week = physio[
            (physio["_date"] >= previous_week_start) &
            (physio["_date"] <= previous_week_end)
        ]

        # Analyze cardiovascular metrics
        if "Resting heart rate (bpm)" in physio.columns:
            rhr_change = analyze_week_over_week(
                current_week, previous_week,
                "Resting heart rate (bpm)",
                higher_is_better=False  # Lower RHR is better
            )
            if rhr_change:
                week_over_week["resting_heart_rate"] = asdict(rhr_change)
                if rhr_change.alert_level in [AlertLevel.CRITICAL, AlertLevel.WARNING]:
                    alerts.append(WeeklyAlert(
                        id=f"{person_key}_rhr_{end_date.strftime('%Y%m%d')}",
                        severity=rhr_change.alert_level,
                        category="Cardiovascular",
                        metric="resting_heart_rate",
                        message=f"RHR {rhr_change.trend} by {abs(rhr_change.change_pct):.1f}% week-over-week",
                        action="Monitor stress levels and recovery"
                    ))

        if "Heart rate variability (ms)" in physio.columns:
            hrv_change = analyze_week_over_week(
                current_week, previous_week,
                "Heart rate variability (ms)",
                higher_is_better=True  # Higher HRV is better
            )
            if hrv_change:
                week_over_week["hrv"] = asdict(hrv_change)
                if hrv_change.alert_level in [AlertLevel.CRITICAL, AlertLevel.WARNING]:
                    alerts.append(WeeklyAlert(
                        id=f"{person_key}_hrv_{end_date.strftime('%Y%m%d')}",
                        severity=hrv_change.alert_level,
                        category="Recovery",
                        metric="hrv",
                        message=f"HRV {hrv_change.trend} by {abs(hrv_change.change_pct):.1f}% week-over-week",
                        action="Prioritize recovery and sleep quality"
                    ))

        if "Recovery score %" in physio.columns:
            recovery_change = analyze_week_over_week(
                current_week, previous_week,
                "Recovery score %",
                higher_is_better=True
            )
            if recovery_change:
                week_over_week["recovery"] = asdict(recovery_change)

        # Analyze sleep metrics (WHOOP includes these in physiological data)
        # Try different sleep duration column names
        sleep_col = None
        for col in ["In bed duration (min)", "Asleep duration (min)", "Total in bed time (min)"]:
            if col in physio.columns:
                sleep_col = col
                break

        if sleep_col:
            sleep_change = analyze_week_over_week(
                current_week, previous_week,
                sleep_col,
                higher_is_better=True
            )
            if sleep_change:
                week_over_week["sleep_duration"] = asdict(sleep_change)

                # Generate sleep recommendation
                if sleep_change.current < 450:  # Less than 7.5 hours
                    recommendations.append(WeeklyRecommendation(
                        priority=1,
                        category="Sleep",
                        action=f"Target {7.5 - sleep_change.current/60:.1f}+ more hours per night",
                        rationale=f"Current {sleep_change.current/60:.1f}h is below optimal 7.5-8h for your age"
                    ))

    # Compute long-term context from full data
    long_term = {
        "30_day_trend": "stable",
        "90_day_trend": "stable",
        "vs_age_benchmark": "average"
    }

    if not physio.empty and len(physio) > 30:
        recent_30 = physio.iloc[-30:]
        earlier_30 = physio.iloc[-60:-30] if len(physio) > 60 else physio.iloc[:30]

        if "Heart rate variability (ms)" in physio.columns:
            recent_hrv = recent_30["Heart rate variability (ms)"].mean()
            earlier_hrv = earlier_30["Heart rate variability (ms)"].mean()

            if recent_hrv > earlier_hrv * 1.05:
                long_term["30_day_trend"] = "improving"
            elif recent_hrv < earlier_hrv * 0.95:
                long_term["30_day_trend"] = "declining"

    return WeeklyReview(
        person_key=person_key,
        person_name=individual.name,
        review_date=end_date.strftime("%Y-%m-%d"),
        data_period={
            "current_week": {
                "start": current_week_start.strftime("%Y-%m-%d"),
                "end": current_week_end.strftime("%Y-%m-%d")
            },
            "previous_week": {
                "start": previous_week_start.strftime("%Y-%m-%d"),
                "end": previous_week_end.strftime("%Y-%m-%d")
            }
        },
        week_over_week_changes=week_over_week,
        alerts=alerts,
        recommendations_for_next_week=recommendations,
        long_term_context=long_term
    )


def run_weekly_analysis(
    config: Config,
    person_key: str | None = None,
    end_date: datetime | None = None,
    output_dir: Path | None = None,
) -> dict[str, WeeklyReview]:
    """Run weekly analysis for all or specific individuals."""
    logger = setup_logging()

    if output_dir is None:
        output_dir = Path("analysis/weekly")
    output_dir.mkdir(parents=True, exist_ok=True)

    # Determine which individuals to analyze
    individuals = config.individuals
    if person_key:
        if person_key not in individuals:
            raise ValueError(f"Unknown person: {person_key}")
        individuals = {person_key: individuals[person_key]}

    reviews = {}

    # Load all consolidated data upfront
    all_data = load_consolidated_data(config)

    for key, individual in individuals.items():
        logger.info(f"Generating weekly review for {individual.name}")

        # Get data for this person
        if key not in all_data:
            logger.warning(f"No consolidated data for {key}")
            continue

        data = all_data[key]
        review = generate_weekly_review(key, individual, data, end_date)
        reviews[key] = review

        # Save individual review
        output_file = output_dir / f"weekly_review_{key}_{review.review_date}.json"
        with open(output_file, "w") as f:
            json.dump(asdict(review), f, indent=2, default=str)

        logger.info(f"Saved weekly review to {output_file}")

        # Print summary
        print(f"\n{'='*60}")
        print(f"Weekly Review: {individual.name}")
        print(f"Period: {review.data_period['current_week']['start']} to {review.data_period['current_week']['end']}")
        print(f"{'='*60}")

        if review.alerts:
            print("\n🚨 ALERTS:")
            for alert in review.alerts:
                print(f"  [{alert.severity.value}] {alert.message}")
                print(f"    → {alert.action}")

        if review.week_over_week_changes:
            print("\n📊 Week-over-Week Changes:")
            for metric, change in review.week_over_week_changes.items():
                sign = "+" if change["change"] > 0 else ""
                print(f"  {metric}: {change['previous']} → {change['current']} ({sign}{change['change_pct']:.1f}%) [{change['grade']}]")

        if review.recommendations_for_next_week:
            print("\n📋 Recommendations for Next Week:")
            for rec in review.recommendations_for_next_week:
                print(f"  {rec.priority}. [{rec.category}] {rec.action}")
                print(f"     Rationale: {rec.rationale}")

    return reviews


def main():
    """CLI entry point for weekly analysis."""
    parser = argparse.ArgumentParser(description="Generate weekly health analysis")
    parser.add_argument("--person", "-p", help="Analyze specific person (key)")
    parser.add_argument("--end-date", "-e", help="End date for analysis (YYYY-MM-DD)")
    parser.add_argument("--output", "-o", help="Output directory", default="analysis/weekly")
    parser.add_argument("--compare-weeks", "-c", type=int, help="Number of weeks to compare")

    args = parser.parse_args()

    # Determine base path (project root)
    base_path = Path(__file__).parent.parent
    config = Config(base_path)

    end_date = None
    if args.end_date:
        end_date = datetime.strptime(args.end_date, "%Y-%m-%d")

    output_dir = Path(args.output)

    run_weekly_analysis(
        config=config,
        person_key=args.person,
        end_date=end_date,
        output_dir=output_dir,
    )


if __name__ == "__main__":
    main()
