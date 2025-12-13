# Health Analysis Pipeline

A deterministic, reproducible health data analysis pipeline for wearable device exports (WHOOP, Apple Health).

## Features

- **Deterministic**: Same input data produces identical output
- **Snapshot-based**: Each analysis creates a timestamped snapshot with data hash
- **Incremental context**: Each analysis considers previous analysis for trend comparison
- **Multi-person**: Analyzes data for multiple family members
- **Medical benchmarks**: Compares metrics against 2024-2025 clinical guidelines
- **DVC-managed**: Large data files tracked with DVC and stored in Cloudflare R2

## Quick Start

```bash
# Install dependencies
uv sync

# Install DVC for large file management (optional)
uv pip install "dvc[s3]>=3.58"

# Pull data from R2 (if configured)
dvc pull

# Run the analysis pipeline
uv run python -m pipeline.main
```

## Usage

```bash
# Run full pipeline
python -m pipeline.main

# Force regeneration (even if snapshot exists)
python -m pipeline.main --force

# Run specific stage only
python -m pipeline.main --stage analyze

# Skip stages
python -m pipeline.main --skip-extract --skip-visualize

# Use specific previous context
python -m pipeline.main --context snapshots/20251120_abc123/context_for_next.json

# Dry run (show what would be done)
python -m pipeline.main --dry-run
```

## Directory Structure

```
health-analysis/
├── .dvc/                    # DVC configuration
├── config/
│   ├── pipeline.yaml        # Pipeline configuration
│   ├── individuals.yaml     # Person definitions
│   └── benchmarks.yaml      # Medical reference standards
├── data/
│   ├── WHOOP/               # WHOOP exports (git-tracked)
│   ├── apple-health/        # Apple Health exports (DVC-tracked)
│   └── medical-records/     # Medical records (future)
├── docs/
│   └── SPEC.md              # Full technical specification
├── pipeline/
│   ├── main.py              # Orchestrator
│   ├── extract.py           # ZIP extraction
│   ├── consolidate.py       # Data deduplication
│   ├── analyze.py           # Health analysis
│   ├── visualize.py         # Chart generation
│   ├── report.py            # Report generation
│   └── context.py           # Historical context
├── snapshots/
│   └── {YYYYMMDD}_{hash}/   # Analysis snapshots
└── analysis -> snapshots/latest  # Symlink to latest
```

## Adding New Data

### WHOOP Data (< 50MB)
```bash
# 1. Place ZIP in person's folder
cp export.zip data/WHOOP/{person-folder}/

# 2. Run pipeline
python -m pipeline.main
```

### Apple Health Data (≥ 50MB, DVC-tracked)
```bash
# 1. Place ZIP in person's folder
cp export.zip data/apple-health/{person-folder}/

# 2. Track with DVC
dvc add data/apple-health/

# 3. Commit changes
git add data/apple-health.dvc .gitignore
git commit -m "data: add Apple Health export"

# 4. Push to R2
dvc push
git push
```

## Snapshot Identification

Each snapshot is identified by: `{YYYYMMDD}_{data_hash}`

- Date component allows chronological sorting
- Hash component ensures same data produces same ID
- Re-running with unchanged data skips regeneration

## Configuration

### Adding a new person

Edit `config/individuals.yaml`:

```yaml
individuals:
  newperson:
    folder: "newperson-folder-name"
    name: "Display Name"
    birth_year: 1990
    gender: "male"
    color: "#hexcolor"
```

## Documentation

See `docs/SPEC.md` for the full technical specification including:

- Complete architecture and data flow
- DVC and Cloudflare R2 configuration
- CI/CD workflows
- Security and privacy considerations
