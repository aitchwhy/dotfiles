# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This repository contains multiple related projects:

- `/foundations/` - Monorepo with various Python projects, including the router project
- `/platform/` and `/platform-lib-api-extractor/` - Frontend and backend application codebases
- `/ant-pdf-processor/` - PDF processing service 
- `/anterior/` - Various projects and scripts
- `/vibes/`, `/rowboat/`, `/awesome-keys/` - Utility projects and tools

## Key Commands

### Python Projects

Python projects use `uv` for environment management:

```bash
# Setup virtual environment
cd <project_dir>
uv venv
# Activate the virtual environment (follow printed instructions)
uv sync

# Run tests (unit tests that don't depend on external services)
pytest -m 'not dependencies'

# Run a specific test
pytest path/to/test_file.py::TestClass::test_function -v

# Run tests with markers
pytest -m "unit"
pytest -m "integration"

# Lint code
ruff check
ruff check --fix  # Auto-fix linting issues

# Format code
ruff format

# Setup pre-commit
python scripts/setup_precommit.py
```

### JavaScript/TypeScript Projects

JavaScript/TypeScript projects use NPM workspaces:

```bash
# Set up local JS environment
nix develop .#npm

# Install dependencies
npm install --strict-peer-deps true --prefer-dedupe true

# Add a new dependency
npm install --strict-peer-deps true --prefer-dedupe true -S your-new-dependency

# Build a workspace
npm run --workspace your/dir build

# Run unit tests
npm run --workspace your/dir test
```

### Nix Commands

```bash
# Build and check everything
nix flake check -L

# Format files
nix fmt

# Enter development shell
nix develop
```

### Docker Commands

```bash
# Build docker images
ant build dev

# Run services locally
ant up

# Watch for changes and rebuild/restart
ant watch

# Run with code regeneration
ant regen proto
ant regen models
ant regen openapi-client
```

### PDF Processor

For the ant-pdf-processor project:

```bash
# Install dependencies
poetry install
poetry shell

# Run the API locally
uvicorn ant_pdf_processor.main:app --reload

# Deploy to GCP Cloud Run
./build_and_deploy.sh
```

## High-Level Code Architecture

The repository contains several key components:

1. **Platform** - A monorepo with a microservices architecture that's transitioning away from gRPC/protobuf toward a more unified API gateway (Noggin). Contains:
   - Services in Python, Go, and TypeScript
   - Gateways (including Noggin API Gateway)
   - Surfaces (frontend applications, including Cortex)
   - Workflows (async tasks using Prefect)

2. **Foundations** - Contains core libraries and utilities:
   - Router - Core routing service for handling external requests
   - IAC - Infrastructure as code components
   - SDK - Client libraries for interacting with services

3. **PDF Processor** - A standalone service for processing PDFs, which can be deployed to GCP Cloud Run.

## Technology Stack

- **Languages**: Python 3.12, TypeScript, Go
- **Python Package Management**: uv
- **JavaScript Package Management**: NPM workspaces
- **Build System**: Nix, Docker
- **API Frameworks**: FastAPI
- **Frontend**: NextJS
- **CI/CD**: GitHub Actions, Nix
- **Infrastructure**: AWS, GCP Cloud Run
- **Async Workflow**: Prefect
- **Secrets Management**: SOPS with AWS KMS

## Development Patterns

### Python Conventions

- Python 3.12 is the standard version
- Use Google-style docstrings only when they provide genuine value
- Type annotations are required for all functions and variables
- Follow DRY principles and prefer OOP patterns when appropriate
- Functional core, imperative shell: keep business logic as pure functions

### JavaScript/TypeScript Conventions

- Separate build and run steps
- Use NPM workspaces for managing dependencies
- No bun lockfiles, only one package-lock.json at the root
- Unit tests must be runnable without environment variables or other services

### Testing Philosophy

- Test behavior, not implementation
- Prefer real implementations over mocks when possible
- Mock only external dependencies when necessary
- Use pytest fixtures effectively
- Keep test code clean and organized

### Code Organization

- Follow existing code conventions in the repository
- Respect module boundaries and dependency structure
- Keep related code together
- Provide appropriate documentation