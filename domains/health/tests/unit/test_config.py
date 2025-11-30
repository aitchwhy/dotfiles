"""
Unit tests for configuration loading.
"""

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from pipeline.config import (
    Config,
    load_benchmarks,
    load_individuals,
    load_pipeline_config,
)


class TestConfigLoading:
    """Tests for configuration loading."""

    @pytest.mark.unit
    def test_load_pipeline_config(self, config_dir: Path) -> None:
        """Test loading pipeline configuration."""
        config = load_pipeline_config(config_dir)

        assert config.version == "1.0.0"
        assert config.raw_data_path == Path("data/WHOOP")
        assert config.snapshots_path == Path("snapshots")
        assert config.analysis.rolling_windows["medium"] == 30

    @pytest.mark.unit
    def test_load_individuals(self, config_dir: Path) -> None:
        """Test loading individuals configuration."""
        individuals = load_individuals(config_dir)

        assert "hank" in individuals
        assert "dad" in individuals
        assert "mom" in individuals

        hank = individuals["hank"]
        assert hank.name == "Hank (Jong-Hyun Lee)"
        assert hank.birth_year == 1993
        assert hank.gender == "male"
        assert hank.color == "#3498db"

    @pytest.mark.unit
    def test_load_benchmarks(self, config_dir: Path) -> None:
        """Test loading medical benchmarks."""
        benchmarks = load_benchmarks(config_dir)

        # Check RHR benchmarks
        assert "excellent" in benchmarks.resting_heart_rate
        assert benchmarks.resting_heart_rate["excellent"].lower == 40
        assert benchmarks.resting_heart_rate["excellent"].upper == 54

        # Check HRV by age
        assert "30-39" in benchmarks.hrv_by_age
        assert "excellent" in benchmarks.hrv_by_age["30-39"]

        # Check sleep duration
        assert benchmarks.sleep_duration["optimal"].lower == 420
        assert benchmarks.sleep_duration["optimal"].upper == 540

    @pytest.mark.unit
    def test_full_config(self, base_path: Path) -> None:
        """Test loading full configuration."""
        config = Config(base_path)

        assert config.pipeline.version == "1.0.0"
        assert len(config.individuals) == 5
        assert config.benchmarks.resting_heart_rate is not None

    @pytest.mark.unit
    def test_config_paths(self, base_path: Path) -> None:
        """Test configuration path resolution."""
        config = Config(base_path)

        raw_path = config.get_raw_data_path()
        assert raw_path.name == "WHOOP"

        snapshots_path = config.get_snapshots_path()
        assert snapshots_path.name == "snapshots"


class TestBenchmarkRanges:
    """Tests for benchmark range validation."""

    @pytest.mark.unit
    def test_rhr_category_coverage(self, base_path: Path) -> None:
        """Test that RHR categories cover full range."""
        config = Config(base_path)
        rhr = config.benchmarks.resting_heart_rate

        # Check categories exist and have valid ranges
        categories = ["excellent", "good", "average", "below_average", "poor"]
        for cat in categories:
            assert cat in rhr
            assert rhr[cat].lower < rhr[cat].upper

    @pytest.mark.unit
    def test_hrv_age_brackets(self, base_path: Path) -> None:
        """Test that HRV benchmarks cover all age brackets."""
        config = Config(base_path)
        hrv = config.benchmarks.hrv_by_age

        expected_brackets = ["20-29", "30-39", "40-49", "50-59", "60-69", "70+"]
        for bracket in expected_brackets:
            assert bracket in hrv, f"Missing age bracket: {bracket}"
            assert "excellent" in hrv[bracket]
            assert "good" in hrv[bracket]

    @pytest.mark.unit
    def test_sleep_duration_hours(self, base_path: Path) -> None:
        """Test sleep duration benchmarks are in minutes."""
        config = Config(base_path)
        sleep = config.benchmarks.sleep_duration

        # Optimal is 7-9 hours = 420-540 minutes
        assert sleep["optimal"].lower == 420
        assert sleep["optimal"].upper == 540
