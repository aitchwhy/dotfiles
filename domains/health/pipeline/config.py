"""
Configuration loader for health analysis pipeline.

Loads YAML configuration files and provides typed access.
"""

from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml

from .schema import Individual


@dataclass
class AnalysisConfig:
    """Analysis configuration."""

    rolling_windows: dict[str, int]
    thresholds: dict[str, float]


@dataclass
class VisualizationConfig:
    """Visualization configuration."""

    dpi: int
    style: str
    figure_sizes: dict[str, list[int]]


@dataclass
class PipelineConfig:
    """Complete pipeline configuration."""

    version: str
    raw_data_path: Path
    consolidated_path: Path
    snapshots_path: Path
    latest_symlink: str
    analysis: AnalysisConfig
    visualization: VisualizationConfig
    llm_analysis: bool
    llm_model: str


@dataclass
class BenchmarkRange:
    """A benchmark range with lower and upper bounds."""

    lower: float
    upper: float


@dataclass
class Benchmarks:
    """Medical benchmarks for health metrics."""

    resting_heart_rate: dict[str, BenchmarkRange]
    hrv_by_age: dict[str, dict[str, BenchmarkRange]]
    blood_oxygen: dict[str, BenchmarkRange]
    respiratory_rate: dict[str, BenchmarkRange]
    sleep_duration: dict[str, BenchmarkRange]
    deep_sleep_percentage: dict[str, BenchmarkRange]
    rem_sleep_percentage: dict[str, BenchmarkRange]
    sleep_efficiency: dict[str, BenchmarkRange]
    recovery_score: dict[str, BenchmarkRange]
    strain: dict[str, BenchmarkRange]


def load_yaml(path: Path) -> dict[str, Any]:
    """Load a YAML file."""
    with open(path) as f:
        return yaml.safe_load(f)


def load_pipeline_config(config_dir: Path) -> PipelineConfig:
    """Load pipeline configuration."""
    data = load_yaml(config_dir / "pipeline.yaml")

    return PipelineConfig(
        version=data["version"],
        raw_data_path=Path(data["data"]["raw_path"]),
        consolidated_path=Path(data["data"]["consolidated_path"]),
        snapshots_path=Path(data["output"]["snapshots_path"]),
        latest_symlink=data["output"]["latest_symlink"],
        analysis=AnalysisConfig(
            rolling_windows=data["analysis"]["rolling_windows"],
            thresholds=data["analysis"]["thresholds"],
        ),
        visualization=VisualizationConfig(
            dpi=data["visualization"]["dpi"],
            style=data["visualization"]["style"],
            figure_sizes=data["visualization"]["figure_sizes"],
        ),
        llm_analysis=data["future"]["llm_analysis"],
        llm_model=data["future"]["llm_model"],
    )


def load_individuals(config_dir: Path) -> dict[str, Individual]:
    """Load individual configurations."""
    data = load_yaml(config_dir / "individuals.yaml")

    individuals = {}
    for key, info in data["individuals"].items():
        individuals[key] = Individual(
            key=key,
            folder=info["folder"],
            name=info["name"],
            birth_year=info["birth_year"],
            gender=info.get("gender", "male"),
            color=info["color"],
        )

    return individuals


def load_benchmarks(config_dir: Path) -> Benchmarks:
    """Load medical benchmarks."""
    data = load_yaml(config_dir / "benchmarks.yaml")

    def parse_ranges(section: dict) -> dict[str, BenchmarkRange]:
        """Parse a section of benchmark ranges."""
        result = {}
        for key, value in section.items():
            if key in ("source", "version", "last_updated"):
                continue
            if isinstance(value, list) and len(value) == 2:
                result[key] = BenchmarkRange(lower=value[0], upper=value[1])
        return result

    def parse_age_ranges(section: dict) -> dict[str, dict[str, BenchmarkRange]]:
        """Parse age-based benchmark ranges."""
        result = {}
        for age_bracket, ranges in section.items():
            if age_bracket in ("source",):
                continue
            result[age_bracket] = parse_ranges(ranges)
        return result

    return Benchmarks(
        resting_heart_rate=parse_ranges(data["resting_heart_rate"]),
        hrv_by_age=parse_age_ranges(data["hrv_by_age"]),
        blood_oxygen=parse_ranges(data["blood_oxygen"]),
        respiratory_rate=parse_ranges(data["respiratory_rate"]),
        sleep_duration=parse_ranges(data["sleep_duration"]),
        deep_sleep_percentage=parse_ranges(data["deep_sleep_percentage"]),
        rem_sleep_percentage=parse_ranges(data["rem_sleep_percentage"]),
        sleep_efficiency=parse_ranges(data["sleep_efficiency"]),
        recovery_score=parse_ranges(data["recovery_score"]),
        strain=parse_ranges(data["strain"]),
    )


class Config:
    """Central configuration access."""

    def __init__(self, base_path: Path):
        self.base_path = base_path
        self.config_dir = base_path / "config"

        self.pipeline = load_pipeline_config(self.config_dir)
        self.individuals = load_individuals(self.config_dir)
        self.benchmarks = load_benchmarks(self.config_dir)

    def get_raw_data_path(self) -> Path:
        """Get absolute path to raw data."""
        return self.base_path / self.pipeline.raw_data_path

    def get_consolidated_path(self) -> Path:
        """Get absolute path to consolidated data."""
        return self.base_path / self.pipeline.consolidated_path

    def get_snapshots_path(self) -> Path:
        """Get absolute path to snapshots."""
        return self.base_path / self.pipeline.snapshots_path

    def get_latest_symlink_path(self) -> Path:
        """Get absolute path to latest symlink."""
        return self.base_path / self.pipeline.latest_symlink
