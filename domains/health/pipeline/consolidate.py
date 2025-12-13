"""
Data consolidation module.

Deduplicates and unifies data from multiple WHOOP exports.
"""

from datetime import date
from pathlib import Path

import pandas as pd

from .config import Config
from .schema import (
    JOURNAL_COLUMNS,
    PHYSIOLOGICAL_COLUMNS,
    SLEEP_COLUMNS,
    WORKOUT_COLUMNS,
    DataRange,
    Individual,
    validate_dataframe,
)


def load_csv_files(directory: Path, pattern: str) -> pd.DataFrame:
    """Load and concatenate all CSV files matching pattern."""
    files = sorted(directory.glob(pattern))
    if not files:
        return pd.DataFrame()

    dfs = []
    for f in files:
        try:
            df = pd.read_csv(f)
            dfs.append(df)
        except Exception as e:
            print(f"Warning: Could not load {f}: {e}")

    if not dfs:
        return pd.DataFrame()

    return pd.concat(dfs, ignore_index=True)


def deduplicate_by_timestamp(
    df: pd.DataFrame, timestamp_col: str = "Cycle start time"
) -> pd.DataFrame:
    """
    Deduplicate DataFrame by timestamp.

    Keeps the last occurrence (from most recent export).
    """
    if df.empty or timestamp_col not in df.columns:
        return df

    # Parse timestamp
    df[timestamp_col] = pd.to_datetime(df[timestamp_col], errors="coerce")

    # Sort by timestamp and drop duplicates keeping last
    df = df.sort_values(timestamp_col)
    df = df.drop_duplicates(subset=[timestamp_col], keep="last")

    return df.reset_index(drop=True)


def load_individual_data(individual: Individual, raw_data_path: Path) -> dict[str, pd.DataFrame]:
    """Load all data for an individual."""
    person_dir = raw_data_path / individual.folder / "extracted"

    if not person_dir.exists():
        return {}

    data = {}

    # Load physiological cycles
    physio_files = list(person_dir.glob("*physiological_cycles.csv"))
    if physio_files:
        df = load_csv_files(person_dir, "*physiological_cycles.csv")
        df = deduplicate_by_timestamp(df, "Cycle start time")
        validate_dataframe(df, PHYSIOLOGICAL_COLUMNS, "physiological_cycles")
        data["physiological"] = df

    # Load sleep data
    sleep_files = list(person_dir.glob("*sleeps.csv"))
    if sleep_files:
        df = load_csv_files(person_dir, "*sleeps.csv")
        df = deduplicate_by_timestamp(df, "Sleep onset")
        validate_dataframe(df, SLEEP_COLUMNS, "sleeps")
        data["sleep"] = df

    # Load workout data
    workout_files = list(person_dir.glob("*workouts.csv"))
    if workout_files:
        df = load_csv_files(person_dir, "*workouts.csv")
        df = deduplicate_by_timestamp(df, "Workout start time")
        validate_dataframe(df, WORKOUT_COLUMNS, "workouts")
        data["workouts"] = df

    # Load journal entries
    journal_files = list(person_dir.glob("*journal_entries.csv"))
    if journal_files:
        df = load_csv_files(person_dir, "*journal_entries.csv")
        # Journal entries are deduplicated by timestamp + question
        if not df.empty and "Cycle start time" in df.columns and "Question text" in df.columns:
            df["Cycle start time"] = pd.to_datetime(df["Cycle start time"], errors="coerce")
            df = df.drop_duplicates(subset=["Cycle start time", "Question text"], keep="last")
        validate_dataframe(df, JOURNAL_COLUMNS, "journal_entries")
        data["journal"] = df

    return data


def get_data_range(df: pd.DataFrame, timestamp_col: str = "Cycle start time") -> DataRange:
    """Get the date range of a DataFrame."""
    if df.empty or timestamp_col not in df.columns:
        return DataRange(start=date.today(), end=date.today(), days=0)

    timestamps = pd.to_datetime(df[timestamp_col], errors="coerce").dropna()
    if timestamps.empty:
        return DataRange(start=date.today(), end=date.today(), days=0)

    start = timestamps.min().date()
    end = timestamps.max().date()
    days = len(df)

    return DataRange(start=start, end=end, days=days)


def consolidate_individual(
    individual: Individual, raw_data_path: Path, output_path: Path
) -> dict[str, pd.DataFrame]:
    """Consolidate all data for an individual."""
    data = load_individual_data(individual, raw_data_path)

    if not data:
        return {}

    # Create output directory
    person_output = output_path / individual.key
    person_output.mkdir(parents=True, exist_ok=True)

    # Save as parquet for efficient storage and loading
    for name, df in data.items():
        if not df.empty:
            parquet_path = person_output / f"{name}.parquet"
            df.to_parquet(parquet_path, index=False)

    return data


def consolidate_all(config: Config) -> dict[str, dict[str, pd.DataFrame]]:
    """Consolidate data for all individuals."""
    raw_data_path = config.get_raw_data_path()
    output_path = config.get_consolidated_path()

    output_path.mkdir(parents=True, exist_ok=True)

    all_data = {}
    for key, individual in config.individuals.items():
        data = consolidate_individual(individual, raw_data_path, output_path)
        if data:
            all_data[key] = data
            physio_range = get_data_range(data.get("physiological", pd.DataFrame()))
            print(
                f"Consolidated {individual.name}: {physio_range.days} days "
                f"({physio_range.start} to {physio_range.end})"
            )

    return all_data


def load_consolidated_data(config: Config) -> dict[str, dict[str, pd.DataFrame]]:
    """Load previously consolidated data."""
    output_path = config.get_consolidated_path()

    all_data = {}
    for key, _individual in config.individuals.items():
        person_dir = output_path / key

        if not person_dir.exists():
            continue

        data = {}
        for parquet_file in person_dir.glob("*.parquet"):
            name = parquet_file.stem
            data[name] = pd.read_parquet(parquet_file)

        if data:
            all_data[key] = data

    return all_data
