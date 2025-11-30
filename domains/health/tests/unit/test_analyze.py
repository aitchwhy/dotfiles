"""
Unit tests for analysis engine.
"""

import sys
from pathlib import Path

import pandas as pd
import pytest

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from pipeline.analyze import (
    analyze_cardiovascular,
    analyze_respiratory,
    analyze_sleep,
    categorize_metric,
    compute_health_scores,
    compute_trend,
    generate_recommendations,
)
from pipeline.config import Config
from pipeline.schema import Individual


class TestCategorizeMetric:
    """Tests for metric categorization."""

    @pytest.mark.unit
    def test_categorize_in_range(self, base_path: Path) -> None:
        """Test categorizing metrics within defined ranges."""
        config = Config(base_path)
        rhr_ranges = config.benchmarks.resting_heart_rate

        # Test excellent range (40-54)
        assert categorize_metric(45, rhr_ranges) == "excellent"
        assert categorize_metric(40, rhr_ranges) == "excellent"
        assert categorize_metric(54, rhr_ranges) == "excellent"

        # Test good range (55-64)
        assert categorize_metric(60, rhr_ranges) == "good"

        # Test average range (65-74)
        assert categorize_metric(70, rhr_ranges) == "average"

    @pytest.mark.unit
    def test_categorize_boundary_values(self, base_path: Path) -> None:
        """Test categorization at boundary values."""
        config = Config(base_path)
        rhr_ranges = config.benchmarks.resting_heart_rate

        # Test boundary values
        for value in [40, 54, 55, 64, 65, 74, 75, 84, 85, 100]:
            category = categorize_metric(value, rhr_ranges)
            assert isinstance(category, str)


class TestComputeTrend:
    """Tests for trend computation."""

    @pytest.mark.unit
    def test_improving_trend(self) -> None:
        """Test detecting improving trend in RHR (lower is better)."""
        # Create series with decreasing values
        earlier = [70] * 30
        recent = [60] * 30
        series = pd.Series(earlier + recent, name="Resting heart rate (bpm)")

        trend = compute_trend(series, window=30)
        assert trend == "improving"

    @pytest.mark.unit
    def test_stable_trend(self) -> None:
        """Test detecting stable trend."""
        # Create series with stable values
        values = [65] * 60
        series = pd.Series(values, name="Heart rate variability (ms)")

        trend = compute_trend(series, window=30)
        assert trend == "stable"

    @pytest.mark.unit
    def test_insufficient_data(self) -> None:
        """Test handling insufficient data."""
        series = pd.Series([65] * 10, name="test")
        trend = compute_trend(series, window=30)
        assert trend == "insufficient_data"


class TestAnalyzeCardiovascular:
    """Tests for cardiovascular analysis."""

    @pytest.mark.unit
    def test_analyze_cardiovascular_basic(
        self, sample_physiological_data: pd.DataFrame, base_path: Path
    ) -> None:
        """Test basic cardiovascular analysis."""
        config = Config(base_path)
        individual = Individual(
            key="test", folder="test", name="Test", birth_year=1990, gender="male", color="#3498db"
        )

        metrics = analyze_cardiovascular(sample_physiological_data, individual, config.benchmarks)

        assert 30 <= metrics.rhr_mean <= 200
        assert metrics.hrv_mean >= 0
        assert metrics.hrv_age_bracket == "30-39"

    @pytest.mark.unit
    def test_cardiovascular_with_varied_data(self, base_path: Path) -> None:
        """Test analysis handles varied data ranges."""
        config = Config(base_path)
        individual = Individual(
            key="test", folder="test", name="Test", birth_year=1990, gender="male", color="#3498db"
        )

        # Test with varied RHR values
        rhr_values = [55 + i % 20 for i in range(50)]
        df = pd.DataFrame(
            {
                "Resting heart rate (bpm)": rhr_values,
                "Heart rate variability (ms)": [50.0] * len(rhr_values),
            }
        )

        metrics = analyze_cardiovascular(df, individual, config.benchmarks)

        assert metrics.rhr_mean == pytest.approx(sum(rhr_values) / len(rhr_values), rel=0.01)


class TestAnalyzeRespiratory:
    """Tests for respiratory analysis."""

    @pytest.mark.unit
    def test_analyze_respiratory_basic(
        self, sample_physiological_data: pd.DataFrame, base_path: Path
    ) -> None:
        """Test basic respiratory analysis."""
        config = Config(base_path)

        metrics = analyze_respiratory(sample_physiological_data, config.benchmarks)

        assert 0 <= metrics.spo2_mean <= 100
        assert 0 <= metrics.low_readings_pct <= 100
        assert metrics.rr_mean > 0

    @pytest.mark.unit
    def test_low_spo2_detection(self, base_path: Path) -> None:
        """Test detection of low SpO2 readings."""
        config = Config(base_path)

        # Create data with some low SpO2 readings
        df = pd.DataFrame(
            {
                "Blood oxygen %": [92.0, 93.0, 94.0, 96.0, 97.0, 98.0, 95.0, 91.0, 99.0, 94.5],
                "Respiratory rate (rpm)": [14.5] * 10,
            }
        )

        metrics = analyze_respiratory(df, config.benchmarks)

        # Values below 95 should be counted as low
        assert metrics.low_readings_count == 5  # 92, 93, 94, 91, 94.5
        assert metrics.low_readings_pct == 50.0


class TestAnalyzeSleep:
    """Tests for sleep analysis."""

    @pytest.mark.unit
    def test_analyze_sleep_basic(
        self, sample_physiological_data: pd.DataFrame, base_path: Path
    ) -> None:
        """Test basic sleep analysis."""
        config = Config(base_path)

        metrics = analyze_sleep(sample_physiological_data, config.benchmarks)

        assert metrics.duration_hours > 0
        assert metrics.duration_min > 0
        assert 0 <= metrics.deep_sleep_pct <= 100
        assert 0 <= metrics.rem_sleep_pct <= 100
        assert 0 <= metrics.efficiency <= 100

    @pytest.mark.unit
    def test_chronic_sleep_debt_detection(self, base_path: Path) -> None:
        """Test detection of chronic sleep debt."""
        config = Config(base_path)

        # Create data with high sleep debt
        df = pd.DataFrame(
            {
                "Asleep duration (min)": [360.0] * 30,  # 6 hours
                "Deep (SWS) duration (min)": [80.0] * 30,
                "REM duration (min)": [100.0] * 30,
                "Light sleep duration (min)": [150.0] * 30,
                "Awake duration (min)": [20.0] * 30,
                "Sleep efficiency %": [90.0] * 30,
                "Sleep performance %": [70.0] * 30,
                "Sleep debt (min)": [90.0] * 30,  # High debt
            }
        )

        metrics = analyze_sleep(df, config.benchmarks)

        assert metrics.chronic_debt == True  # noqa: E712 - numpy bool comparison
        assert metrics.sleep_debt_min == 90.0


class TestComputeHealthScores:
    """Tests for health score computation."""

    @pytest.mark.unit
    def test_compute_health_scores_basic(self) -> None:
        """Test basic health score computation."""
        from pipeline.schema import (
            CardiovascularMetrics,
            RecoveryMetrics,
            RespiratoryMetrics,
            SleepMetrics,
        )

        cv = CardiovascularMetrics(
            rhr_mean=55,
            rhr_std=5,
            rhr_min=50,
            rhr_max=60,
            rhr_category="good",
            rhr_trend="stable",
            rhr_30day_avg=None,
            hrv_mean=50,
            hrv_std=10,
            hrv_min=40,
            hrv_max=60,
            hrv_category="good",
            hrv_trend="stable",
            hrv_30day_avg=None,
            hrv_age_bracket="30-39",
        )

        resp = RespiratoryMetrics(
            spo2_mean=97,
            spo2_std=1,
            spo2_min=95,
            spo2_max=99,
            spo2_category="normal",
            low_readings_count=0,
            low_readings_pct=0,
            rr_mean=14,
            rr_std=1,
            rr_category="optimal",
        )

        sleep = SleepMetrics(
            duration_hours=7.5,
            duration_min=450,
            duration_category="optimal",
            deep_sleep_min=90,
            deep_sleep_pct=20,
            deep_sleep_category="excellent",
            rem_sleep_min=110,
            rem_sleep_pct=24,
            rem_sleep_category="excellent",
            light_sleep_min=200,
            awake_min=20,
            efficiency=93,
            efficiency_category="excellent",
            performance=85,
            sleep_debt_min=20,
            chronic_debt=False,
        )

        recovery = RecoveryMetrics(
            recovery_mean=70,
            recovery_std=15,
            green_days=20,
            green_pct=66,
            yellow_days=8,
            yellow_pct=27,
            red_days=2,
            red_pct=7,
            recovery_7day_avg=None,
            strain_mean=12,
            strain_std=3,
            light_pct=30,
            moderate_pct=40,
            high_pct=25,
            all_out_pct=5,
        )

        scores = compute_health_scores(cv, resp, sleep, recovery)

        assert 0 <= scores.overall <= 100
        assert 0 <= scores.cardiovascular <= 100
        assert 0 <= scores.sleep <= 100
        assert scores.recovery == 70  # Direct from WHOOP


class TestGenerateRecommendations:
    """Tests for recommendation generation."""

    @pytest.mark.unit
    def test_generates_sleep_recommendation(self) -> None:
        """Test that sleep recommendations are generated for short sleep."""
        from pipeline.schema import (
            CardiovascularMetrics,
            Priority,
            RecoveryMetrics,
            RespiratoryMetrics,
            SleepMetrics,
        )

        individual = Individual(
            key="test", folder="test", name="Test", birth_year=1990, gender="male", color="#3498db"
        )

        cv = CardiovascularMetrics(
            rhr_mean=60,
            rhr_std=5,
            rhr_min=55,
            rhr_max=65,
            rhr_category="good",
            rhr_trend="stable",
            rhr_30day_avg=None,
            hrv_mean=50,
            hrv_std=10,
            hrv_min=40,
            hrv_max=60,
            hrv_category="good",
            hrv_trend="stable",
            hrv_30day_avg=None,
            hrv_age_bracket="30-39",
        )

        resp = RespiratoryMetrics(
            spo2_mean=97,
            spo2_std=1,
            spo2_min=95,
            spo2_max=99,
            spo2_category="normal",
            low_readings_count=0,
            low_readings_pct=0,
            rr_mean=14,
            rr_std=1,
            rr_category="optimal",
        )

        # Short sleep duration
        sleep = SleepMetrics(
            duration_hours=5.5,
            duration_min=330,
            duration_category="short",
            deep_sleep_min=70,
            deep_sleep_pct=21,
            deep_sleep_category="excellent",
            rem_sleep_min=80,
            rem_sleep_pct=24,
            rem_sleep_category="excellent",
            light_sleep_min=150,
            awake_min=20,
            efficiency=90,
            efficiency_category="excellent",
            performance=65,
            sleep_debt_min=90,
            chronic_debt=True,
        )

        recovery = RecoveryMetrics(
            recovery_mean=50,
            recovery_std=15,
            green_days=10,
            green_pct=33,
            yellow_days=15,
            yellow_pct=50,
            red_days=5,
            red_pct=17,
            recovery_7day_avg=None,
            strain_mean=10,
            strain_std=3,
            light_pct=40,
            moderate_pct=35,
            high_pct=20,
            all_out_pct=5,
        )

        recommendations = generate_recommendations(individual, cv, resp, sleep, recovery)

        # Should have sleep-related recommendations
        sleep_recs = [r for r in recommendations if r.category == "Sleep"]
        assert len(sleep_recs) > 0

        # Should have high priority for insufficient sleep
        high_priority = [r for r in recommendations if r.priority == Priority.HIGH]
        assert len(high_priority) > 0
