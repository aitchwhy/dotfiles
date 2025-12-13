# Life Data System Specification

> **Version**: 1.1.0
> **Last Updated**: 2025-11-30
> **Status**: Active

## 1. Purpose

A reproducible, content-addressable analysis system for personal life data across multiple domains (health, finance) and multiple people. Follows 12-factor app principles adapted for data pipelines.

## 2. Design Principles

| Principle | Description |
|-----------|-------------|
| **Hermetic Execution** | Pipelines run in `nix develop` with pinned dependencies via flake.lock |
| **Content-Addressable** | Snapshots identified by SHA256 hash of inputs |
| **Temporal Chaining** | Each analysis references previous analysis by hash |
| **Domain Isolation** | Per-domain directories with explicit boundaries |
| **Person Isolation** | Per-person data within domains |
| **Spec-Driven** | This document is the source of truth; code implements spec |
| **Minimal Duplication** | One source of truth for data; latest exports only |

## 3. Repository Structure

```
Systems/
├── docs/
│   ├── SPEC.md              # This specification (source of truth)
│   └── architecture/        # ADRs and design docs
├── schemas/                 # CUE validation schemas
│   ├── common.cue
│   ├── health.cue
│   └── finance.cue
├── domains/
│   ├── health/              # Health analytics domain
│   │   ├── config/          # YAML configuration
│   │   ├── data/WHOOP/      # Raw WHOOP exports (latest only)
│   │   ├── pipeline/        # Python analysis code
│   │   ├── snapshots/       # Versioned outputs with manifests
│   │   ├── tests/           # Unit + e2e tests
│   │   ├── justfile         # Domain commands
│   │   └── pyproject.toml   # Dependencies
│   └── finance/             # Finance analytics domain
│       ├── config/
│       ├── data/            # Monarch, Copilot CSVs
│       ├── pipeline/
│       ├── snapshots/
│       ├── tests/
│       ├── justfile
│       └── pyproject.toml
├── tests/e2e/               # Cross-domain integration tests
├── flake.nix                # Nix development environment
├── flake.lock               # Pinned dependencies
├── justfile                 # Root task orchestration
└── pyproject.toml           # Root Python config
```

## 4. Tech Stack (Nov 2025)

| Component | Tool | Version | Notes |
|-----------|------|---------|-------|
| Environment | Nix Flakes | 2.30+ | Determinate Nix on macOS |
| Package Manager | uv | 0.9+ | Fast Python package management |
| Runtime | Python | 3.13 | Via Nix; 3.14 lacks pydantic support |
| Data Processing | Polars | 1.31+ | Fast DataFrame operations |
| Visualization | Matplotlib/Seaborn | Latest | PDF report generation |
| Schema Validation | CUE | 0.9+ | Declarative schema language |
| Data Validation | Pydantic | 2.11+ | Runtime type checking |
| Task Runner | Just | 1.43+ | Make alternative |
| PDF Generation | WeasyPrint | Latest | HTML to PDF |

## 5. Domain: Health

### 5.1 Data Sources
- **WHOOP**: Wearable data exports (physiological_cycles, sleeps, workouts, journal_entries)
- **Medical Records**: MedStar health records (PDFs)

### 5.2 People
| ID | Name | WHOOP Data |
|----|------|------------|
| hank | Jong-Hyun Lee | ✓ |
| ayae | Ayae Yoshimoto | ✓ |
| dad | Il-Keun Lee | ✓ |
| mom | Mi-Hyang Park | ✓ |
| phillip | Jong-Min Lee | ✓ |

### 5.3 Pipeline Stages
```
EXTRACT → CONSOLIDATE → ANALYZE → REPORT
   │           │           │         │
   ▼           ▼           ▼         ▼
 *.zip    merged CSV   profiles   PDFs
```

### 5.4 Snapshot Structure
```
snapshots/{date}_{hash}/
├── manifest.json        # Content-addressable metadata
├── health_profiles.json # Analysis results
├── context_for_next.json # Temporal chaining
├── report_{person}.pdf  # Individual reports
└── summary_report.pdf   # Family comparison
```

### 5.5 Health Metrics
- **Cardiovascular**: HRV, RHR trends
- **Sleep**: Duration, efficiency, consistency
- **Recovery**: Daily recovery scores
- **Strain**: Activity load tracking

## 6. Domain: Finance

### 6.1 Data Sources
- **Monarch Money**: Transaction exports (CSV)
- **Copilot**: Transaction exports (CSV)

### 6.2 Pipeline Stages
```
INGEST → ANALYZE → REPORT
   │         │        │
   ▼         ▼        ▼
 CSV    summaries   markdown
```

## 7. Commands

### Root Commands
```bash
nix develop              # Enter hermetic environment
just                     # Show all commands
just health-run          # Run health pipeline
just health-test         # Run health tests
just finance-test        # Run finance tests
just test-all            # Run all tests
just validate            # Validate CUE schemas
```

### Health Domain Commands
```bash
cd domains/health
just run                 # Full pipeline
just test                # Unit tests
just test-all            # All tests including e2e
```

## 8. Configuration

### 8.1 Environment Variables
```bash
# Optional: Override data paths
WHOOP_DATA_DIR=./data/WHOOP
OUTPUT_DIR=./snapshots
```

### 8.2 Config Files
- `config/pipeline.yaml`: Pipeline settings
- `config/individuals.yaml`: Person definitions
- `config/benchmarks.yaml`: Health metric benchmarks

## 9. Data Management

### 9.1 WHOOP Data Policy
- Keep only **latest** export per person (cumulative data)
- Store in `data/WHOOP/{person-id}/` with `extracted/` subdirectory
- ZIP files retained for audit; CSVs extracted for processing

### 9.2 Snapshot Retention
- All snapshots kept in git for reproducibility
- `manifest.json` enables verification of any historical run

## 10. Testing Strategy

### 10.1 Test Hierarchy
1. **Unit Tests**: Pure functions, no I/O
2. **Integration Tests**: Domain structure validation
3. **E2E Tests**: Full pipeline with golden data

### 10.2 Running Tests
```bash
# Health domain
cd domains/health && uv run pytest tests/unit/ -v

# Finance domain
cd domains/finance && uv run --extra dev pytest tests/ -v

# Cross-domain
uv run pytest tests/e2e/ -v
```

## 11. Adding a New Domain

1. Create `domains/{name}/` with standard structure
2. Add `config/pipeline.yaml` with domain settings
3. Implement pipeline modules in `pipeline/`
4. Add tests in `tests/`
5. Create `justfile` with domain commands
6. Add to root `justfile`
7. Update this spec

## 12. Changelog

| Date | Version | Change |
|------|---------|--------|
| 2025-11-30 | 1.1.0 | Simplified structure: removed lib/core duplicate, updated tech versions |
| 2025-11-29 | 1.0.0 | Initial spec after merge of Health-Analysis + Systems |
