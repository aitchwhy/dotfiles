# Dotfiles Specifications

This document provides detailed technical specifications for the dotfiles repository, serving as a reference for development and contributions.

## Core Principles

1. **Modularity**: Components should be self-contained and independently useful
2. **XDG Compliance**: Follow XDG Base Directory specification when possible
3. **Consistency**: Maintain consistent style and approach across configurations
4. **Performance**: Optimize for speed and responsiveness
5. **Documentation**: All components should be well-documented
6. **Testability**: Components should be testable in isolation
7. **Security**: Follow security best practices throughout

## System Requirements

- **Operating System**: macOS 13 (Ventura) or newer
- **Architecture**: Apple Silicon (M1/M2/M3 series)
- **Shell**: Zsh 5.9 or newer
- **Package Manager**: Homebrew 4.0 or newer
- **Git**: 2.40 or newer
- **Node.js**: 20.0 or newer (for TypeScript SDK)
- **Python**: 3.10 or newer

## Component Specifications

### AI Integration System

The AI integration system provides a unified interface for leveraging large language models in various development workflows.

#### Core Components

- **Configuration System**:
  - Central YAML configuration (`config/ai/core/config.yaml`)
  - Provider-specific settings
  - Task-specific model recommendations
  - Extensible parameter definitions

- **TypeScript Library**:
  - Type definitions (`config/ai/core/types.ts`)
  - Utility functions (`config/ai/core/utils.ts`)
  - Client abstractions for different providers
  - Error handling and retry mechanisms

- **Prompt System**:
  - Base templates in `config/ai/prompts/base/`
  - Language-specific templates in `config/ai/prompts/code/`
  - Task-specific templates for common operations
  - Variable substitution system for dynamic content

- **Tool Integrations**:
  - Git hooks for commit message generation and validation
  - IDE plugins for VS Code, Neovim, and Cursor
  - API utilities for OpenAPI tooling
  - Shell integrations for command-line access

#### Interfaces

- **CLI Interface**:
  - Just recipes for common operations
  - Consistent command structure
  - Well-documented help system
  - Colorized output

- **TypeScript SDK**:
  - Programmatic access to all functionality
  - Strongly typed interfaces
  - Promise-based async operations
  - Comprehensive error handling

- **Shell Integration**:
  - Bash/Zsh function library
  - Environment variable configuration
  - Command-line completion
  - History integration

#### Provider Support

| Provider | Models | Features | Limitations |
|----------|--------|----------|-------------|
| Anthropic | Claude 3 Opus, Sonnet, Haiku | Robust reasoning, code generation, long contexts | No function calling |
| OpenAI | GPT-4, GPT-3.5 | Function calling, tool use, fine-tuning | Cost, rate limits |
| Google | Gemini Pro, Ultra | Multimodal, large context window | Newer ecosystem |
| Local | Mixtral, Llama 3 | Privacy, no cost, offline usage | Limited capabilities |

### API Utilities

The API namespace provides tools for OpenAPI development, client generation, and testing.

#### OpenAPI Tools

- **Validation**: Spectral and Optic for schema validation
- **Proxying**: API proxying for testing and debugging
- **Mocking**: Mock servers for API testing
- **Client Generation**: TypeScript and Python client generation

#### HTTP Testing

- **Request Building**: Templates for common request types
- **Response Validation**: Schema validation for responses
- **Collection Management**: Bruno file generation for API collections
- **Environment Management**: Support for different environments

### TypeScript SDK

The TypeScript SDK provides programmatic access to all dotfiles functionality.

#### Features

- **Command Execution**: Run just commands programmatically
- **Configuration Management**: Read and update configurations
- **Tool Integration**: Interface with external tools
- **AI Operations**: Access to all AI functionality
- **Type Safety**: Comprehensive TypeScript types

#### Architecture

- **Core Library**: Base functionality and utilities
- **Provider Modules**: Provider-specific implementations
- **Command Modules**: Just command wrappers
- **API Clients**: Generated OpenAPI clients

## API Specifications

### REST API

The REST API implementation follows OpenAPI 3.1 specifications and includes:

- **Server Implementation**:
  - Hono.js for API routing
  - Zod for request/response validation
  - TypeScript 5.5.0 for type safety
  - Vitest for testing

- **Client Libraries**:
  - TypeScript client with Tanstack Query
  - Python 3.12.4 client
  - React components for UI integration

### Schema Definitions

All API schemas follow these conventions:

- **Naming**: PascalCase for schemas, camelCase for properties
- **Documentation**: All schemas and properties must be documented
- **Validation**: Zod schemas for runtime validation
- **Types**: TypeScript interfaces for compile-time safety

## Style Guide

### Code Style

- **TypeScript/JavaScript**: 
  - 2 space indentation
  - Semicolons required
  - Single quotes for strings
  - Trailing commas in multiline
  - ESLint + Prettier configuration

- **Python**: 
  - 4 space indentation
  - PEP 8 compliance
  - Type hints required
  - Ruff for linting
  - Black for formatting

- **Shell**: 
  - 2 space indentation
  - ShellCheck compliance
  - Function documentation
  - Error handling required

### Commit Format

All commits must follow the Conventional Commits specification:

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

Types include: feat, fix, docs, style, refactor, perf, test, build, ci, chore

## Testing Requirements

### Unit Tests

- **TypeScript**: Vitest for unit testing
- **Python**: pytest for unit testing
- **Coverage**: 80% minimum for new code

### Integration Tests

- **API**: MSW for mock service workers
- **CLI**: Tape for command-line interface testing
- **Configuration**: Validation tests for all configurations

## Documentation Standards

### Component Documentation

- **README.md**: Every component must have a README.md file
- **Examples**: Include example usage for all functionality
- **API Reference**: Document all public functions and types
- **Installation**: Include installation instructions if applicable

### Code Documentation

- **TypeScript**: JSDoc for all public functions and types
- **Python**: Google-style docstrings for all functions and classes
- **Shell**: Comment blocks for functions and sections

## Installation Process

The installation process follows these steps:

1. **Environment Check**: Verify system requirements
2. **Directory Setup**: Create necessary directories
3. **Configuration Symlinks**: Create symlinks for all configurations
4. **Package Installation**: Install required packages via Homebrew
5. **Post-Installation**: Run any necessary post-installation tasks
6. **Validation**: Verify installation was successful

## Version Management

- **Semantic Versioning**: Follow SemVer for release versioning
- **Change Log**: Maintain CHANGELOG.md with all changes
- **Release Tagging**: Tag all releases in Git
- **Version File**: Store current version in VERSION.md