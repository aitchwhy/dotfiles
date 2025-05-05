# AI Directory Structure

This directory contains all AI-related configurations, tools, and utilities for enhancing your development workflows through AI integration.

## Directory Structure

```
config/ai/
├── claude/               # Claude-specific configuration files
├── cline/                # Cline (Claude CLI) configuration
├── history/              # AI conversation history exports
├── integrations/         # Integration files for various tools
│   └── api-justfile      # API namespace for REST API utilities
├── justfile              # Main AI command structure
├── models/               # AI model definitions and capabilities
│   └── llms.yaml         # LLM definitions with capabilities
├── preferences/          # User preferences extracted from AI interactions
├── prompts/              # Prompt templates for different AI tasks
│   ├── language-specific/  # Templates for different programming languages
│   └── task-specific/      # Templates for different task types
├── providers/            # Provider-specific configuration
│   ├── anthropic/
│   ├── claude/
│   ├── cursor/
│   ├── gemini/
│   └── openai/
├── templates/            # Code, document, and prompt templates
└── utils/                # Utility scripts for AI operations
    ├── ai_bash.sh        # Bash scripts for AI commands
    └── typescript/       # TypeScript library for AI commands
```

## Main Components

### Claude Code Integration

The `claude` directory contains configuration files for Claude Code, Anthropic's AI coding assistant. The `history` directory stores conversation exports from Claude Code sessions.

### Command Structure

The `justfile` provides a comprehensive set of AI commands organized into namespaces:

- `ai:` - Core AI operations
- `ai:typescript` - TypeScript-specific AI commands
- `ai:python` - Python-specific AI commands
- `ai:shell` - Shell scripting AI commands
- `ai:nix` - Nix-related AI commands
- `ai:run` - AI-powered operations
- `api:` - REST API utilities powered by AI

### Model Definitions

The `models/llms.yaml` file contains detailed information about AI models, their capabilities, and recommended use cases. This serves as a central reference for all AI model configuration.

### Provider Configuration

Each AI provider has its own directory in `providers/` containing configuration files, API settings, and provider-specific utilities.

### Templates and Prompts

The `templates/` and `prompts/` directories contain reusable templates for different tasks, languages, and scenarios, making it easy to create consistent AI-driven workflows.

## Usage

To use these AI tools, you can leverage the justfile command structure:

```bash
# List all available AI commands
just ai

# Run a specific AI command
just ai:code typescript "Write a function that does X"

# Generate a commit message with AI
just ai:commit-msg

# Run the API utilities
just api
```

## Adding New AI Tools

To add a new AI tool or configuration:

1. Create a new directory in the appropriate location (e.g., providers/new-provider/)
2. Add configuration files and templates
3. Update the justfile to include commands for the new tool
4. Document the new tool in this README.md

## Related Files

- `/Users/hank/dotfiles/SPECIFICATIONS.yml` - Contains specifications for AI tools
- `/Users/hank/dotfiles/config/git/gitconfig` - Git integration with AI for commit messages
- `/Users/hank/dotfiles/config/git/gitmessage` - Commit message template with AI assistance