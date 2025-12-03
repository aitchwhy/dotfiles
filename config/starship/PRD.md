# Starship Configuration Requirements

This document captures the requirements, preferences, and design principles for the Starship prompt configuration.

## Core Requirements

### 1. Appearance and Design

- **Tokyo Night Theme**: Use Tokyo Night color palette consistently
- **Clean Layout**: Minimal but informative prompt design
- **Two-Line Prompt**: Command input on a separate line
- **Right Prompt**: Time and battery on right side
- **Icons**: Nerd Font icons for visual information
- **Colors**: Color coding for different information types
- **Directory**: Clear display of current directory path
- **Status**: Command success/error indicator

### 2. Performance

- **Fast Rendering**: < 10ms scan timeout
- **Minimal Overhead**: Low performance impact
- **Responsive**: No noticeable lag when typing
- **Efficient Modules**: Only enable necessary modules
- **Cached Information**: Cache information where appropriate

### 3. Information Display

- **Directory**: Current directory with path truncation
- **Git**: Branch, status, and ahead/behind count
- **Language Versions**: Show relevant language versions
- **Exit Code**: Indicate command success/failure
- **Time**: Current time in right prompt
- **Battery**: Battery status in right prompt
- **Shell**: Current shell indicator
- **Package**: Package version in appropriate directories

### 4. Contextual Awareness

- **Project Detection**: Detect project type
- **Directory Icons**: Custom icons for common directories
- **Git Status**: Detailed git status information
- **Environment**: Show environment indicators (nix, docker, etc.)
- **Package Version**: Show version when in package directory
- **Node.js**: Show Node.js version in JavaScript projects
- **Rust**: Show Rust version in Rust projects
- **Python**: Show Python version in Python projects
- **Go**: Show Go version in Go projects

### 5. Customization

- **Theme System**: Easy theme switching
- **Module Control**: Enable/disable modules as needed
- **Format Control**: Customizable format strings
- **Style Options**: Control colors and formatting
- **Symbol Options**: Customizable symbols and icons

## Feature Requirements

### Essential Features

- **Directory Display**: Current directory path
- **Git Information**: Branch and status
- **Command Status**: Success/failure indicator
- **Time Display**: Current time in right prompt
- **Battery Status**: Battery level in right prompt

### Enhanced Features

- **Language Versions**: Show relevant language versions
- **Directory Icons**: Custom icons for common directories
- **Git Details**: Detailed git status information
- **Environment Indicators**: Show environment info
- **Package Information**: Package version when relevant
- **Command Duration**: Show duration for long commands
- **Character Customization**: Customize prompt character

### Optional Features

- **Cloud Provider**: Show cloud provider info
- **Kubernetes**: Show k8s context
- **Jobs**: Background job count
- **AWS**: AWS profile information
- **Conda**: Conda environment
- **Docker**: Docker context
- **Memory Usage**: System memory information

## Configuration Categories

1. **Core**: Essential prompt options
2. **Format**: Prompt format configuration
3. **Colors**: Color scheme settings
4. **Directory**: Directory display options
5. **Git**: Git integration options
6. **Languages**: Programming language modules
7. **Environment**: Environment indicators
8. **System**: System information display
9. **Performance**: Performance optimization settings

## Module Configuration

- **Directory**: Truncation length, substitutions
- **Git Branch**: Symbol, truncation
- **Git Status**: Format, symbols
- **Node.js**: Symbol, version format
- **Rust**: Symbol, version format
- **Go**: Symbol, version format
- **PHP**: Symbol, version format
- **Time**: Format, style
- **Battery**: Symbols, thresholds
- **Character**: Success/error symbols

## Configuration Principles

1. **Simplicity**: Keep configuration simple and focused
2. **Performance**: Optimize for fast rendering
3. **Clarity**: Clear, readable information
4. **Consistency**: Consistent styling and behavior
5. **Contextual**: Show information relevant to context
6. **Aesthetics**: Visually appealing design
7. **Integration**: Fits well with terminal theme

## Customization Areas

1. **Theme**: Color scheme
2. **Format**: Prompt layout
3. **Modules**: Enable/disable modules
4. **Symbols**: Custom icons and symbols
5. **Styles**: Custom colors and formatting
6. **Behavior**: Module-specific behavior