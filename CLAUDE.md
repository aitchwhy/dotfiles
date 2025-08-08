# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

### Setup and Installation
```bash
# Initial setup for new macOS machine
./install.sh

# Manual post-installation steps:
source ~/.zshrc
nvm install v22.14.0 && nvm use 22.14.0 && nvm alias default 22.14.0
```

### Development Commands
```bash
# Show available just commands
just --list
just --choose

# System information and checks
just sysinfo              # Show system information
just check-deps           # Check for missing dependencies
just reload               # Reload shell configuration

# Documentation
just readme               # View main README with glow
just prd                  # View PRD with glow

# ANT SDK Commands (if working with ANT)
just ant-sdk-clean        # Clean .NET SDK
just ant-sdk-restore      # Restore dependencies
just ant-sdk-build        # Build SDK
just ant-sdk-test         # Run tests
just ant-sdk-all          # Run all SDK tasks
```

### Git Workflow - Conventional Commits
```bash
# The repository uses conventional commits with commitizen
# Navigate to the git config directory first
cd ~/.config/git/commitizen

# Install commitizen dependencies
npm install

# Create a conventional commit (interactive wizard)
npm run commit
# Or use the git alias if configured:
git cz

# The commit format follows: type(scope): description
# Types: feat, fix, docs, style, refactor, test, chore
```

### Python Development
```bash
# The scripts directory uses uv package manager for Python
cd scripts/

# Install dependencies
uv sync

# Run Python scripts
uv run python google-docs.py
uv run python main.py

# Python formatting (if ruff is installed)
ruff format <file.py>
```

### Linting and Formatting
```bash
# Shell scripts
shfmt -i 2 -ci <file.sh>

# JavaScript/TypeScript (from commitizen directory)
eslint --fix <file.js>

# The repository has lint-staged configured for:
# - JS/TS files: eslint --fix
# - JSON/MD/YAML: prettier --write  
# - Shell scripts: shfmt -i 2 -ci -w
```

## Architecture Overview

### Repository Structure
```
dotfiles/
├── AI/                      # AI tools configuration and prompts
│   ├── ANT/                # Anterior platform specific configs
│   ├── claude/              # Claude-specific configurations
│   ├── prompts/             # Reusable prompt templates
│   └── utils/               # AI utility scripts
├── configs/                 # Application configurations
│   ├── hazel/              # Hazel automation rules
│   └── tableplus/          # TablePlus database connections
├── scripts/                 # Automation scripts
│   ├── google-docs.py      # Google Docs to markdown converter
│   ├── pyproject.toml      # Python project config
│   └── data/               # Script data files
├── .config/git/commitizen/  # Git commit conventions
├── justfile                 # Task runner commands
└── install.sh              # macOS setup script
```

### Key Integration Points

1. **AI Configuration**: The `AI/` directory contains extensive AI tooling configurations including:
   - Claude desktop configurations
   - Prompt engineering templates
   - Provider-specific settings (Claude, GPT, etc.)
   - The ANT platform documentation and workflows

2. **Google Docs Automation**: The `scripts/` directory contains Python scripts for:
   - Downloading Google Docs as markdown
   - Requires Google Cloud service account credentials
   - Uses `google-docs-urls.txt` for batch processing
   - Saves to `downloaded_docs/` directory

3. **Git Workflow**: Conventional commits are enforced via:
   - Commitizen with cz-git adapter
   - Husky for git hooks
   - CommitLint for validation
   - Lint-staged for pre-commit formatting

## Important Context

### User Preferences (from ~/.claude/CLAUDE.md)
- Prioritize clean, maintainable, DRY code
- Implement minimal changesets
- Use semantic variable names (avoid i, j, k)
- Keep functions small and focused
- Write tests before implementation (TDD approach)
- Use TypeScript with strict typing (no `any`)
- Prefer Bun over Node.js for JavaScript projects

### AI Tools Philosophy
- The repository emphasizes AI-powered development workflows
- Extensive prompt templates for various use cases
- Integration with multiple AI providers (Claude, GPT, Gemini)
- Focus on code generation and review automation

### Scripts Directory
When working in the `scripts/` directory:
- Use `uv` package manager for Python dependencies
- Google Docs scripts require service account credentials
- Set `GOOGLE_CREDS_PATH` environment variable or place `credentials.json` locally
- Downloaded documents are sanitized (slashes replaced with dashes)

## Development Best Practices

1. **Commits**: Use conventional commits via `git cz` for consistency
2. **Python**: Use `uv` for package management, `ruff` for formatting
3. **Shell**: Format with `shfmt -i 2 -ci`
4. **Documentation**: Keep README files updated, use glow for viewing
5. **Testing**: Follow TDD principles - write tests first
6. **AI Integration**: Leverage the extensive prompt templates in `AI/prompts/`

## Troubleshooting

- If `just` commands fail, check dependencies with `just check-deps`
- For Python scripts, ensure `uv` is installed and run `uv sync`
- For git commits, ensure you're in `.config/git/commitizen/` and run `npm install`
- Google Docs scripts require valid credentials and API access