"""
Data schemas and validation for health analysis pipeline.

Defines the expected structure of input data and output artifacts.
"""

from dataclasses import dataclass, field
from datetime import date, datetime
from enum import Enum

import pandas as pd


class Priority(Enum):
    """Recommendation priority levels."""

    HIGH = "HIGH"
    MEDIUM = "MEDIUM"
    LOW = "LOW"


class RecommendationStatus(Enum):
    """Status of a recommendation."""

    OPEN = "open"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    DISMISSED = "dismissed"


class AlertSeverity(Enum):
    """Alert severity levels."""

    CRITICAL = "critical"
    WARNING = "warning"
    INFO = "info"


@dataclass
class Individual:
    """Person configuration."""

    key: str
    folder: str
    name: str
    birth_year: int
    gender: str  # "male" or "female"
    color: str

    @property
    def age(self) -> int:
        """Calculate current age."""
        return datetime.now().year - self.birth_year

    @property
    def age_bracket(self) -> str:
        """Get age bracket for HRV benchmarks."""
        age = self.age
        if age < 30:
            return "20-29"
        elif age < 40:
            return "30-39"
        elif age < 50:
            return "40-49"
        elif age < 60:
            return "50-59"
        elif age < 70:
            return "60-69"
        return "70+"

    @property
    def demographic_key(self) -> str:
        """Get demographic key for baseline lookups (age_bracket + gender)."""
        return f"{self.age_bracket}_{self.gender}"


@dataclass
class DataRange:
    """Date range for data."""

    start: date
    end: date
    days: int


@dataclass
class HealthScores:
    """Computed health scores for an individual."""

    overall: float
    cardiovascular: float
    respiratory: float
    sleep: float
    recovery: float
    activity: float


@dataclass
class CardiovascularMetrics:
    """Cardiovascular health metrics."""

    rhr_mean: float
    rhr_std: float
    rhr_min: float
    rhr_max: float
    rhr_category: str
    rhr_trend: str
    rhr_30day_avg: float | None

    hrv_mean: float
    hrv_std: float
    hrv_min: float
    hrv_max: float
    hrv_category: str
    hrv_trend: str
    hrv_30day_avg: float | None
    hrv_age_bracket: str


@dataclass
class RespiratoryMetrics:
    """Respiratory health metrics."""

    spo2_mean: float
    spo2_std: float
    spo2_min: float
    spo2_max: float
    spo2_category: str
    low_readings_count: int
    low_readings_pct: float

    rr_mean: float
    rr_std: float
    rr_category: str


@dataclass
class SleepMetrics:
    """Sleep health metrics."""

    duration_hours: float
    duration_min: float
    duration_category: str

    deep_sleep_min: float
    deep_sleep_pct: float
    deep_sleep_category: str

    rem_sleep_min: float
    rem_sleep_pct: float
    rem_sleep_category: str

    light_sleep_min: float
    awake_min: float

    efficiency: float
    efficiency_category: str
    performance: float

    sleep_debt_min: float
    chronic_debt: bool


@dataclass
class RecoveryMetrics:
    """Recovery and strain metrics."""

    recovery_mean: float
    recovery_std: float
    green_days: int
    green_pct: float
    yellow_days: int
    yellow_pct: float
    red_days: int
    red_pct: float
    recovery_7day_avg: float | None

    strain_mean: float
    strain_std: float
    light_pct: float
    moderate_pct: float
    high_pct: float
    all_out_pct: float


@dataclass
class Recommendation:
    """A health recommendation."""

    rec_id: str
    category: str
    priority: Priority
    finding: str
    action: str
    medical_note: str
    status: RecommendationStatus = RecommendationStatus.OPEN
    created: date = field(default_factory=date.today)


@dataclass
class Alert:
    """A health alert."""

    alert_id: str
    alert_type: str
    severity: AlertSeverity
    message: str
    value: float
    threshold: float


@dataclass
class HealthProfile:
    """Complete health profile for an individual."""

    individual: Individual
    data_range: DataRange
    health_scores: HealthScores
    cardiovascular: CardiovascularMetrics
    respiratory: RespiratoryMetrics
    sleep: SleepMetrics
    recovery: RecoveryMetrics
    recommendations: list[Recommendation]
    alerts: list[Alert]
    lifestyle_patterns: dict[str, dict]


@dataclass
class AnalysisContext:
    """Context from previous analysis for trend comparison."""

    snapshot_id: str
    analysis_date: date
    profiles: dict[str, HealthProfile]
    family_insights: dict


@dataclass
class Manifest:
    """Pipeline execution manifest."""

    version: str
    snapshot_id: str
    created_at: datetime
    data_hash: str
    input_summary: dict
    output_files: list[str]
    previous_snapshot: str | None
    duration_seconds: float


# CSV Column schemas for validation
PHYSIOLOGICAL_COLUMNS = [
    "Cycle start time",
    "Cycle end time",
    "Cycle timezone",
    "Recovery score %",
    "Resting heart rate (bpm)",
    "Heart rate variability (ms)",
    "Skin temp (celsius)",
    "Blood oxygen %",
    "Day Strain",
    "Energy burned (cal)",
    "Max HR (bpm)",
    "Average HR (bpm)",
    "Sleep onset",
    "Wake onset",
    "Sleep performance %",
    "Respiratory rate (rpm)",
    "Asleep duration (min)",
    "In bed duration (min)",
    "Light sleep duration (min)",
    "Deep (SWS) duration (min)",
    "REM duration (min)",
    "Awake duration (min)",
    "Sleep need (min)",
    "Sleep debt (min)",
    "Sleep efficiency %",
    "Sleep consistency %",
]

SLEEP_COLUMNS = [
    "Cycle start time",
    "Cycle end time",
    "Cycle timezone",
    "Sleep onset",
    "Wake onset",
    "Sleep performance %",
    "Respiratory rate (rpm)",
    "Asleep duration (min)",
    "In bed duration (min)",
    "Light sleep duration (min)",
    "Deep (SWS) duration (min)",
    "REM duration (min)",
    "Awake duration (min)",
    "Sleep need (min)",
    "Sleep debt (min)",
    "Sleep efficiency %",
    "Sleep consistency %",
    "Nap",
]

WORKOUT_COLUMNS = [
    "Cycle start time",
    "Cycle end time",
    "Cycle timezone",
    "Workout start time",
    "Workout end time",
    "Duration (min)",
    "Activity Strain",
    "Energy burned (cal)",
    "Max HR (bpm)",
    "Average HR (bpm)",
    "HR Zone 1 %",
    "HR Zone 2 %",
    "HR Zone 3 %",
    "HR Zone 4 %",
    "HR Zone 5 %",
    "GPS enabled",
]

JOURNAL_COLUMNS = [
    "Cycle start time",
    "Cycle end time",
    "Cycle timezone",
    "Question text",
    "Answered yes",
    "Notes",
]


def validate_dataframe(df: pd.DataFrame, expected_columns: list[str], name: str) -> bool:
    """Validate that a DataFrame has expected columns."""
    missing = set(expected_columns) - set(df.columns)
    if missing:
        print(f"Warning: {name} missing columns: {missing}")
        return False
    return True
