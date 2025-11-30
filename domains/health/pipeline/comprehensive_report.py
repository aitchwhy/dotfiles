"""
Comprehensive report generation module.

Generates consolidated PDF reports with embedded visualizations:
- One comprehensive report per person
- One family summary report

Medical benchmarks are cited from:
- American Heart Association (AHA) 2024 Guidelines
- National Sleep Foundation 2024 Guidelines
- AASM Sleep Medicine Guidelines 2024
- WHO Physical Activity Guidelines 2024
"""

from datetime import datetime
from pathlib import Path

import matplotlib.dates as mdates
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.backends.backend_pdf import PdfPages

from .config import Config
from .schema import HealthProfile, Individual

# Medical benchmarks with citations
BENCHMARKS_CITATIONS = {
    "rhr": {
        "source": "American Heart Association (AHA) 2024",
        "url": "https://www.heart.org/en/health-topics/high-blood-pressure/understanding-blood-pressure-readings",
        "ranges": {
            "excellent": {"male": (40, 54), "female": (42, 56)},
            "good": {"male": (55, 64), "female": (57, 66)},
            "average": {"male": (65, 74), "female": (67, 76)},
            "above_average": {"male": (75, 84), "female": (77, 86)},
            "poor": {"male": (85, 200), "female": (87, 200)},
        },
    },
    "hrv": {
        "source": "Whoop & Clinical Studies Meta-Analysis 2024",
        "url": "https://www.whoop.com/us/en/thelocker/heart-rate-variability-hrv/",
        "ranges_by_age": {
            "20-29": {"excellent": (60, 200), "good": (45, 59), "below_average": (25, 44)},
            "30-39": {"excellent": (55, 200), "good": (40, 54), "below_average": (20, 39)},
            "40-49": {"excellent": (50, 200), "good": (35, 49), "below_average": (15, 34)},
            "50-59": {"excellent": (45, 200), "good": (30, 44), "below_average": (12, 29)},
            "60-69": {"excellent": (40, 200), "good": (25, 39), "below_average": (10, 24)},
            "70+": {"excellent": (35, 200), "good": (20, 34), "below_average": (8, 19)},
        },
    },
    "spo2": {
        "source": "WHO & CDC Pulse Oximetry Guidelines 2024",
        "url": "https://www.cdc.gov/healthyweight/assessing/pulse-oximetry.html",
        "ranges": {
            "normal": (95, 100),
            "low": (90, 94),
            "concerning": (0, 89),
        },
    },
    "sleep": {
        "source": "National Sleep Foundation 2024",
        "url": "https://www.sleepfoundation.org/how-sleep-works/how-much-sleep-do-we-really-need",
        "duration_by_age": {
            "18-64": {"optimal": (7, 9), "acceptable": (6, 10), "short": (0, 6)},
            "65+": {"optimal": (7, 8), "acceptable": (6, 9), "short": (0, 6)},
        },
        "architecture": {
            "deep_sleep_pct": {"excellent": (20, 25), "good": (15, 20), "low": (0, 15)},
            "rem_sleep_pct": {"excellent": (20, 25), "good": (15, 20), "low": (0, 15)},
        },
    },
    "respiratory_rate": {
        "source": "Clinical Guidelines (Cleveland Clinic 2024)",
        "url": "https://my.clevelandclinic.org/health/symptoms/respiratory-rate",
        "ranges": {
            "optimal": (12, 16),
            "acceptable": (10, 20),
            "elevated": (20, 30),
        },
    },
}


def setup_style():
    """Configure matplotlib style for reports."""
    plt.style.use("seaborn-v0_8-whitegrid")
    plt.rcParams["figure.figsize"] = (11, 8.5)  # Letter size
    plt.rcParams["font.size"] = 9
    plt.rcParams["axes.titlesize"] = 11
    plt.rcParams["axes.labelsize"] = 9


def get_baseline_comparison(
    value: float,
    metric: str,
    individual: Individual,
) -> dict:
    """Compare a value against baseline for the individual's demographic."""
    result = {"value": value, "category": "unknown", "vs_baseline": "N/A"}

    if metric == "rhr":
        ranges = BENCHMARKS_CITATIONS["rhr"]["ranges"]
        gender = individual.gender
        for category, bounds in ranges.items():
            low, high = bounds.get(gender, bounds.get("male", (0, 200)))
            if low <= value <= high:
                result["category"] = category
                break
        # Calculate vs median for age/gender
        if individual.age < 50:
            median = 62 if gender == "male" else 64
        else:
            median = 68 if gender == "male" else 70
        diff = value - median
        result["vs_baseline"] = f"{diff:+.0f} bpm vs median"

    elif metric == "hrv":
        age_bracket = individual.age_bracket
        ranges = BENCHMARKS_CITATIONS["hrv"]["ranges_by_age"].get(age_bracket, {})
        for category, bounds in ranges.items():
            low, high = bounds
            if low <= value <= high:
                result["category"] = category
                break
        # vs age median
        medians = {"20-29": 55, "30-39": 45, "40-49": 40, "50-59": 35, "60-69": 30, "70+": 25}
        median = medians.get(age_bracket, 40)
        diff = value - median
        result["vs_baseline"] = f"{diff:+.0f} ms vs age median"

    elif metric == "spo2":
        if value >= 95:
            result["category"] = "normal"
        elif value >= 90:
            result["category"] = "low"
        else:
            result["category"] = "concerning"
        result["vs_baseline"] = "95%+ is normal"

    elif metric == "sleep_duration":
        if value >= 7:
            result["category"] = "optimal"
        elif value >= 6:
            result["category"] = "acceptable"
        else:
            result["category"] = "short"
        result["vs_baseline"] = "7-9 hrs recommended"

    return result


def create_individual_pdf(
    key: str,
    profile: HealthProfile,
    data: dict[str, pd.DataFrame],
    previous_context: dict | None,
    output_path: Path,
    config: Config,  # noqa: ARG001 - reserved for future style config
) -> str:
    """Create comprehensive PDF report for an individual."""
    setup_style()
    individual = profile.individual
    pdf_path = output_path / f"report_{key}.pdf"

    with PdfPages(pdf_path) as pdf:
        # Page 1: Cover & Executive Summary
        fig = plt.figure(figsize=(11, 8.5))
        fig.suptitle(
            f"Health Analysis Report: {individual.name}",
            fontsize=18,
            fontweight="bold",
            y=0.95,
        )

        # Summary box
        ax = fig.add_subplot(111)
        ax.axis("off")

        summary_text = f"""
EXECUTIVE SUMMARY
{"=" * 60}

Name: {individual.name}
Age: {individual.age} years ({individual.age_bracket} bracket)
Gender: {individual.gender.title()}
Analysis Period: {profile.data_range.start} to {profile.data_range.end} ({profile.data_range.days} days)
Generated: {datetime.now().strftime("%Y-%m-%d %H:%M")}

HEALTH SCORES
{"─" * 40}
Overall Score: {profile.health_scores.overall:.0f}/100 {"(Good)" if profile.health_scores.overall >= 80 else "(Moderate)" if profile.health_scores.overall >= 60 else "(Needs Attention)"}

  Cardiovascular: {profile.health_scores.cardiovascular:.0f}/100
  Respiratory:    {profile.health_scores.respiratory:.0f}/100
  Sleep:          {profile.health_scores.sleep:.0f}/100
  Recovery:       {profile.health_scores.recovery:.0f}/100
  Activity:       {profile.health_scores.activity:.0f}/100

TOP RECOMMENDATIONS
{"─" * 40}
"""
        for i, rec in enumerate(profile.recommendations[:3], 1):
            summary_text += f"{i}. [{rec.priority.value}] {rec.category}: {rec.action[:60]}...\n"

        if not profile.recommendations:
            summary_text += "No urgent recommendations at this time.\n"

        ax.text(
            0.05,
            0.95,
            summary_text,
            transform=ax.transAxes,
            fontsize=10,
            verticalalignment="top",
            fontfamily="monospace",
        )
        pdf.savefig(fig, bbox_inches="tight")
        plt.close()

        # Page 2: Cardiovascular Dashboard
        df = data.get("physiological")
        if df is not None:
            df_sorted = df.sort_values("Cycle start time")

            fig = plt.figure(figsize=(11, 8.5))
            fig.suptitle("Cardiovascular Health", fontsize=14, fontweight="bold")

            # HRV plot
            ax1 = fig.add_subplot(2, 2, 1)
            hrv = df_sorted["Heart rate variability (ms)"].dropna()
            dates = df_sorted.loc[hrv.index, "Cycle start time"]
            ax1.scatter(dates, hrv, alpha=0.3, s=8, color=individual.color)
            rolling = hrv.rolling(window=30, min_periods=7).mean()
            ax1.plot(dates, rolling, color="black", linewidth=2, label="30-day avg")

            # Add baseline reference
            hrv_baseline = get_baseline_comparison(
                profile.cardiovascular.hrv_mean, "hrv", individual
            )
            ax1.axhline(
                y=profile.cardiovascular.hrv_mean,
                color="blue",
                linestyle="--",
                alpha=0.7,
                label=f"Your avg: {profile.cardiovascular.hrv_mean:.0f}ms ({hrv_baseline['category']})",
            )
            ax1.set_title(f"HRV - {hrv_baseline['vs_baseline']}")
            ax1.set_ylabel("ms")
            ax1.legend(fontsize=8)

            # RHR plot
            ax2 = fig.add_subplot(2, 2, 2)
            rhr = df_sorted["Resting heart rate (bpm)"].dropna()
            dates_rhr = df_sorted.loc[rhr.index, "Cycle start time"]
            ax2.scatter(dates_rhr, rhr, alpha=0.3, s=8, color=individual.color)
            rolling_rhr = rhr.rolling(window=30, min_periods=7).mean()
            ax2.plot(dates_rhr, rolling_rhr, color="black", linewidth=2, label="30-day avg")

            rhr_baseline = get_baseline_comparison(
                profile.cardiovascular.rhr_mean, "rhr", individual
            )
            ax2.axhline(
                y=profile.cardiovascular.rhr_mean,
                color="red",
                linestyle="--",
                alpha=0.7,
                label=f"Your avg: {profile.cardiovascular.rhr_mean:.0f}bpm ({rhr_baseline['category']})",
            )
            ax2.set_title(f"Resting Heart Rate - {rhr_baseline['vs_baseline']}")
            ax2.set_ylabel("bpm")
            ax2.legend(fontsize=8)

            # Trend comparison if previous data exists
            ax3 = fig.add_subplot(2, 2, 3)
            prev_data = None
            if previous_context:
                prev_ind = previous_context.get("individuals", {}).get(key)
                if prev_ind:
                    prev_data = prev_ind.get("key_metrics", {})

            metrics = ["RHR", "HRV"]
            current = [profile.cardiovascular.rhr_mean, profile.cardiovascular.hrv_mean]
            x = np.arange(len(metrics))
            ax3.bar(x, current, color=individual.color, alpha=0.8, label="Current")

            if prev_data:
                previous = [
                    prev_data.get("rhr_mean", current[0]),
                    prev_data.get("hrv_mean", current[1]),
                ]
                ax3.bar(x + 0.35, previous, width=0.35, color="gray", alpha=0.5, label="Previous")

            ax3.set_xticks(x)
            ax3.set_xticklabels(metrics)
            ax3.set_title("Current vs Previous Analysis")
            ax3.legend()

            # CV Score gauge
            ax4 = fig.add_subplot(2, 2, 4)
            score = profile.health_scores.cardiovascular
            colors = ["red", "orange", "yellow", "lightgreen", "green"]
            bounds = [0, 40, 60, 70, 85, 100]
            for i in range(len(bounds) - 1):
                ax4.barh(
                    0,
                    bounds[i + 1] - bounds[i],
                    left=bounds[i],
                    height=0.5,
                    color=colors[i],
                    alpha=0.6,
                )
            ax4.axvline(x=score, color="black", linewidth=3)
            ax4.set_xlim(0, 100)
            ax4.set_ylim(-0.5, 0.5)
            ax4.set_title(f"Cardiovascular Score: {score:.0f}/100")
            ax4.set_yticks([])

            plt.tight_layout(rect=[0, 0.03, 1, 0.95])
            pdf.savefig(fig, bbox_inches="tight")
            plt.close()

            # Page 3: Sleep Dashboard
            fig = plt.figure(figsize=(11, 8.5))
            fig.suptitle("Sleep Health", fontsize=14, fontweight="bold")

            # Sleep duration
            ax1 = fig.add_subplot(2, 2, 1)
            sleep_hrs = df_sorted["Asleep duration (min)"].dropna() / 60
            dates_sleep = df_sorted.loc[sleep_hrs.index, "Cycle start time"]
            ax1.scatter(dates_sleep, sleep_hrs, alpha=0.3, s=8, color=individual.color)
            rolling_sleep = sleep_hrs.rolling(window=30, min_periods=7).mean()
            ax1.plot(dates_sleep, rolling_sleep, color="black", linewidth=2, label="30-day avg")
            ax1.axhline(y=7, color="green", linestyle="--", alpha=0.5, label="7hr minimum")
            ax1.axhline(y=9, color="green", linestyle="--", alpha=0.5, label="9hr max optimal")

            sleep_baseline = get_baseline_comparison(
                profile.sleep.duration_hours, "sleep_duration", individual
            )
            ax1.set_title(f"Sleep Duration - {sleep_baseline['category'].title()}")
            ax1.set_ylabel("hours")
            ax1.legend(fontsize=8)

            # Sleep architecture pie
            ax2 = fig.add_subplot(2, 2, 2)
            labels = [
                f"Deep\n{profile.sleep.deep_sleep_pct:.1f}%",
                f"REM\n{profile.sleep.rem_sleep_pct:.1f}%",
                f"Light\n{100 - profile.sleep.deep_sleep_pct - profile.sleep.rem_sleep_pct - (profile.sleep.awake_min / profile.sleep.duration_min * 100):.1f}%",
                f"Awake\n{profile.sleep.awake_min / profile.sleep.duration_min * 100:.1f}%",
            ]
            sizes = [
                profile.sleep.deep_sleep_min,
                profile.sleep.rem_sleep_min,
                profile.sleep.light_sleep_min,
                profile.sleep.awake_min,
            ]
            colors = ["#2c3e50", "#9b59b6", "#3498db", "#e74c3c"]
            ax2.pie(sizes, labels=labels, colors=colors, autopct="", startangle=90)
            ax2.set_title("Sleep Architecture")

            # Sleep efficiency trend
            ax3 = fig.add_subplot(2, 2, 3)
            efficiency = df_sorted["Sleep efficiency %"].dropna()
            dates_eff = df_sorted.loc[efficiency.index, "Cycle start time"]
            ax3.scatter(dates_eff, efficiency, alpha=0.3, s=8, color=individual.color)
            rolling_eff = efficiency.rolling(window=30, min_periods=7).mean()
            ax3.plot(dates_eff, rolling_eff, color="black", linewidth=2, label="30-day avg")
            ax3.axhline(y=85, color="green", linestyle="--", alpha=0.5, label="85% target")
            ax3.set_title(f"Sleep Efficiency - Avg: {profile.sleep.efficiency:.1f}%")
            ax3.set_ylabel("%")
            ax3.legend(fontsize=8)

            # Sleep score gauge
            ax4 = fig.add_subplot(2, 2, 4)
            score = profile.health_scores.sleep
            for low, high, color in [
                (0, 40, "red"),
                (40, 60, "orange"),
                (60, 70, "yellow"),
                (70, 85, "lightgreen"),
                (85, 100, "green"),
            ]:
                ax4.barh(0, high - low, left=low, height=0.5, color=color, alpha=0.6)
            ax4.axvline(x=score, color="black", linewidth=3)
            ax4.set_xlim(0, 100)
            ax4.set_ylim(-0.5, 0.5)
            ax4.set_title(f"Sleep Score: {score:.0f}/100")
            ax4.set_yticks([])

            plt.tight_layout(rect=[0, 0.03, 1, 0.95])
            pdf.savefig(fig, bbox_inches="tight")
            plt.close()

            # Page 4: Recovery & Activity
            fig = plt.figure(figsize=(11, 8.5))
            fig.suptitle("Recovery & Activity", fontsize=14, fontweight="bold")

            # Recovery trend
            ax1 = fig.add_subplot(2, 2, 1)
            recovery = df_sorted["Recovery score %"].dropna()
            dates_rec = df_sorted.loc[recovery.index, "Cycle start time"]
            colors_rec = ["green" if v >= 67 else "gold" if v >= 33 else "red" for v in recovery]
            ax1.scatter(dates_rec, recovery, c=colors_rec, alpha=0.5, s=8)
            rolling_rec = recovery.rolling(window=30, min_periods=7).mean()
            ax1.plot(dates_rec, rolling_rec, color="black", linewidth=2, label="30-day avg")
            ax1.axhline(y=67, color="green", linestyle="--", alpha=0.5)
            ax1.axhline(y=33, color="red", linestyle="--", alpha=0.5)
            ax1.set_title(f"Recovery Score - Avg: {profile.recovery.recovery_mean:.0f}%")
            ax1.set_ylabel("%")
            ax1.legend(fontsize=8)

            # Recovery distribution
            ax2 = fig.add_subplot(2, 2, 2)
            ax2.bar(
                ["Green\n(67-100%)", "Yellow\n(33-66%)", "Red\n(0-32%)"],
                [profile.recovery.green_pct, profile.recovery.yellow_pct, profile.recovery.red_pct],
                color=["green", "gold", "red"],
            )
            ax2.set_ylabel("%")
            ax2.set_title("Recovery Distribution")

            # Strain trend
            ax3 = fig.add_subplot(2, 2, 3)
            strain = df_sorted["Day Strain"].dropna()
            dates_strain = df_sorted.loc[strain.index, "Cycle start time"]
            ax3.scatter(dates_strain, strain, alpha=0.3, s=8, color=individual.color)
            rolling_strain = strain.rolling(window=30, min_periods=7).mean()
            ax3.plot(dates_strain, rolling_strain, color="black", linewidth=2, label="30-day avg")
            ax3.axhline(y=14, color="orange", linestyle="--", alpha=0.5, label="High strain")
            ax3.set_title(f"Day Strain - Avg: {profile.recovery.strain_mean:.1f}")
            ax3.set_ylabel("Strain (0-21)")
            ax3.legend(fontsize=8)

            # Activity mix
            ax4 = fig.add_subplot(2, 2, 4)
            activity_labels = ["Light", "Moderate", "High", "All-out"]
            activity_values = [
                profile.recovery.light_pct,
                profile.recovery.moderate_pct,
                profile.recovery.high_pct,
                profile.recovery.all_out_pct,
            ]
            ax4.pie(
                activity_values,
                labels=[
                    f"{label}\n{val:.0f}%"
                    for label, val in zip(activity_labels, activity_values, strict=True)
                ],
                colors=["lightblue", "orange", "red", "darkred"],
                startangle=90,
            )
            ax4.set_title("Activity Intensity Mix")

            plt.tight_layout(rect=[0, 0.03, 1, 0.95])
            pdf.savefig(fig, bbox_inches="tight")
            plt.close()

            # Page 5: Respiratory Health
            fig = plt.figure(figsize=(11, 8.5))
            fig.suptitle("Respiratory Health", fontsize=14, fontweight="bold")

            # SpO2 trend
            ax1 = fig.add_subplot(2, 2, 1)
            spo2 = df_sorted["Blood oxygen %"].dropna()
            dates_spo2 = df_sorted.loc[spo2.index, "Cycle start time"]
            colors_spo2 = ["red" if v < 95 else "green" for v in spo2]
            ax1.scatter(dates_spo2, spo2, c=colors_spo2, alpha=0.5, s=8)
            rolling_spo2 = spo2.rolling(window=30, min_periods=7).mean()
            ax1.plot(dates_spo2, rolling_spo2, color="black", linewidth=2, label="30-day avg")
            ax1.axhline(y=95, color="orange", linestyle="--", alpha=0.5, label="95% threshold")
            ax1.set_title(f"Blood Oxygen (SpO2) - Avg: {profile.respiratory.spo2_mean:.1f}%")
            ax1.set_ylabel("%")
            ax1.legend(fontsize=8)

            # Low SpO2 readings
            ax2 = fig.add_subplot(2, 2, 2)
            low_count = profile.respiratory.low_readings_count
            normal_count = len(spo2) - low_count
            ax2.pie(
                [normal_count, low_count],
                labels=["Normal\n(>=95%)", "Low\n(<95%)"],
                colors=["green", "red"],
                autopct="%1.1f%%",
                startangle=90,
            )
            ax2.set_title(f"SpO2 Distribution ({profile.respiratory.low_readings_pct:.1f}% low)")

            # Respiratory rate
            ax3 = fig.add_subplot(2, 2, 3)
            if "Respiratory rate (rpm)" in df_sorted.columns:
                rr = df_sorted["Respiratory rate (rpm)"].dropna()
                dates_rr = df_sorted.loc[rr.index, "Cycle start time"]
                ax3.scatter(dates_rr, rr, alpha=0.3, s=8, color=individual.color)
                rolling_rr = rr.rolling(window=30, min_periods=7).mean()
                ax3.plot(dates_rr, rolling_rr, color="black", linewidth=2, label="30-day avg")
                ax3.axhline(y=12, color="green", linestyle="--", alpha=0.5)
                ax3.axhline(y=16, color="green", linestyle="--", alpha=0.5)
                ax3.set_title(f"Respiratory Rate - Avg: {profile.respiratory.rr_mean:.1f} rpm")
                ax3.set_ylabel("breaths/min")
                ax3.legend(fontsize=8)

            # Respiratory score gauge
            ax4 = fig.add_subplot(2, 2, 4)
            score = profile.health_scores.respiratory
            for low, high, color in [
                (0, 40, "red"),
                (40, 60, "orange"),
                (60, 70, "yellow"),
                (70, 85, "lightgreen"),
                (85, 100, "green"),
            ]:
                ax4.barh(0, high - low, left=low, height=0.5, color=color, alpha=0.6)
            ax4.axvline(x=score, color="black", linewidth=3)
            ax4.set_xlim(0, 100)
            ax4.set_ylim(-0.5, 0.5)
            ax4.set_title(f"Respiratory Score: {score:.0f}/100")
            ax4.set_yticks([])

            plt.tight_layout(rect=[0, 0.03, 1, 0.95])
            pdf.savefig(fig, bbox_inches="tight")
            plt.close()

            # Page 6: Correlations
            fig = plt.figure(figsize=(11, 8.5))
            fig.suptitle("Correlation Analysis", fontsize=14, fontweight="bold")

            # HRV vs Recovery
            ax1 = fig.add_subplot(2, 2, 1)
            hrv = df["Heart rate variability (ms)"].dropna()
            rec = df.loc[hrv.index, "Recovery score %"]
            mask = ~(hrv.isna() | rec.isna())
            if mask.sum() > 10:
                ax1.scatter(hrv[mask], rec[mask], alpha=0.4, c=individual.color)
                z = np.polyfit(hrv[mask], rec[mask], 1)
                p = np.poly1d(z)
                ax1.plot(hrv[mask].sort_values(), p(hrv[mask].sort_values()), "r--", alpha=0.8)
                corr = np.corrcoef(hrv[mask], rec[mask])[0, 1]
                ax1.set_title(f"HRV vs Recovery (r={corr:.2f})")
            ax1.set_xlabel("HRV (ms)")
            ax1.set_ylabel("Recovery %")

            # Sleep vs Recovery
            ax2 = fig.add_subplot(2, 2, 2)
            sleep = df["Asleep duration (min)"].dropna() / 60
            rec = df.loc[sleep.index, "Recovery score %"]
            mask = ~(sleep.isna() | rec.isna())
            if mask.sum() > 10:
                ax2.scatter(sleep[mask], rec[mask], alpha=0.4, c=individual.color)
                z = np.polyfit(sleep[mask], rec[mask], 1)
                p = np.poly1d(z)
                ax2.plot(sleep[mask].sort_values(), p(sleep[mask].sort_values()), "r--", alpha=0.8)
                corr = np.corrcoef(sleep[mask], rec[mask])[0, 1]
                ax2.set_title(f"Sleep vs Recovery (r={corr:.2f})")
            ax2.set_xlabel("Sleep (hours)")
            ax2.set_ylabel("Recovery %")

            # Strain vs Next Recovery
            ax3 = fig.add_subplot(2, 2, 3)
            strain = df["Day Strain"].dropna()
            next_rec = df["Recovery score %"].shift(-1).loc[strain.index]
            mask = ~(strain.isna() | next_rec.isna())
            if mask.sum() > 10:
                ax3.scatter(strain[mask], next_rec[mask], alpha=0.4, c=individual.color)
                z = np.polyfit(strain[mask], next_rec[mask], 1)
                p = np.poly1d(z)
                ax3.plot(
                    strain[mask].sort_values(), p(strain[mask].sort_values()), "r--", alpha=0.8
                )
                corr = np.corrcoef(strain[mask], next_rec[mask])[0, 1]
                ax3.set_title(f"Strain vs Next Day Recovery (r={corr:.2f})")
            ax3.set_xlabel("Day Strain")
            ax3.set_ylabel("Next Day Recovery %")

            # Deep Sleep vs Recovery
            ax4 = fig.add_subplot(2, 2, 4)
            deep = df["Deep (SWS) duration (min)"].dropna()
            rec = df.loc[deep.index, "Recovery score %"]
            mask = ~(deep.isna() | rec.isna())
            if mask.sum() > 10:
                ax4.scatter(deep[mask], rec[mask], alpha=0.4, c=individual.color)
                z = np.polyfit(deep[mask], rec[mask], 1)
                p = np.poly1d(z)
                ax4.plot(deep[mask].sort_values(), p(deep[mask].sort_values()), "r--", alpha=0.8)
                corr = np.corrcoef(deep[mask], rec[mask])[0, 1]
                ax4.set_title(f"Deep Sleep vs Recovery (r={corr:.2f})")
            ax4.set_xlabel("Deep Sleep (min)")
            ax4.set_ylabel("Recovery %")

            plt.tight_layout(rect=[0, 0.03, 1, 0.95])
            pdf.savefig(fig, bbox_inches="tight")
            plt.close()

        # Page 7: Recommendations & Alerts
        fig = plt.figure(figsize=(11, 8.5))
        ax = fig.add_subplot(111)
        ax.axis("off")

        rec_text = f"""
RECOMMENDATIONS & ALERTS
{"=" * 60}

"""
        if profile.alerts:
            rec_text += "ACTIVE ALERTS\n" + "─" * 40 + "\n"
            for alert in profile.alerts:
                rec_text += f"[{alert.severity.value.upper()}] {alert.message}\n"
            rec_text += "\n"

        if profile.recommendations:
            rec_text += "RECOMMENDATIONS\n" + "─" * 40 + "\n\n"
            for rec in profile.recommendations:
                rec_text += f"[{rec.priority.value}] {rec.category}\n"
                rec_text += f"  Finding: {rec.finding}\n"
                rec_text += f"  Action: {rec.action}\n"
                rec_text += f"  Note: {rec.medical_note}\n\n"
        else:
            rec_text += "No recommendations at this time. Keep up the good work!\n"

        rec_text += f"""

METHODOLOGY & CITATIONS
{"─" * 40}
This analysis uses medical benchmarks from:
- {BENCHMARKS_CITATIONS["rhr"]["source"]}: {BENCHMARKS_CITATIONS["rhr"]["url"]}
- {BENCHMARKS_CITATIONS["hrv"]["source"]}
- {BENCHMARKS_CITATIONS["spo2"]["source"]}
- {BENCHMARKS_CITATIONS["sleep"]["source"]}
- {BENCHMARKS_CITATIONS["respiratory_rate"]["source"]}

For medical decisions, please consult with healthcare providers.
"""

        ax.text(
            0.05,
            0.95,
            rec_text,
            transform=ax.transAxes,
            fontsize=9,
            verticalalignment="top",
            fontfamily="monospace",
        )
        pdf.savefig(fig, bbox_inches="tight")
        plt.close()

    return f"report_{key}.pdf"


def create_summary_pdf(
    profiles: dict[str, HealthProfile],
    all_data: dict[str, dict[str, pd.DataFrame]],
    previous_context: dict | None,  # noqa: ARG001 - reserved for future trend comparison
    output_path: Path,
    config: Config,
    snapshot_id: str,
) -> str:
    """Create family summary PDF report."""
    setup_style()
    pdf_path = output_path / "summary_report.pdf"

    with PdfPages(pdf_path) as pdf:
        # Page 1: Cover & Overview
        fig = plt.figure(figsize=(11, 8.5))
        fig.suptitle("Family Health Summary Report", fontsize=18, fontweight="bold", y=0.95)

        ax = fig.add_subplot(111)
        ax.axis("off")

        summary_text = f"""
FAMILY HEALTH OVERVIEW
{"=" * 60}

Snapshot ID: {snapshot_id}
Generated: {datetime.now().strftime("%Y-%m-%d %H:%M")}
Individuals: {len(profiles)}

HEALTH SCORES SUMMARY
{"─" * 40}
{"Person":<25} {"Age":<6} {"Overall":<10} {"CV":<8} {"Sleep":<8} {"Recovery":<10}
{"─" * 40}
"""
        for _key, profile in profiles.items():
            ind = profile.individual
            scores = profile.health_scores
            summary_text += f"{ind.name:<25} {ind.age:<6} {scores.overall:>6.0f}    {scores.cardiovascular:>5.0f}   {scores.sleep:>5.0f}    {scores.recovery:>6.0f}\n"

        summary_text += f"""

TOP FAMILY CONCERNS
{"─" * 40}
"""
        # Aggregate concerns
        all_recs = []
        for _key, profile in profiles.items():
            for rec in profile.recommendations:
                if rec.priority.value == "HIGH":
                    all_recs.append((profile.individual.name, rec.category, rec.finding))

        for name, category, finding in all_recs[:5]:
            summary_text += f"- {name}: {category} - {finding[:50]}...\n"

        if not all_recs:
            summary_text += "No high-priority concerns across the family.\n"

        ax.text(
            0.05,
            0.95,
            summary_text,
            transform=ax.transAxes,
            fontsize=10,
            verticalalignment="top",
            fontfamily="monospace",
        )
        pdf.savefig(fig, bbox_inches="tight")
        plt.close()

        # Page 2: Health Score Comparison
        fig = plt.figure(figsize=(11, 8.5))
        fig.suptitle("Health Score Comparison", fontsize=14, fontweight="bold")

        categories = ["Overall", "Cardiovascular", "Sleep", "Recovery", "Activity", "Respiratory"]
        x = np.arange(len(categories))
        width = 0.15

        ax = fig.add_subplot(111)
        for idx, (_key, profile) in enumerate(profiles.items()):
            scores = profile.health_scores
            values = [
                scores.overall,
                scores.cardiovascular,
                scores.sleep,
                scores.recovery,
                scores.activity,
                scores.respiratory,
            ]
            ax.bar(
                x + idx * width,
                values,
                width,
                label=profile.individual.name,
                color=profile.individual.color,
                alpha=0.8,
            )

        ax.set_ylabel("Score (0-100)")
        ax.set_xticks(x + width * (len(profiles) - 1) / 2)
        ax.set_xticklabels(categories)
        ax.legend(loc="upper right")
        ax.set_ylim(0, 110)
        ax.axhline(y=80, linestyle="--", color="green", alpha=0.3, label="Good")
        ax.axhline(y=60, linestyle="--", color="orange", alpha=0.3, label="Moderate")

        plt.tight_layout()
        pdf.savefig(fig, bbox_inches="tight")
        plt.close()

        # Page 3: Trend Comparisons
        fig = plt.figure(figsize=(11, 8.5))
        fig.suptitle("Key Metric Trends", fontsize=14, fontweight="bold")

        # HRV comparison
        ax1 = fig.add_subplot(2, 2, 1)
        for key, data in all_data.items():
            df = data.get("physiological")
            if df is None:
                continue
            ind = config.individuals[key]
            df_sorted = df.sort_values("Cycle start time")
            hrv = df_sorted["Heart rate variability (ms)"].dropna()
            rolling = hrv.rolling(window=30, min_periods=7).mean()
            ax1.plot(
                df_sorted.loc[hrv.index, "Cycle start time"],
                rolling,
                label=ind.name,
                color=ind.color,
                linewidth=2,
            )
        ax1.set_title("HRV Trends (30-day avg)")
        ax1.set_ylabel("ms")
        ax1.legend(fontsize=8)
        ax1.xaxis.set_major_formatter(mdates.DateFormatter("%Y-%m"))
        plt.setp(ax1.xaxis.get_majorticklabels(), rotation=45)

        # RHR comparison
        ax2 = fig.add_subplot(2, 2, 2)
        for key, data in all_data.items():
            df = data.get("physiological")
            if df is None:
                continue
            ind = config.individuals[key]
            df_sorted = df.sort_values("Cycle start time")
            rhr = df_sorted["Resting heart rate (bpm)"].dropna()
            rolling = rhr.rolling(window=30, min_periods=7).mean()
            ax2.plot(
                df_sorted.loc[rhr.index, "Cycle start time"],
                rolling,
                label=ind.name,
                color=ind.color,
                linewidth=2,
            )
        ax2.set_title("Resting Heart Rate Trends")
        ax2.set_ylabel("bpm")
        ax2.legend(fontsize=8)
        ax2.xaxis.set_major_formatter(mdates.DateFormatter("%Y-%m"))
        plt.setp(ax2.xaxis.get_majorticklabels(), rotation=45)

        # Sleep comparison
        ax3 = fig.add_subplot(2, 2, 3)
        for key, data in all_data.items():
            df = data.get("physiological")
            if df is None:
                continue
            ind = config.individuals[key]
            df_sorted = df.sort_values("Cycle start time")
            sleep = df_sorted["Asleep duration (min)"].dropna() / 60
            rolling = sleep.rolling(window=30, min_periods=7).mean()
            ax3.plot(
                df_sorted.loc[sleep.index, "Cycle start time"],
                rolling,
                label=ind.name,
                color=ind.color,
                linewidth=2,
            )
        ax3.axhline(y=7, color="green", linestyle="--", alpha=0.5)
        ax3.set_title("Sleep Duration Trends")
        ax3.set_ylabel("hours")
        ax3.legend(fontsize=8)
        ax3.xaxis.set_major_formatter(mdates.DateFormatter("%Y-%m"))
        plt.setp(ax3.xaxis.get_majorticklabels(), rotation=45)

        # Recovery comparison
        ax4 = fig.add_subplot(2, 2, 4)
        for key, data in all_data.items():
            df = data.get("physiological")
            if df is None:
                continue
            ind = config.individuals[key]
            df_sorted = df.sort_values("Cycle start time")
            rec = df_sorted["Recovery score %"].dropna()
            rolling = rec.rolling(window=30, min_periods=7).mean()
            ax4.plot(
                df_sorted.loc[rec.index, "Cycle start time"],
                rolling,
                label=ind.name,
                color=ind.color,
                linewidth=2,
            )
        ax4.axhline(y=67, color="green", linestyle="--", alpha=0.5)
        ax4.axhline(y=33, color="red", linestyle="--", alpha=0.5)
        ax4.set_title("Recovery Trends")
        ax4.set_ylabel("%")
        ax4.legend(fontsize=8)
        ax4.xaxis.set_major_formatter(mdates.DateFormatter("%Y-%m"))
        plt.setp(ax4.xaxis.get_majorticklabels(), rotation=45)

        plt.tight_layout(rect=[0, 0.03, 1, 0.95])
        pdf.savefig(fig, bbox_inches="tight")
        plt.close()

        # Page 4: Individual Summaries
        for _key, profile in profiles.items():
            fig = plt.figure(figsize=(11, 8.5))
            ind = profile.individual
            fig.suptitle(f"{ind.name} - Quick Summary", fontsize=14, fontweight="bold")

            # Radar chart of scores
            ax1 = fig.add_subplot(1, 2, 1, polar=True)
            categories = ["Overall", "CV", "Sleep", "Recovery", "Activity", "Respiratory"]
            values = [
                profile.health_scores.overall,
                profile.health_scores.cardiovascular,
                profile.health_scores.sleep,
                profile.health_scores.recovery,
                profile.health_scores.activity,
                profile.health_scores.respiratory,
            ]
            values += values[:1]  # Close the loop

            angles = [n / float(len(categories)) * 2 * np.pi for n in range(len(categories))]
            angles += angles[:1]

            ax1.plot(angles, values, "o-", linewidth=2, color=ind.color)
            ax1.fill(angles, values, alpha=0.25, color=ind.color)
            ax1.set_xticks(angles[:-1])
            ax1.set_xticklabels(categories, size=8)
            ax1.set_ylim(0, 100)
            ax1.set_title("Health Profile", pad=20)

            # Key metrics text
            ax2 = fig.add_subplot(1, 2, 2)
            ax2.axis("off")

            metrics_text = f"""
{ind.name}
Age: {ind.age} ({ind.gender.title()})
Data: {profile.data_range.days} days

KEY METRICS
{"─" * 30}
RHR: {profile.cardiovascular.rhr_mean:.0f} bpm ({profile.cardiovascular.rhr_category})
HRV: {profile.cardiovascular.hrv_mean:.0f} ms ({profile.cardiovascular.hrv_category})
Sleep: {profile.sleep.duration_hours:.1f} hrs ({profile.sleep.duration_category})
SpO2: {profile.respiratory.spo2_mean:.1f}% ({profile.respiratory.spo2_category})
Recovery: {profile.recovery.recovery_mean:.0f}% ({profile.recovery.green_pct:.0f}% green days)

RECOMMENDATIONS
{"─" * 30}
"""
            for rec in profile.recommendations[:3]:
                metrics_text += f"[{rec.priority.value}] {rec.category}\n"

            if not profile.recommendations:
                metrics_text += "No urgent recommendations.\n"

            ax2.text(
                0.1,
                0.9,
                metrics_text,
                transform=ax2.transAxes,
                fontsize=10,
                verticalalignment="top",
                fontfamily="monospace",
            )

            plt.tight_layout()
            pdf.savefig(fig, bbox_inches="tight")
            plt.close()

        # Final page: Citations
        fig = plt.figure(figsize=(11, 8.5))
        ax = fig.add_subplot(111)
        ax.axis("off")

        citations_text = f"""
METHODOLOGY & CITATIONS
{"=" * 60}

This health analysis uses evidence-based medical benchmarks from the following sources:

CARDIOVASCULAR METRICS
{"─" * 40}
Resting Heart Rate:
  Source: {BENCHMARKS_CITATIONS["rhr"]["source"]}
  URL: {BENCHMARKS_CITATIONS["rhr"]["url"]}

Heart Rate Variability:
  Source: {BENCHMARKS_CITATIONS["hrv"]["source"]}
  Note: HRV benchmarks are age-adjusted, as HRV naturally declines with age.

RESPIRATORY METRICS
{"─" * 40}
Blood Oxygen (SpO2):
  Source: {BENCHMARKS_CITATIONS["spo2"]["source"]}
  Normal range: 95-100%

Respiratory Rate:
  Source: {BENCHMARKS_CITATIONS["respiratory_rate"]["source"]}
  Normal range: 12-16 breaths/min

SLEEP METRICS
{"─" * 40}
Duration & Architecture:
  Source: {BENCHMARKS_CITATIONS["sleep"]["source"]}
  Optimal duration: 7-9 hours for adults

DISCLAIMER
{"─" * 40}
This analysis is for informational purposes only and should not replace
professional medical advice. For any health concerns, consult with
qualified healthcare providers.

Generated by Health Analysis Pipeline v1.0.0
Analysis Date: {datetime.now().strftime("%Y-%m-%d")}
"""

        ax.text(
            0.05,
            0.95,
            citations_text,
            transform=ax.transAxes,
            fontsize=10,
            verticalalignment="top",
            fontfamily="monospace",
        )
        pdf.savefig(fig, bbox_inches="tight")
        plt.close()

    return "summary_report.pdf"


def generate_comprehensive_reports(
    profiles: dict[str, HealthProfile],
    all_data: dict[str, dict[str, pd.DataFrame]],
    previous_context: dict | None,
    output_path: Path,
    config: Config,
    snapshot_id: str,
) -> list[str]:
    """Generate all comprehensive PDF reports."""
    output_path.mkdir(parents=True, exist_ok=True)
    generated_files = []

    # Generate per-person reports
    for key, profile in profiles.items():
        data = all_data.get(key, {})
        filename = create_individual_pdf(key, profile, data, previous_context, output_path, config)
        generated_files.append(filename)
        print(f"Generated: {filename}")

    # Generate summary report
    filename = create_summary_pdf(
        profiles, all_data, previous_context, output_path, config, snapshot_id
    )
    generated_files.append(filename)
    print(f"Generated: {filename}")

    return generated_files
