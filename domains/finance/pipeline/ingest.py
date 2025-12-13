"""Ingest financial data from Monarch Money and Copilot exports."""
import polars as pl
from pathlib import Path


def load_monarch_transactions(data_dir: Path) -> pl.DataFrame:
    """Load and normalize Monarch Money transaction exports."""
    csv_files = list(data_dir.glob("*.csv"))
    if not csv_files:
        raise FileNotFoundError(f"No CSV files found in {data_dir}")

    # Load most recent export
    latest = max(csv_files, key=lambda p: p.stat().st_mtime)

    df = pl.read_csv(latest)

    # Normalize column names
    df = df.rename({col: col.lower().replace(" ", "_") for col in df.columns})

    return df


def load_copilot_transactions(data_dir: Path) -> pl.DataFrame:
    """Load and normalize Copilot transaction exports."""
    csv_files = list(data_dir.glob("*.csv"))
    if not csv_files:
        return pl.DataFrame()

    latest = max(csv_files, key=lambda p: p.stat().st_mtime)
    df = pl.read_csv(latest)
    df = df.rename({col: col.lower().replace(" ", "_") for col in df.columns})

    return df
