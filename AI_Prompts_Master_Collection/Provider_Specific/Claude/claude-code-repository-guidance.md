# Claude Code Repository Guidance

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains multiple projects spanning different languages and technologies:

- **Brrr**: High-performance workflow scheduling system (Python)
- **Zellij**: Terminal workspace/multiplexer (Rust)
- **Obsidian-Vimrc-Support**: Plugin for Obsidian.md
- **Platform/Anterior**: Healthcare platform monorepo (multi-language)
- **Nixos-config**: NixOS configuration system
- Several smaller utilities and tools

## Common Commands

### Nix-based Development (Platform/Anterior)

```bash
# Enter development shell
nix develop

# Build Docker images for development
ant build dev

# Run services locally
ant up

# Run with auto-rebuild on file changes
ant watch

# Populate services with test data
ant populate

# Run all tests and sanity checks
nix flake check -L

# Load testing
ant load-test [API_IP_ADDRESS]
```

### Python Projects (Brrr, workflows)

```bash
# Install dependencies
uv pip install -e .

# Run tests
pytest
pytest -m 'not dependencies'  # Skip tests requiring external dependencies

# Run specific test
pytest tests/test_file.py::test_function -v

# Brrr demo
nix run github:nobssoftware/brrr#demo
curl 'http://localhost:8333/hello?greetee=John'
```

### Rust Projects (Zellij)

```bash
# Run debug build
cargo xtask run

# Run all tests
cargo xtask test

# Build release version
cargo build --release
```

### JavaScript/TypeScript Projects

```bash
# Install dependencies
npm install

# Run linting
npm run lint

# Run tests
npm run test

# Build
npm run build
```

## Architecture

### Brrr

- Queue & database-agnostic workflow scheduling system
- Minimal core with extension points for different backends
- Supports Redis and SQS as queues, DynamoDB as database
- Designed for horizontal scaling

### Platform/Anterior

- Microservices architecture with Docker containerization
- Services communicate via HTTP/REST APIs with OpenAPI specs
- Prefect for workflow orchestration
- Nix for reproducible builds
- Frontend surfaces: Cortex (React/TypeScript)

### Zellij

- Terminal multiplexer with workspace focus
- Plugin system supporting WebAssembly
- Multi-pane layout system with floating windows

## Development Workflows

### Environment Setup

1. Install Nix package manager
2. Run `nix develop` to enter development shell
3. Configure editor with EditorConfig support
4. For secrets, use SOPS with correct key access

### Secret Management

- Secrets stored in `secrets.json` and `secrets.prod.json`
- Use 1Password for secure storage
- Never commit unencrypted secrets

### Running Services

1. Run `ant up` to start all services
2. Use `ant watch` for development with auto-rebuild
3. Access specific service documentation in their respective README files

### Testing

Follow testing protocols specific to each project:
- Python: pytest with appropriate markers
- JavaScript: Jest/Vitest
- Rust: Cargo test suite