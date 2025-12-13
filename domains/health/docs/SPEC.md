# HEALTH ANALYSIS SPECIFICATION

**Version**: 2.2.0
**Created**: 2025-11-26
**Updated**: 2025-11-28
**Status**: Active
**Repository**: github.com/aitchwhy/health-analysis

---

## Purpose

This specification is the **single source of truth** for the Health Analysis project. It defines architecture, data management, workflows, and operational procedures. AI assistants (Claude Code) should reference this document to understand project conventions and execute tasks consistently.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Architecture](#2-architecture)
3. [Technology Stack](#3-technology-stack)
4. [Directory Structure](#4-directory-structure)
5. [Data Management](#5-data-management)
6. [Pipeline Specification](#6-pipeline-specification)
7. [Configuration](#7-configuration)
8. [Workflows](#8-workflows)
9. [Testing Strategy](#9-testing-strategy)
10. [CI/CD](#10-cicd)
11. [Security & Privacy](#11-security--privacy)
12. [Migration & Setup](#12-migration--setup)
13. [Future Roadmap](#13-future-roadmap)
14. [Appendices](#14-appendices)

---

## 1. Overview

### 1.1 Project Description

A deterministic, reproducible health data analysis pipeline that processes wearable device exports (WHOOP, Apple Health) and generates actionable health insights for family health optimization. The system supports 5 individuals and is designed to scale to additional data sources.

### 1.2 Design Principles

| Principle | Description |
|-----------|-------------|
| **Determinism** | Same input data produces identical output (minus timestamps) |
| **Reproducibility** | Any historical analysis can be regenerated from raw data |
| **Statelessness** | Pipeline has no side effects on input data |
| **Incrementality** | Each analysis builds on previous analysis context |
| **Extensibility** | Architecture supports future LLM-powered analysis modules |
| **Spec-Driven** | This document is the source of truth; code implements the spec |

### 1.3 Individuals

| Key | Name | Birth Year | Gender |
|-----|------|------------|--------|
| hank | Hank (Jong-Hyun Lee) | 1993 | male |
| dad | Dad (Il-Keun Lee) | 1963 | male |
| mom | Mom (Mi-Hyang Park) | 1965 | female |
| ayae | Ayae Yoshimoto | 1994 | female |
| phillip | Phillip (Jong-Min Lee) | 1997 | male |

---

## 2. Architecture

### 2.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           HEALTH ANALYSIS SYSTEM                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────┐    ┌──────────────────────┐    ┌────────────────┐  │
│  │   Git Repository    │    │   DVC Tracking       │    │  Cloudflare R2 │  │
│  │   (GitHub)          │    │   (.dvc files)       │    │  (Data Store)  │  │
│  ├─────────────────────┤    ├──────────────────────┤    ├────────────────┤  │
│  │ • Source code       │    │ • data/*.dvc         │───▶│ • Apple Health │  │
│  │ • Config files      │───▶│ • .dvc/config        │    │   exports      │  │
│  │ • Small data (<50MB)│    │ • .dvcignore         │    │ • Large ZIPs   │  │
│  │ • DVC metafiles     │    │ • .dvc/cache (local) │    │ • Future data  │  │
│  │ • Snapshots/outputs │    └──────────────────────┘    └────────────────┘  │
│  │ • CI/CD workflows   │                                        ▲           │
│  └─────────────────────┘                                        │           │
│           │                                                      │           │
│           │ git push/pull                              dvc push/pull        │
│           ▼                                                      │           │
│  ┌─────────────────────┐                              ┌──────────────────┐  │
│  │      GitHub         │                              │  Cloudflare R2   │  │
│  │   (Code + Pointers) │                              │   (Data Blobs)   │  │
│  └─────────────────────┘                              └──────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Data Flow Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│                         INPUT LAYER                              │
├─────────────────────────────────────────────────────────────────┤
│  data/{source}/{person}/*.zip  →  Raw exports (DVC-tracked)     │
│  snapshots/{prev}/context_for_next.json  →  Previous context    │
│  config/*.yaml  →  Configuration                                 │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                       EXTRACT STAGE                              │
├─────────────────────────────────────────────────────────────────┤
│  1. Extract all ZIPs to {person}/extracted/                     │
│  2. Compute SHA256 hash of all extracted CSVs                   │
│  3. Generate data_hash for snapshot identification              │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     CONSOLIDATE STAGE                            │
├─────────────────────────────────────────────────────────────────┤
│  1. Load all CSVs for each person                               │
│  2. Deduplicate by (timestamp, metric) - keep latest export     │
│  3. Validate against schema                                      │
│  4. Write to consolidated/*.parquet                             │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                       ANALYZE STAGE                              │
├─────────────────────────────────────────────────────────────────┤
│  1. Load consolidated data                                       │
│  2. Load previous analysis context (if exists)                  │
│  3. Compute health metrics against benchmarks                   │
│  4. Compare with previous analysis (trends, adherence)          │
│  5. Generate recommendations                                     │
│  6. [Future] LLM-powered deep analysis                          │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      VISUALIZE STAGE                             │
├─────────────────────────────────────────────────────────────────┤
│  1. Generate comparison charts                                   │
│  2. Generate individual dashboards                              │
│  3. Generate correlation analyses                               │
│  4. Generate trend comparisons with previous snapshot           │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        REPORT STAGE                              │
├─────────────────────────────────────────────────────────────────┤
│  1. Generate markdown report                                     │
│  2. Generate context_for_next.json                              │
│  3. Write manifest.json with full provenance                    │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        OUTPUT LAYER                              │
├─────────────────────────────────────────────────────────────────┤
│  snapshots/{YYYYMMDD}_{data_hash}/  →  Immutable snapshot       │
│  analysis/  →  Symlink to latest snapshot                       │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Technology Stack

### 3.1 Core Technologies

| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| Language | Python | 3.14+ | Analysis pipeline |
| Code VCS | Git | 2.43+ | Source code version control |
| Data VCS | DVC | 3.64+ | Large file version control |
| Remote Storage | Cloudflare R2 | - | S3-compatible object storage |
| Code Hosting | GitHub | - | Repository hosting, CI/CD |
| Package Manager | uv | 0.9+ | Fast Python dependency management |
| Task Runner | just | 1.43+ | Command runner (replaces Make) |
| File Linting | ls-lint | 2.3+ | File/directory naming conventions |
| Code Linting | Ruff | 0.14+ | Python linting and formatting |
| Type Checking | mypy | 1.18+ | Static type analysis |
| Testing | pytest | 9.0+ | Test framework |

### 3.2 Python Dependencies

**Production** (requirements.txt):
```
pandas>=2.3.0
numpy>=2.3.0
pyyaml>=6.0.0
pyarrow>=22.0.0
matplotlib>=3.10.0
seaborn>=0.13.0
```

**Development** (requirements-dev.txt):
```
pytest>=9.0.0
pytest-cov>=7.0.0
ruff>=0.14.0
mypy>=1.18.0
dvc[s3]>=3.61.0
```

### 3.3 DVC Remote Configuration

**Remote**: Cloudflare R2 (S3-compatible)  
**Bucket**: `health-analysis-data`  
**Endpoint**: `https://<ACCOUNT_ID>.r2.cloudflarestorage.com`

---

## 4. Directory Structure

```
health-analysis/
├── .dvc/                              # DVC configuration (git-tracked)
│   ├── config                         # Remote configuration (no secrets)
│   ├── config.local                   # Local credentials (gitignored)
│   └── .gitignore
├── .dvcignore                         # Files DVC should ignore
├── .git/                              # Git repository
├── .github/
│   └── workflows/
│       └── ci.yml                     # CI/CD pipeline
│
├── config/                            # Configuration files (git-tracked)
│   ├── benchmarks.yaml                # Medical reference standards
│   ├── individuals.yaml               # Person definitions
│   └── pipeline.yaml                  # Pipeline settings
│
├── data/                              # Health data (mixed tracking)
│   ├── WHOOP/                         # WHOOP exports
│   │   ├── {person-folder}/
│   │   │   ├── {export-folder}/       # Contains CSVs (git if <50MB)
│   │   │   │   ├── journal_entries.csv
│   │   │   │   ├── physiological_cycles.csv
│   │   │   │   ├── sleeps.csv
│   │   │   │   └── workouts.csv
│   │   │   └── extracted/             # Extracted data (gitignored)
│   │   └── consolidated/              # Generated parquet (gitignored)
│   │
│   ├── apple-health/                  # Apple Health exports (DVC-tracked)
│   │   └── {person-folder}/
│   │       ├── *.zip                  # Large exports (DVC-tracked)
│   │       └── extracted/             # Parsed XML (gitignored)
│   │
│   ├── medical-records/               # Medical records (future v3.0)
│   │   └── {person-folder}/           # PDFs, FHIR exports
│   │
│   └── apple-health.dvc               # DVC pointer file (git-tracked)
│
├── docs/                              # Documentation
│   └── SPEC.md                        # THIS FILE - source of truth
│
├── pipeline/                          # Analysis code (git-tracked)
│   ├── __init__.py
│   ├── main.py                        # Pipeline orchestrator
│   ├── extract.py                     # Data extraction from ZIPs
│   ├── consolidate.py                 # Deduplication and unification
│   ├── analyze.py                     # Health analysis engine
│   ├── comprehensive_report.py        # Report generation with visualizations
│   ├── context.py                     # Historical context loader
│   ├── config.py                      # Configuration loader
│   ├── schema.py                      # Data schemas and validation
│   └── logging_config.py              # Logging setup
│
├── snapshots/                         # Analysis outputs (git-tracked)
│   └── {YYYYMMDD}_{hash}/
│       ├── manifest.json              # Input/output manifest
│       ├── health_profiles.json       # Structured analysis results
│       ├── report.md                  # Human-readable report
│       ├── context_for_next.json      # Context for next analysis
│       └── visualizations/            # Generated charts (optional)
│
├── tests/                             # Test suite (git-tracked)
│   ├── e2e/
│   │   ├── __init__.py
│   │   └── test_pipeline.py
│   ├── unit/
│   │   ├── __init__.py
│   │   ├── test_analyze.py
│   │   └── test_config.py
│   ├── __init__.py
│   └── conftest.py                    # Pytest fixtures
│
├── .githooks/                         # Git hooks for DVC integration
│   ├── pre-commit                     # Auto-stage DVC files, check naming
│   ├── post-checkout                  # Sync DVC data on checkout
│   └── post-merge                     # Sync DVC data on merge
│
├── analysis/                          # Symlink → latest snapshot
├── .gitignore
├── .ls-lint.yml                       # File naming convention rules
├── .python-version                    # Python version (3.14)
├── justfile                           # Task runner commands
├── pyproject.toml                     # Project metadata
├── requirements.txt
├── requirements-dev.txt
├── README.md
└── run_analysis.py                    # Entry point script
```

---

## 5. Data Management

### 5.1 Tracking Rules

| Data Type | Size Threshold | Tracked By | Storage |
|-----------|----------------|------------|---------|
| Source code (*.py) | Any | Git | GitHub |
| Config (*.yaml) | Any | Git | GitHub |
| Small CSVs | < 50 MB | Git | GitHub |
| Large ZIPs (Apple Health) | ≥ 50 MB | DVC | Cloudflare R2 |
| Generated parquet | Any | Neither | Local only (gitignored) |
| Extracted data | Any | Neither | Local only (gitignored) |
| Analysis snapshots | < 10 MB | Git | GitHub |
| Visualization PNGs | < 5 MB each | Git | GitHub |

### 5.2 DVC Configuration

**.dvc/config** (git-tracked, no secrets):
```ini
[core]
    remote = r2
    autostage = true
['remote "r2"']
    url = s3://health-analysis-data
    endpointurl = https://<ACCOUNT_ID>.r2.cloudflarestorage.com
```

**.dvc/config.local** (gitignored, contains secrets):
```ini
['remote "r2"']
    access_key_id = <ACCESS_KEY>
    secret_access_key = <SECRET_KEY>
```

### 5.3 .gitignore

```gitignore
# Python
__pycache__/
*.py[cod]
.venv/
*.egg-info/

# DVC
.dvc/config.local
.dvc/tmp
.dvc/cache

# Large data files (tracked by DVC)
data/apple-health/**/*.zip

# Generated/extracted data
data/**/extracted/
data/**/consolidated/
*.parquet

# IDE
.idea/
.vscode/
*.swp

# OS
.DS_Store
Thumbs.db
```

### 5.4 .dvcignore

```
# Don't track extracted/generated data with DVC
**/extracted/**
**/consolidated/**

# Small files handled by git
*.csv
*.json
*.yaml
*.yml
*.md
```

---

## 6. Pipeline Specification

### 6.1 Snapshot Identification

Each snapshot is identified by: `{YYYYMMDD}_{data_hash_short}`

- `YYYYMMDD`: Date of analysis run
- `data_hash_short`: First 8 characters of SHA256 hash of all input data

Example: `20251125_e9092910`

### 6.2 Hash Computation

```python
def compute_data_hash(data_dir: Path) -> str:
    """Compute deterministic hash of all input data."""
    hasher = hashlib.sha256()
    
    # Sort files for determinism
    for csv_file in sorted(data_dir.rglob("*.csv")):
        hasher.update(csv_file.name.encode())
        hasher.update(csv_file.read_bytes())
    
    return hasher.hexdigest()
```

### 6.3 Manifest Schema

Each snapshot includes a `manifest.json`:

```json
{
  "version": "1.0.0",
  "snapshot_id": "20251125_e9092910",
  "created_at": "2025-11-25T14:30:00Z",
  "data_hash": "e909291056fcfbfa528f10c1fc7caf31...",
  "input": {
    "individuals": ["hank", "dad", "mom", "ayae", "phillip"],
    "data_files": {
      "hank": ["journal_entries.csv", "physiological_cycles.csv", "sleeps.csv", "workouts.csv"]
    },
    "total_records": 22322,
    "previous_snapshot": "20251120_b8c4d3e2"
  },
  "output": {
    "files": [
      "health_profiles.json",
      "report.md",
      "context_for_next.json"
    ]
  },
  "pipeline": {
    "version": "1.0.0",
    "modules": ["extract", "consolidate", "analyze", "visualize", "report"],
    "duration_seconds": 6.63
  }
}
```

### 6.4 Context Schema

The `context_for_next.json` carries forward analysis state:

```json
{
  "snapshot_id": "20251125_e9092910",
  "analysis_date": "2025-11-25",
  "individuals": {
    "hank": {
      "health_scores": {
        "overall": 80,
        "cardiovascular": 70,
        "respiratory": 90,
        "sleep": 85,
        "recovery": 65,
        "activity": 72
      },
      "key_metrics": {
        "rhr_30day_avg": 56.0,
        "hrv_30day_avg": 78.4
      },
      "recommendations": [
        {
          "id": "hank_sleep_duration_001",
          "category": "Sleep",
          "priority": "HIGH",
          "action": "Extend sleep by 45-60 minutes",
          "status": "open",
          "created": "2025-11-25"
        }
      ],
      "alerts": []
    }
  },
  "family_insights": {
    "shared_concerns": ["sleep_duration"],
    "shared_strengths": ["deep_sleep"]
  }
}
```

### 6.5 CLI Interface

```bash
# Run full pipeline
python -m pipeline.main

# Run specific stages
python -m pipeline.main --stage extract
python -m pipeline.main --stage consolidate
python -m pipeline.main --stage analyze
python -m pipeline.main --stage visualize
python -m pipeline.main --stage report

# Skip stages
python -m pipeline.main --skip-extract --skip-visualize

# Dry run (show what would be done)
python -m pipeline.main --dry-run

# Use specific previous context
python -m pipeline.main --context snapshots/20251120_b8c4d3e2/context_for_next.json

# Force regeneration (ignore existing snapshot with same hash)
python -m pipeline.main --force
```

### 6.6 Weekly Analysis Workflow

The weekly analysis is the **primary review cadence** for actionable health insights. It focuses on recent changes with high priority on the most recent week.

#### 6.6.1 Time-Weighted Analysis Model

| Time Period | Weight | Focus | Purpose |
|-------------|--------|-------|---------|
| Current week vs Previous week | 1.0 | High detail, alerts | Immediate action items |
| 2-4 weeks ago | 0.7 | Trend detection | Short-term patterns |
| 1-3 months ago | 0.4 | Baseline comparison | Monthly trends |
| 3+ months ago | 0.2 | Context only | Long-term reference |

#### 6.6.2 Weekly Report Structure

```
weekly_review_{person}_{YYYYMMDD}.json
{
  "person_key": "hank",
  "review_date": "2025-11-28",
  "data_period": {
    "current_week": {"start": "2025-11-22", "end": "2025-11-28"},
    "previous_week": {"start": "2025-11-15", "end": "2025-11-21"}
  },

  "week_over_week_changes": {
    "cardiovascular": {
      "rhr_change": -2.3,
      "rhr_current": 54.2,
      "rhr_previous": 56.5,
      "trend": "improving",
      "grade": "A",
      "alert_level": "none"
    },
    "sleep": {
      "duration_change_min": +18,
      "duration_current_min": 432,
      "duration_previous_min": 414,
      "trend": "improving",
      "grade": "B+",
      "alert_level": "watch"
    }
  },

  "alerts": [
    {
      "id": "weekly_001",
      "severity": "WARNING",
      "category": "Recovery",
      "metric": "recovery_score",
      "message": "Recovery trending down 12% week-over-week",
      "action": "Consider reducing training intensity"
    }
  ],

  "recommendations_for_next_week": [
    {
      "priority": 1,
      "category": "Sleep",
      "action": "Target 7.5+ hours per night",
      "rationale": "Current 7.2h is below age-optimal 7.5-8h"
    }
  ],

  "long_term_context": {
    "30_day_trend": "stable",
    "90_day_trend": "improving",
    "vs_age_benchmark": "above_average"
  }
}
```

#### 6.6.3 Grading Criteria

| Grade | Description | Week-over-Week Change |
|-------|-------------|----------------------|
| A+ | Exceptional improvement | >15% improvement or optimal range |
| A | Strong improvement | 10-15% improvement |
| B | Moderate improvement | 5-10% improvement |
| C | Stable | ±5% change |
| D | Declining | 5-10% decline |
| F | Significant concern | >10% decline |

#### 6.6.4 Alert Levels

| Level | Trigger | Action |
|-------|---------|--------|
| **CRITICAL** | >20% decline OR medical threshold breach | Immediate review required |
| **WARNING** | 10-20% decline OR approaching threshold | Monitor closely next week |
| **WATCH** | 5-10% decline OR slight concern | Track in next review |
| **NONE** | Stable or improving | Continue current approach |

#### 6.6.5 CLI for Weekly Analysis

```bash
# Run weekly analysis for all individuals
python -m pipeline.weekly

# Run for specific person
python -m pipeline.weekly --person hank

# Specify date range (defaults to last 7 days)
python -m pipeline.weekly --end-date 2025-11-28

# Generate comparison report
python -m pipeline.weekly --compare-weeks 4
```

---

## 7. Configuration

### 7.1 pipeline.yaml

```yaml
version: "1.0.0"

data:
  raw_path: "data/WHOOP"
  consolidated_path: "data/WHOOP/consolidated"

output:
  snapshots_path: "snapshots"
  latest_symlink: "analysis"

analysis:
  rolling_windows:
    short: 7
    medium: 30
    long: 90
  
  thresholds:
    chronic_sleep_debt_min: 60
    low_spo2_percentage: 95
    min_activity_strain: 10
    red_recovery_threshold: 33
    green_recovery_threshold: 67

visualization:
  dpi: 150
  style: "seaborn-v0_8-whitegrid"
  figure_sizes:
    dashboard: [20, 16]
    comparison: [16, 8]
    correlation: [14, 12]

future:
  llm_analysis: false
  llm_model: "claude-sonnet-4-20250514"
```

### 7.2 individuals.yaml

```yaml
individuals:
  hank:
    folder: "hank-jonghyunlee"
    name: "Hank (Jong-Hyun Lee)"
    birth_year: 1993
    gender: "male"
    color: "#3498db"

  dad:
    folder: "dad-ilkeunlee"
    name: "Dad (Il-Keun Lee)"
    birth_year: 1963
    gender: "male"
    color: "#e74c3c"

  mom:
    folder: "mom-mihyangpark"
    name: "Mom (Mi-Hyang Park)"
    birth_year: 1965
    gender: "female"
    color: "#9b59b6"

  ayae:
    folder: "ayae-yoshimoto"
    name: "Ayae Yoshimoto"
    birth_year: 1994
    gender: "female"
    color: "#2ecc71"

  phillip:
    folder: "phillip-jongminlee"
    name: "Phillip (Jong-Min Lee)"
    birth_year: 1997
    gender: "male"
    color: "#f39c12"
```

### 7.3 benchmarks.yaml

Contains medical reference standards from 2024-2025 clinical guidelines for:
- Resting heart rate (by fitness level)
- HRV (by age bracket)
- Blood oxygen (SpO2)
- Respiratory rate
- Sleep duration and architecture
- Recovery scores
- Activity strain levels

See `config/benchmarks.yaml` for full definitions.

---

## 8. Workflows

### 8.1 Adding New Health Data Export

```bash
# 1. Copy export to appropriate location
cp ~/Downloads/apple-health-export-*.zip data/apple-health/hank-jonghyunlee/

# 2. Track with DVC (if large file)
dvc add data/apple-health/

# 3. Stage DVC pointer file for Git
git add data/apple-health.dvc data/apple-health/.gitignore

# 4. Commit both code and data tracking
git commit -m "data: add Apple Health export Nov 2025"

# 5. Push data to R2 and code to GitHub
dvc push
git push
```

### 8.2 Running Analysis

```bash
# Ensure data is current
dvc pull

# Run full pipeline
uv run python -m pipeline.main

# Check outputs
ls -la analysis/
cat analysis/report.md
```

### 8.3 Cloning Repository (Fresh Setup)

```bash
# 1. Clone repository
git clone git@github.com:aitchwhy/health-analysis.git
cd health-analysis

# 2. Install Python dependencies
uv sync

# 3. Install DVC
uv pip install "dvc[s3]>=3.58"

# 4. Configure DVC credentials (one-time setup)
dvc remote modify --local r2 access_key_id <YOUR_ACCESS_KEY>
dvc remote modify --local r2 secret_access_key <YOUR_SECRET_KEY>

# 5. Pull data from R2
dvc pull

# 6. Verify setup
ls -la data/apple-health/hank-jonghyunlee/
```

### 8.4 Updating Dependencies

```bash
# Update Python dependencies
uv sync --upgrade

# Update specific package
uv pip install --upgrade pandas

# Regenerate lock file
uv lock
```

---

## 9. Testing Strategy

### 9.1 Test Categories

| Category | Location | Marker | Purpose |
|----------|----------|--------|---------|
| Unit | tests/unit/ | `@pytest.mark.unit` | Isolated module tests |
| E2E | tests/e2e/ | `@pytest.mark.e2e` | Full pipeline tests |
| Golden | tests/e2e/ | `@pytest.mark.golden` | Output comparison tests |

### 9.2 Running Tests

```bash
# All tests
uv run pytest

# Unit tests only
uv run pytest tests/unit/ -v -m "unit"

# E2E tests only
uv run pytest tests/e2e/ -v -m "e2e"

# With coverage
uv run pytest --cov=pipeline --cov-report=html

# Type checking
uv run mypy pipeline/ --ignore-missing-imports
```

### 9.3 Test Data

Test fixtures use minimal sample data in `tests/fixtures/`. Full data is pulled via DVC only when running E2E/golden tests in CI.

---

## 10. CI/CD

### 10.1 GitHub Actions Workflow

**.github/workflows/ci.yml**:

```yaml
name: CI

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]
  workflow_dispatch:

env:
  PYTHON_VERSION: "3.14"
  UV_VERSION: "0.5.0"

jobs:
  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
        with:
          version: ${{ env.UV_VERSION }}
      - run: uv python install ${{ env.PYTHON_VERSION }}
      - run: uv sync --dev
      - run: uv run ruff check .
      - run: uv run ruff format --check .

  type-check:
    name: Type Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
        with:
          version: ${{ env.UV_VERSION }}
      - run: uv python install ${{ env.PYTHON_VERSION }}
      - run: uv sync --dev
      - run: uv run mypy pipeline/ --ignore-missing-imports
        continue-on-error: true

  test-unit:
    name: Unit Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
        with:
          version: ${{ env.UV_VERSION }}
      - run: uv python install ${{ env.PYTHON_VERSION }}
      - run: uv sync --dev
      - run: uv run pytest tests/unit/ -v -m "unit" --junitxml=junit-unit.xml

  test-e2e:
    name: E2E Tests
    runs-on: ubuntu-latest
    env:
      DVC_REMOTE_R2_ACCESS_KEY_ID: ${{ secrets.R2_ACCESS_KEY_ID }}
      DVC_REMOTE_R2_SECRET_ACCESS_KEY: ${{ secrets.R2_SECRET_ACCESS_KEY }}
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
        with:
          version: ${{ env.UV_VERSION }}
      - run: uv python install ${{ env.PYTHON_VERSION }}
      - run: uv sync --dev
      - name: Configure DVC
        run: |
          dvc remote modify --local r2 access_key_id $DVC_REMOTE_R2_ACCESS_KEY_ID
          dvc remote modify --local r2 secret_access_key $DVC_REMOTE_R2_SECRET_ACCESS_KEY
      - run: dvc pull
      - run: uv run pytest tests/e2e/ -v -m "e2e"

  pipeline-smoke:
    name: Pipeline Smoke Test
    runs-on: ubuntu-latest
    env:
      DVC_REMOTE_R2_ACCESS_KEY_ID: ${{ secrets.R2_ACCESS_KEY_ID }}
      DVC_REMOTE_R2_SECRET_ACCESS_KEY: ${{ secrets.R2_SECRET_ACCESS_KEY }}
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
        with:
          version: ${{ env.UV_VERSION }}
      - run: uv python install ${{ env.PYTHON_VERSION }}
      - run: uv sync --dev
      - name: Configure DVC
        run: |
          dvc remote modify --local r2 access_key_id $DVC_REMOTE_R2_ACCESS_KEY_ID
          dvc remote modify --local r2 secret_access_key $DVC_REMOTE_R2_SECRET_ACCESS_KEY
      - run: dvc pull
      - run: uv run python -m pipeline.main --force
      - name: Verify outputs
        run: |
          test -L analysis || test -d analysis
          test -f analysis/manifest.json
          test -f analysis/health_profiles.json
```

### 10.2 Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `R2_ACCESS_KEY_ID` | Cloudflare R2 API access key |
| `R2_SECRET_ACCESS_KEY` | Cloudflare R2 API secret key |

---

## 11. Security & Privacy

### 11.1 Data Classification

| Classification | Examples | Handling |
|----------------|----------|----------|
| PHI (Protected Health Information) | Health exports, metrics | Encrypted at rest (R2), access controlled |
| Configuration | API keys, credentials | Never committed, stored in .local files |
| Public | Source code, documentation | Git-tracked, public if repo is public |

### 11.2 Credential Management

- **Local development**: `.dvc/config.local` (gitignored)
- **CI/CD**: GitHub encrypted secrets
- **Secure storage**: Store R2 credentials in 1Password or similar

### 11.3 R2 Security

- Bucket is **private by default** (no public access)
- API tokens scoped to specific bucket with minimal permissions
- HTTPS enforced for all data transfer
- AES-256 encryption at rest

---

## 12. Migration & Setup

### 12.1 Initial Repository Setup (One-Time)

This section documents the migration from the original git-only approach to DVC + R2.

#### Phase 1: Clean Git History

```bash
# Backup first
cp -r health-analysis health-analysis-backup

# Install git-filter-repo
pip install git-filter-repo

# Remove large files from history
git filter-repo --strip-blobs-bigger-than 50M --force

# Re-add remote (filter-repo removes it)
git remote add origin git@github.com:aitchwhy/health-analysis.git
```

#### Phase 2: Set Up Cloudflare R2

1. Create R2 bucket named `health-analysis-data` in Cloudflare Dashboard
2. Create API token with Object Read & Write permissions
3. Note your Account ID for the endpoint URL

#### Phase 3: Initialize DVC

```bash
# Install DVC
pip install "dvc[s3]>=3.58"

# Initialize in repo
dvc init

# Configure R2 remote
dvc remote add -d r2 s3://health-analysis-data
dvc remote modify r2 endpointurl https://<ACCOUNT_ID>.r2.cloudflarestorage.com
dvc remote modify --local r2 access_key_id <ACCESS_KEY>
dvc remote modify --local r2 secret_access_key <SECRET_KEY>

# Enable autostage
dvc config core.autostage true
```

#### Phase 4: Track Data

```bash
# Track Apple Health exports with DVC
dvc add data/apple-health/

# Commit DVC configuration
git add .dvc/ .dvcignore data/apple-health.dvc .gitignore
git commit -m "feat: initialize DVC with Cloudflare R2"

# Push data to R2
dvc push

# Push code to GitHub
git push --force-with-lease origin main
```

#### Phase 5: Configure CI/CD

1. Add GitHub Secrets: `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`
2. Update `.github/workflows/ci.yml` with DVC configuration

### 12.2 New Developer Setup

```bash
# Clone
git clone git@github.com:aitchwhy/health-analysis.git
cd health-analysis

# Dependencies
uv sync
uv pip install "dvc[s3]>=3.58"

# Get credentials from team lead/1Password
dvc remote modify --local r2 access_key_id <KEY>
dvc remote modify --local r2 secret_access_key <SECRET>

# Pull data
dvc pull

# Verify
python -m pipeline.main --dry-run
```

---

## 13. Future Roadmap

### 13.1 Version 2.1: LLM Integration

```python
class LLMAnalyzer:
    """LLM-powered analysis capabilities."""
    
    def analyze_trends(self, current: Analysis, previous: Context) -> Insights:
        """Deep trend analysis using Claude."""
        pass
    
    def generate_personalized_plan(self, profile: HealthProfile) -> ActionPlan:
        """Generate personalized health improvement plan."""
        pass
    
    def assess_recommendation_adherence(
        self,
        previous_recommendations: list[Recommendation],
        current_metrics: Metrics
    ) -> AdherenceReport:
        """Assess whether previous recommendations were followed."""
        pass
```

### 13.2 Version 3.0: Additional Data Sources

```
data/
├── WHOOP/           # Existing
├── apple-health/    # Existing
├── oura/            # Oura Ring
├── blood-tests/     # Lab results
├── nutrition/       # Food logs
└── medical-records/ # PHR exports (FHIR format)
```

### 13.3 Version 4.0: Platform

- Web dashboard for family members
- Mobile app integration
- Real-time alerts and notifications
- Multi-family support

---

## 14. Appendices

### 14.1 Quick Reference Commands

```bash
# === just Commands (unified interface) ===
just                    # Show all available commands
just push               # Push code (git) and data (dvc) together
just pull               # Pull code (git) and data (dvc) together
just sync               # Full sync (pull then push)
just data-add           # Add data changes to DVC
just status             # Show git and dvc status
just setup              # Configure git hooks

# === Development Commands ===
just run                # Run the analysis pipeline
just run --force        # Force regenerate
just test               # Run unit tests
just test-all           # Run all tests
just lint               # Check code style
just fmt                # Format code
just check              # Run all checks (lint + format + file naming)
just lint-files         # Check file naming conventions

# === Direct DVC Commands (if needed) ===
dvc add data/path/      # Track data
dvc status              # Check sync status
dvc gc --workspace      # Clean old cache

# === Git + DVC Manual Workflow ===
dvc add data/apple-health/
git add data/apple-health.dvc .gitignore
git commit -m "data: add export"
just push               # Unified push
```

### 14.2 Environment Variables

```bash
# Alternative to config.local (for CI/CD)
export DVC_REMOTE_R2_ACCESS_KEY_ID=xxx
export DVC_REMOTE_R2_SECRET_ACCESS_KEY=xxx
```

### 14.3 Troubleshooting

| Problem | Solution |
|---------|----------|
| `git push` fails (large file) | Check if file should be DVC-tracked; run `dvc add` |
| `dvc pull` timeout | Check network; verify credentials in config.local |
| Pipeline fails on missing data | Run `dvc pull` first |
| Tests fail in CI | Ensure GitHub secrets are configured |

### 14.4 Cost Estimation

**Cloudflare R2 (estimated monthly)**:

| Resource | Price | Usage | Cost |
|----------|-------|-------|------|
| Storage | $0.015/GB | 10 GB | $0.15 |
| Class A ops | $4.50/M | 1,000 | $0.00 |
| Class B ops | $0.36/M | 10,000 | $0.00 |
| Egress | $0.00/GB | Unlimited | $0.00 |
| **Total** | | | **~$0.15** |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-11-25 | Initial pipeline specification |
| 2.0.0 | 2025-11-26 | Added data management with DVC + R2, comprehensive rewrite |
| 2.1.0 | 2025-11-26 | Upgraded to Python 3.14, latest dependencies (Nov 2025) |
| 2.2.0 | 2025-11-28 | Added just task runner, ls-lint file naming, git hooks, cleaned dead code |

---

## References

- [DVC Documentation](https://dvc.org/doc)
- [Cloudflare R2 Documentation](https://developers.cloudflare.com/r2/)
- [uv Documentation](https://docs.astral.sh/uv/)
- [Ruff Documentation](https://docs.astral.sh/ruff/)
- [just Documentation](https://just.systems/man/en/)
- [ls-lint Documentation](https://ls-lint.org/)
