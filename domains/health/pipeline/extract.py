"""
Data extraction module.

Extracts WHOOP data from ZIP files and computes deterministic hashes.
Handles merging of CSV files from multiple exports.
"""

import csv
import hashlib
import zipfile
from io import StringIO
from pathlib import Path

from .config import Config
from .schema import Individual


def merge_csv_content(existing_content: str, new_content: str) -> str:
    """
    Merge two CSV contents, keeping unique rows based on first column (timestamp).

    This handles the WHOOP export format where each ZIP has the same filenames
    but different date ranges.
    """
    if not existing_content:
        return new_content
    if not new_content:
        return existing_content

    # Parse existing
    existing_reader = csv.reader(StringIO(existing_content))
    existing_rows = list(existing_reader)
    if not existing_rows:
        return new_content

    header = existing_rows[0]
    existing_data = {row[0]: row for row in existing_rows[1:] if row}

    # Parse new
    new_reader = csv.reader(StringIO(new_content))
    new_rows = list(new_reader)
    if not new_rows:
        return existing_content

    # Merge (new overwrites existing for same timestamp)
    for row in new_rows[1:]:
        if row:
            existing_data[row[0]] = row

    # Sort by first column (timestamp) and rebuild CSV
    sorted_rows = sorted(existing_data.values(), key=lambda x: x[0], reverse=True)

    output = StringIO()
    writer = csv.writer(output)
    writer.writerow(header)
    writer.writerows(sorted_rows)

    return output.getvalue()


def extract_zip(zip_path: Path, output_dir: Path) -> list[Path]:
    """Extract a ZIP file to output directory, merging with existing CSVs."""
    output_dir.mkdir(parents=True, exist_ok=True)

    extracted_files = []
    with zipfile.ZipFile(zip_path, "r") as zf:
        for member in zf.namelist():
            if member.endswith(".csv"):
                output_path = output_dir / member

                # Read new content from ZIP
                new_content = zf.read(member).decode("utf-8")

                # If file exists, merge contents
                if output_path.exists():
                    existing_content = output_path.read_text()
                    merged_content = merge_csv_content(existing_content, new_content)
                    output_path.write_text(merged_content)
                else:
                    output_path.write_text(new_content)

                extracted_files.append(output_path)

    return extracted_files


def extract_all_for_individual(individual: Individual, raw_data_path: Path) -> list[Path]:
    """Extract all ZIP files for an individual, merging data from all exports."""
    person_dir = raw_data_path / individual.folder
    extracted_dir = person_dir / "extracted"

    # Clear existing extracted files to ensure clean merge
    if extracted_dir.exists():
        for f in extracted_dir.glob("*.csv"):
            f.unlink()
    extracted_dir.mkdir(parents=True, exist_ok=True)

    all_extracted = []

    # Find all ZIP files, sort by date in filename (oldest first for proper merge)
    zip_files = sorted(person_dir.glob("*.zip"))

    for zip_path in zip_files:
        try:
            files = extract_zip(zip_path, extracted_dir)
            all_extracted.extend(files)
        except zipfile.BadZipFile:
            print(f"Warning: Could not extract {zip_path}")

    return list(set(all_extracted))  # Dedupe since same files are merged


def extract_all(config: Config) -> dict[str, list[Path]]:
    """Extract all ZIP files for all individuals."""
    raw_data_path = config.get_raw_data_path()

    extracted = {}
    for key, individual in config.individuals.items():
        files = extract_all_for_individual(individual, raw_data_path)
        extracted[key] = files
        print(f"Extracted {len(files)} files for {individual.name}")

    return extracted


def compute_file_hash(file_path: Path) -> str:
    """Compute SHA256 hash of a file."""
    hasher = hashlib.sha256()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


def compute_data_hash(config: Config) -> str:
    """
    Compute deterministic hash of all input data.

    This hash uniquely identifies the input data state and is used
    for snapshot identification.
    """
    hasher = hashlib.sha256()
    raw_data_path = config.get_raw_data_path()

    # Collect all CSV files across all individuals
    all_csv_files = []
    for individual in config.individuals.values():
        person_dir = raw_data_path / individual.folder / "extracted"
        if person_dir.exists():
            all_csv_files.extend(person_dir.glob("*.csv"))

    # Sort for determinism
    all_csv_files = sorted(all_csv_files)

    for csv_file in all_csv_files:
        # Include relative path for uniqueness
        rel_path = csv_file.relative_to(raw_data_path)
        hasher.update(str(rel_path).encode())
        hasher.update(csv_file.read_bytes())

    return hasher.hexdigest()


def get_data_summary(config: Config) -> dict:
    """Get summary of available data."""
    raw_data_path = config.get_raw_data_path()

    summary = {
        "individuals": [],
        "data_files": {},
        "total_records": 0,
    }

    for key, individual in config.individuals.items():
        person_dir = raw_data_path / individual.folder / "extracted"
        if person_dir.exists():
            summary["individuals"].append(key)
            summary["data_files"][key] = []

            for csv_file in sorted(person_dir.glob("*.csv")):
                summary["data_files"][key].append(csv_file.name)

                # Count records (lines - header)
                with open(csv_file) as f:
                    line_count = sum(1 for _ in f) - 1
                    summary["total_records"] += max(0, line_count)

    return summary
