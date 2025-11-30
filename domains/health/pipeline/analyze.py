"""
Health analysis engine.

Computes health metrics and generates recommendations against medical benchmarks.
"""

import uuid

import pandas as pd

from .config import BenchmarkRange, Benchmarks, Config
from .consolidate import get_data_range
from .schema import (
    Alert,
    AlertSeverity,
    CardiovascularMetrics,
    HealthProfile,
    HealthScores,
    Individual,
    Priority,
    Recommendation,
    RecoveryMetrics,
    RespiratoryMetrics,
    SleepMetrics,
)


def categorize_metric(value: float, ranges: dict[str, BenchmarkRange]) -> str:
    """Categorize a metric value against benchmark ranges."""
    for category, benchmark in ranges.items():
        if benchmark.lower <= value <= benchmark.upper:
            return category
    return "unknown"


def compute_trend(series: pd.Series, window: int = 30) -> str:
    """Compute trend direction comparing recent to earlier data."""
    if len(series) < window * 2:
        return "insufficient_data"

    recent = series.iloc[-window:].mean()
    earlier = series.iloc[:window].mean()

    if recent < earlier * 0.95:
        return "improving" if series.name in ["Resting heart rate (bpm)"] else "declining"
    elif recent > earlier * 1.05:
        return "worsening" if series.name in ["Resting heart rate (bpm)"] else "improving"
    return "stable"


def analyze_cardiovascular(
    df: pd.DataFrame, individual: Individual, benchmarks: Benchmarks, window: int = 30
) -> CardiovascularMetrics:
    """Analyze cardiovascular metrics."""
    rhr = df["Resting heart rate (bpm)"].dropna()
    hrv = df["Heart rate variability (ms)"].dropna()

    # RHR analysis
    rhr_mean = rhr.mean() if len(rhr) > 0 else 0
    rhr_category = categorize_metric(rhr_mean, benchmarks.resting_heart_rate)
    rhr_trend = (
        "improving"
        if len(rhr) >= window * 2 and rhr.iloc[-window:].mean() < rhr.iloc[:window].mean()
        else "stable"
    )

    # HRV analysis
    hrv_mean = hrv.mean() if len(hrv) > 0 else 0
    age_bracket = individual.age_bracket
    hrv_ranges = benchmarks.hrv_by_age.get(age_bracket, benchmarks.hrv_by_age["30-39"])
    hrv_category = categorize_metric(hrv_mean, hrv_ranges)
    hrv_trend = (
        "improving"
        if len(hrv) >= window * 2 and hrv.iloc[-window:].mean() > hrv.iloc[:window].mean()
        else "stable"
    )

    return CardiovascularMetrics(
        rhr_mean=round(rhr_mean, 1),
        rhr_std=round(rhr.std(), 1) if len(rhr) > 0 else 0,
        rhr_min=round(rhr.min(), 1) if len(rhr) > 0 else 0,
        rhr_max=round(rhr.max(), 1) if len(rhr) > 0 else 0,
        rhr_category=rhr_category,
        rhr_trend=rhr_trend,
        rhr_30day_avg=round(rhr.iloc[-window:].mean(), 1) if len(rhr) >= window else None,
        hrv_mean=round(hrv_mean, 1),
        hrv_std=round(hrv.std(), 1) if len(hrv) > 0 else 0,
        hrv_min=round(hrv.min(), 1) if len(hrv) > 0 else 0,
        hrv_max=round(hrv.max(), 1) if len(hrv) > 0 else 0,
        hrv_category=hrv_category,
        hrv_trend=hrv_trend,
        hrv_30day_avg=round(hrv.iloc[-window:].mean(), 1) if len(hrv) >= window else None,
        hrv_age_bracket=age_bracket,
    )


def analyze_respiratory(df: pd.DataFrame, benchmarks: Benchmarks) -> RespiratoryMetrics:
    """Analyze respiratory metrics."""
    spo2 = df["Blood oxygen %"].dropna()
    rr = df["Respiratory rate (rpm)"].dropna()

    spo2_mean = spo2.mean() if len(spo2) > 0 else 0
    spo2_category = categorize_metric(spo2_mean, benchmarks.blood_oxygen)
    low_readings = len(spo2[spo2 < 95]) if len(spo2) > 0 else 0

    rr_mean = rr.mean() if len(rr) > 0 else 0
    rr_category = categorize_metric(rr_mean, benchmarks.respiratory_rate)

    return RespiratoryMetrics(
        spo2_mean=round(spo2_mean, 2),
        spo2_std=round(spo2.std(), 2) if len(spo2) > 0 else 0,
        spo2_min=round(spo2.min(), 2) if len(spo2) > 0 else 0,
        spo2_max=round(spo2.max(), 2) if len(spo2) > 0 else 0,
        spo2_category=spo2_category,
        low_readings_count=low_readings,
        low_readings_pct=round(100 * low_readings / len(spo2), 1) if len(spo2) > 0 else 0,
        rr_mean=round(rr_mean, 1),
        rr_std=round(rr.std(), 1) if len(rr) > 0 else 0,
        rr_category=rr_category,
    )


def analyze_sleep(df: pd.DataFrame, benchmarks: Benchmarks) -> SleepMetrics:
    """Analyze sleep metrics."""
    duration = df["Asleep duration (min)"].dropna()
    deep = df["Deep (SWS) duration (min)"].dropna()
    rem = df["REM duration (min)"].dropna()
    light = df["Light sleep duration (min)"].dropna()
    awake = df["Awake duration (min)"].dropna()
    efficiency = df["Sleep efficiency %"].dropna()
    performance = df["Sleep performance %"].dropna()
    debt = df["Sleep debt (min)"].dropna()

    duration_mean = duration.mean() if len(duration) > 0 else 0
    duration_category = categorize_metric(duration_mean, benchmarks.sleep_duration)

    deep_mean = deep.mean() if len(deep) > 0 else 0
    deep_pct = 100 * deep_mean / duration_mean if duration_mean > 0 else 0
    deep_category = categorize_metric(deep_pct, benchmarks.deep_sleep_percentage)

    rem_mean = rem.mean() if len(rem) > 0 else 0
    rem_pct = 100 * rem_mean / duration_mean if duration_mean > 0 else 0
    rem_category = categorize_metric(rem_pct, benchmarks.rem_sleep_percentage)

    efficiency_mean = efficiency.mean() if len(efficiency) > 0 else 0
    efficiency_category = categorize_metric(efficiency_mean, benchmarks.sleep_efficiency)

    debt_mean = debt.mean() if len(debt) > 0 else 0

    return SleepMetrics(
        duration_hours=round(duration_mean / 60, 1),
        duration_min=round(duration_mean, 0),
        duration_category=duration_category,
        deep_sleep_min=round(deep_mean, 0),
        deep_sleep_pct=round(deep_pct, 1),
        deep_sleep_category=deep_category,
        rem_sleep_min=round(rem_mean, 0),
        rem_sleep_pct=round(rem_pct, 1),
        rem_sleep_category=rem_category,
        light_sleep_min=round(light.mean(), 0) if len(light) > 0 else 0,
        awake_min=round(awake.mean(), 0) if len(awake) > 0 else 0,
        efficiency=round(efficiency_mean, 1),
        efficiency_category=efficiency_category,
        performance=round(performance.mean(), 1) if len(performance) > 0 else 0,
        sleep_debt_min=round(debt_mean, 0),
        chronic_debt=debt_mean > 60,
    )


def analyze_recovery(
    df: pd.DataFrame,
    benchmarks: Benchmarks,  # noqa: ARG001 - kept for API consistency
    window: int = 7,
) -> RecoveryMetrics:
    """Analyze recovery and strain metrics."""
    recovery = df["Recovery score %"].dropna()
    strain = df["Day Strain"].dropna()

    total = len(recovery) if len(recovery) > 0 else 1
    green = len(recovery[recovery >= 67])
    yellow = len(recovery[(recovery >= 34) & (recovery < 67)])
    red = len(recovery[recovery < 34])

    light = len(strain[strain < 10]) if len(strain) > 0 else 0
    moderate = len(strain[(strain >= 10) & (strain < 14)]) if len(strain) > 0 else 0
    high = len(strain[(strain >= 14) & (strain < 18)]) if len(strain) > 0 else 0
    all_out = len(strain[strain >= 18]) if len(strain) > 0 else 0
    strain_total = len(strain) if len(strain) > 0 else 1

    return RecoveryMetrics(
        recovery_mean=round(recovery.mean(), 1) if len(recovery) > 0 else 0,
        recovery_std=round(recovery.std(), 1) if len(recovery) > 0 else 0,
        green_days=green,
        green_pct=round(100 * green / total, 1),
        yellow_days=yellow,
        yellow_pct=round(100 * yellow / total, 1),
        red_days=red,
        red_pct=round(100 * red / total, 1),
        recovery_7day_avg=round(recovery.iloc[-window:].mean(), 1)
        if len(recovery) >= window
        else None,
        strain_mean=round(strain.mean(), 1) if len(strain) > 0 else 0,
        strain_std=round(strain.std(), 1) if len(strain) > 0 else 0,
        light_pct=round(100 * light / strain_total, 1),
        moderate_pct=round(100 * moderate / strain_total, 1),
        high_pct=round(100 * high / strain_total, 1),
        all_out_pct=round(100 * all_out / strain_total, 1),
    )


def compute_health_scores(
    cardiovascular: CardiovascularMetrics,
    respiratory: RespiratoryMetrics,
    sleep: SleepMetrics,
    recovery: RecoveryMetrics,
) -> HealthScores:
    """Compute overall health scores from component metrics."""
    category_scores = {
        "excellent": 100,
        "good": 80,
        "normal": 90,
        "optimal": 100,
        "average": 60,
        "acceptable": 75,
        "below_average": 40,
        "poor": 20,
        "low_normal": 75,
        "concerning": 40,
        "critical": 10,
        "short": 50,
        "very_short": 25,
        "elevated": 60,
        "unknown": 50,
    }

    # Cardiovascular score
    rhr_score = category_scores.get(cardiovascular.rhr_category, 50)
    hrv_score = category_scores.get(cardiovascular.hrv_category, 50)
    cv_score = (rhr_score + hrv_score) / 2

    # Respiratory score
    resp_score = category_scores.get(respiratory.spo2_category, 50)

    # Sleep score
    duration_score = category_scores.get(sleep.duration_category, 50)
    deep_score = category_scores.get(sleep.deep_sleep_category, 50)
    efficiency_score = category_scores.get(sleep.efficiency_category, 50)
    sleep_score = (duration_score + deep_score + efficiency_score) / 3

    # Recovery score (direct from WHOOP)
    recovery_score = recovery.recovery_mean

    # Activity score
    activity_score = min(
        100,
        (
            recovery.moderate_pct * 1.0
            + recovery.high_pct * 1.2
            + recovery.light_pct * 0.5
            + recovery.all_out_pct * 0.8
        ),
    )

    # Overall
    overall = (cv_score + resp_score + sleep_score + recovery_score + activity_score) / 5

    return HealthScores(
        overall=round(overall, 0),
        cardiovascular=round(cv_score, 0),
        respiratory=round(resp_score, 0),
        sleep=round(sleep_score, 0),
        recovery=round(recovery_score, 0),
        activity=round(activity_score, 0),
    )


def generate_recommendations(
    individual: Individual,
    cardiovascular: CardiovascularMetrics,
    respiratory: RespiratoryMetrics,
    sleep: SleepMetrics,
    recovery: RecoveryMetrics,
) -> list[Recommendation]:
    """Generate health recommendations based on analysis."""
    recommendations = []

    # Cardiovascular recommendations
    if cardiovascular.rhr_category in ["below_average", "poor"]:
        recommendations.append(
            Recommendation(
                rec_id=f"{individual.key}_rhr_{uuid.uuid4().hex[:8]}",
                category="Cardiovascular",
                priority=Priority.HIGH,
                finding=f"Elevated resting heart rate ({cardiovascular.rhr_mean} bpm)",
                action="Increase aerobic exercise (150+ min/week moderate intensity). "
                "Focus on Zone 2 training. Review caffeine and stress levels.",
                medical_note="If consistently >85 bpm at rest, consider cardiac evaluation.",
            )
        )

    if cardiovascular.hrv_category in ["below_average", "poor"]:
        recommendations.append(
            Recommendation(
                rec_id=f"{individual.key}_hrv_{uuid.uuid4().hex[:8]}",
                category="Autonomic Health",
                priority=Priority.MEDIUM,
                finding=f"Low HRV for age bracket ({cardiovascular.hrv_mean} ms)",
                action="Focus on recovery: prioritize sleep, stress management, "
                "and avoid overtraining. Consider HRV biofeedback training.",
                medical_note="Low HRV is associated with increased cardiovascular risk.",
            )
        )

    # Respiratory recommendations
    if respiratory.low_readings_pct > 5:
        recommendations.append(
            Recommendation(
                rec_id=f"{individual.key}_spo2_{uuid.uuid4().hex[:8]}",
                category="Respiratory",
                priority=Priority.HIGH,
                finding=f"{respiratory.low_readings_pct}% of nights with SpO2 < 95%",
                action="Screen for sleep apnea. Consider sleep study (polysomnography). "
                "Review sleeping position and nasal breathing.",
                medical_note="Frequent desaturations during sleep warrant medical evaluation for OSA.",
            )
        )

    # Sleep recommendations
    if sleep.duration_hours < 7:
        recommendations.append(
            Recommendation(
                rec_id=f"{individual.key}_sleep_duration_{uuid.uuid4().hex[:8]}",
                category="Sleep",
                priority=Priority.HIGH,
                finding=f"Insufficient sleep duration ({sleep.duration_hours} hours avg)",
                action="Aim for 7-9 hours. Establish consistent sleep/wake times. "
                "Create sleep-conducive environment (dark, cool, quiet).",
                medical_note="Chronic sleep deprivation increases risk of obesity, diabetes, and CVD.",
            )
        )

    if sleep.deep_sleep_pct < 15:
        recommendations.append(
            Recommendation(
                rec_id=f"{individual.key}_deep_sleep_{uuid.uuid4().hex[:8]}",
                category="Sleep Quality",
                priority=Priority.MEDIUM,
                finding=f"Low deep sleep percentage ({sleep.deep_sleep_pct}%)",
                action="Avoid alcohol before bed. Exercise earlier in day. "
                "Maintain consistent sleep schedule. Consider magnesium supplementation.",
                medical_note="Deep sleep is critical for physical recovery and immune function.",
            )
        )

    if sleep.chronic_debt:
        recommendations.append(
            Recommendation(
                rec_id=f"{individual.key}_sleep_debt_{uuid.uuid4().hex[:8]}",
                category="Sleep Debt",
                priority=Priority.HIGH,
                finding=f"Chronic sleep debt ({sleep.sleep_debt_min} min average)",
                action="Prioritize sleep extension. Consider 20-min naps if needed. "
                "Address root causes of sleep restriction.",
                medical_note="Sleep debt accumulates and cannot be fully repaid with catch-up nights.",
            )
        )

    # Recovery recommendations
    if recovery.red_pct > 20:
        recommendations.append(
            Recommendation(
                rec_id=f"{individual.key}_recovery_{uuid.uuid4().hex[:8]}",
                category="Recovery",
                priority=Priority.HIGH,
                finding=f"High percentage of poor recovery days ({recovery.red_pct}%)",
                action="Review training load vs recovery balance. Consider deload weeks. "
                "Optimize nutrition, hydration, and stress management.",
                medical_note="Chronic under-recovery increases injury risk and may indicate overtraining.",
            )
        )

    # Activity recommendations
    if recovery.light_pct > 60:
        recommendations.append(
            Recommendation(
                rec_id=f"{individual.key}_activity_{uuid.uuid4().hex[:8]}",
                category="Activity",
                priority=Priority.MEDIUM,
                finding=f"Low activity levels ({recovery.light_pct}% light strain days)",
                action="Increase physical activity. Aim for 150 min moderate or 75 min vigorous "
                "exercise weekly. Include strength training 2x/week.",
                medical_note="Physical inactivity is a leading risk factor for chronic disease.",
            )
        )

    return recommendations


def generate_alerts(
    individual: Individual,
    respiratory: RespiratoryMetrics,
    sleep: SleepMetrics,
    recovery: RecoveryMetrics,
) -> list[Alert]:
    """Generate health alerts for critical conditions."""
    alerts = []

    if respiratory.low_readings_pct > 50:
        alerts.append(
            Alert(
                alert_id=f"{individual.key}_spo2_critical_{uuid.uuid4().hex[:8]}",
                alert_type="low_spo2",
                severity=AlertSeverity.CRITICAL,
                message=f"Critical: {respiratory.low_readings_pct}% of nights with low SpO2",
                value=respiratory.low_readings_pct,
                threshold=50,
            )
        )

    if sleep.chronic_debt and sleep.sleep_debt_min > 90:
        alerts.append(
            Alert(
                alert_id=f"{individual.key}_sleep_debt_severe_{uuid.uuid4().hex[:8]}",
                alert_type="chronic_sleep_debt",
                severity=AlertSeverity.WARNING,
                message=f"Severe sleep debt: {sleep.sleep_debt_min} min average",
                value=sleep.sleep_debt_min,
                threshold=90,
            )
        )

    if recovery.red_pct > 30:
        alerts.append(
            Alert(
                alert_id=f"{individual.key}_recovery_poor_{uuid.uuid4().hex[:8]}",
                alert_type="poor_recovery",
                severity=AlertSeverity.WARNING,
                message=f"High proportion of poor recovery days: {recovery.red_pct}%",
                value=recovery.red_pct,
                threshold=30,
            )
        )

    return alerts


def analyze_lifestyle_patterns(journal_df: pd.DataFrame) -> dict[str, dict]:
    """Analyze journal entry patterns."""
    if journal_df is None or journal_df.empty:
        return {}

    patterns = {}
    for question in journal_df["Question text"].unique():
        q_data = journal_df[journal_df["Question text"] == question]
        yes_count = q_data["Answered yes"].sum()
        total = len(q_data)
        patterns[question] = {
            "yes_count": int(yes_count),
            "total": total,
            "yes_pct": round(100 * yes_count / total, 1) if total > 0 else 0,
        }

    return patterns


def analyze_individual(
    individual: Individual, data: dict[str, pd.DataFrame], config: Config
) -> HealthProfile | None:
    """Generate complete health profile for an individual."""
    physio_df = data.get("physiological")
    if physio_df is None or physio_df.empty:
        return None

    journal_df = data.get("journal")

    # Compute all metrics
    data_range = get_data_range(physio_df)
    cardiovascular = analyze_cardiovascular(physio_df, individual, config.benchmarks)
    respiratory = analyze_respiratory(physio_df, config.benchmarks)
    sleep = analyze_sleep(physio_df, config.benchmarks)
    recovery = analyze_recovery(physio_df, config.benchmarks)
    health_scores = compute_health_scores(cardiovascular, respiratory, sleep, recovery)
    recommendations = generate_recommendations(
        individual, cardiovascular, respiratory, sleep, recovery
    )
    alerts = generate_alerts(individual, respiratory, sleep, recovery)
    lifestyle = analyze_lifestyle_patterns(journal_df)

    return HealthProfile(
        individual=individual,
        data_range=data_range,
        health_scores=health_scores,
        cardiovascular=cardiovascular,
        respiratory=respiratory,
        sleep=sleep,
        recovery=recovery,
        recommendations=recommendations,
        alerts=alerts,
        lifestyle_patterns=lifestyle,
    )


def analyze_all(
    all_data: dict[str, dict[str, pd.DataFrame]], config: Config
) -> dict[str, HealthProfile]:
    """Analyze health data for all individuals."""
    profiles = {}

    for key, data in all_data.items():
        individual = config.individuals.get(key)
        if individual is None:
            continue

        profile = analyze_individual(individual, data, config)
        if profile:
            profiles[key] = profile
            print(f"Analyzed {individual.name}: Overall score {profile.health_scores.overall}")

    return profiles
