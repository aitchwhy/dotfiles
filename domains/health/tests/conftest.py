"""
Pytest configuration and shared fixtures.
"""

import json
import shutil

# Add project root to path
import sys
import tempfile
from collections.abc import Generator
from pathlib import Path

import pandas as pd
import pytest

sys.path.insert(0, str(Path(__file__).parent.parent))


@pytest.fixture
def base_path() -> Path:
    """Get the project base path."""
    return Path(__file__).parent.parent


@pytest.fixture
def config_dir(base_path: Path) -> Path:
    """Get the config directory."""
    return base_path / "config"


@pytest.fixture
def data_dir(base_path: Path) -> Path:
    """Get the data directory."""
    return base_path / "data" / "WHOOP"


@pytest.fixture
def temp_dir() -> Generator[Path]:
    """Create a temporary directory for test outputs."""
    temp = Path(tempfile.mkdtemp())
    yield temp
    shutil.rmtree(temp)


@pytest.fixture
def sample_physiological_data() -> pd.DataFrame:
    """Create sample physiological data for testing."""
    dates = pd.date_range(start="2024-01-01", periods=30, freq="D")
    return pd.DataFrame(
        {
            "Cycle start time": dates,
            "Cycle end time": dates + pd.Timedelta(hours=23),
            "Cycle timezone": "UTC-05:00",
            "Recovery score %": [65 + i % 20 for i in range(30)],
            "Resting heart rate (bpm)": [58 + i % 10 for i in range(30)],
            "Heart rate variability (ms)": [45 + i % 15 for i in range(30)],
            "Skin temp (celsius)": [33.5 + (i % 5) * 0.1 for i in range(30)],
            "Blood oxygen %": [96.0 + (i % 3) * 0.5 for i in range(30)],
            "Day Strain": [10 + i % 8 for i in range(30)],
            "Energy burned (cal)": [1800 + i * 50 for i in range(30)],
            "Max HR (bpm)": [140 + i % 20 for i in range(30)],
            "Average HR (bpm)": [70 + i % 10 for i in range(30)],
            "Sleep onset": dates,
            "Wake onset": dates + pd.Timedelta(hours=7),
            "Sleep performance %": [75 + i % 15 for i in range(30)],
            "Respiratory rate (rpm)": [14.5 + (i % 3) * 0.5 for i in range(30)],
            "Asleep duration (min)": [400 + i % 60 for i in range(30)],
            "In bed duration (min)": [420 + i % 60 for i in range(30)],
            "Light sleep duration (min)": [150 + i % 30 for i in range(30)],
            "Deep (SWS) duration (min)": [90 + i % 20 for i in range(30)],
            "REM duration (min)": [110 + i % 25 for i in range(30)],
            "Awake duration (min)": [15 + i % 10 for i in range(30)],
            "Sleep need (min)": [450 + i % 30 for i in range(30)],
            "Sleep debt (min)": [30 + i % 40 for i in range(30)],
            "Sleep efficiency %": [90 + i % 8 for i in range(30)],
            "Sleep consistency %": [70 + i % 20 for i in range(30)],
        }
    )


@pytest.fixture
def sample_individual_config() -> dict:
    """Create sample individual configuration."""
    return {
        "key": "test_person",
        "folder": "test-person-folder",
        "name": "Test Person",
        "birth_year": 1990,
        "gender": "male",
        "color": "#3498db",
    }


@pytest.fixture
def sample_health_scores() -> dict:
    """Create sample health scores."""
    return {
        "overall": 75.0,
        "cardiovascular": 80.0,
        "respiratory": 90.0,
        "sleep": 85.0,
        "recovery": 60.0,
        "activity": 70.0,
    }


@pytest.fixture
def golden_snapshot_path(base_path: Path) -> Path:
    """Get the path to the golden snapshot for comparison.

    Uses tests/golden_data as the source of truth for deterministic testing.
    This directory contains known-good outputs that CI can verify against.
    """
    golden_dir = base_path / "tests" / "golden_data"
    if golden_dir.exists() and (golden_dir / "manifest.json").exists():
        return golden_dir

    # Fallback to snapshots directory
    snapshots = base_path / "snapshots"
    if snapshots.exists():
        for snapshot_dir in sorted(snapshots.iterdir()):
            if snapshot_dir.is_dir() and (snapshot_dir / "manifest.json").exists():
                return snapshot_dir
    return golden_dir  # Return golden_data path even if it doesn't exist


@pytest.fixture
def golden_manifest(golden_snapshot_path: Path) -> dict:
    """Load the golden manifest for comparison."""
    manifest_path = golden_snapshot_path / "manifest.json"
    if manifest_path.exists():
        with open(manifest_path) as f:
            return json.load(f)
    return {}


@pytest.fixture
def golden_profiles(golden_snapshot_path: Path) -> dict:
    """Load the golden health profiles for comparison."""
    profiles_path = golden_snapshot_path / "health_profiles.json"
    if profiles_path.exists():
        with open(profiles_path) as f:
            return json.load(f)
    return {}
