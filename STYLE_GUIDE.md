# Style Guide for Dotfiles Repository

This document establishes the consistent style, language, and design principles to be applied across all dotfiles configuration and documentation. It serves as a formal specification for maintaining consistency when modifying or extending the repository.

## Language and Terminology

### General Principles

1. **Clarity**: Use clear, direct language without unnecessary jargon
2. **Consistency**: Maintain consistent terminology across all files
3. **Precision**: Be specific about requirements and implementations
4. **Formality**: Use a professional, semi-formal tone in documentation
5. **Conciseness**: Be brief but complete, avoiding redundancy

### Standard Terminology

| Term | Definition | Usage |
|------|------------|-------|
| Tokyo Night | The primary color theme used across all tools | "Tokyo Night theme for consistent styling" |
| XDG | XDG Base Directory Specification | "Follow XDG compliance for config locations" |
| Apple Silicon | ARM-based Mac processors | "Optimized for Apple Silicon performance" |
| Dotfiles | Configuration files stored in version control | "Manage dotfiles with symlinks" |
| Symlink | Symbolic link to configuration files | "Symlink entire directories when possible" |
| Idempotent | Can be run multiple times without side effects | "Idempotent setup script" |

## File Structure and Organization

### Configuration Files

1. **Header Comments**: Begin each configuration file with a descriptive header
   ```lua
   -- Tool Configuration
   -- Description: Brief description of what this configures
   -- Last Updated: YYYY-MM-DD
   ```

2. **Section Organization**: Organize configurations into logical sections
   ```toml
   # Section 1: Core Settings
   setting1 = value1
   
   # Section 2: Feature Settings
   setting2 = value2
   ```

3. **Comments**: Add comments for non-obvious settings
   ```bash
   # Use 10ms timeout for faster prompt rendering
   scan_timeout = 10
   ```

### Documentation Files

1. **README.md Structure**:
   - Title and brief description
   - Features section with bullet points
   - Installation instructions
   - Configuration explanation
   - Usage examples
   - Customization options
   - Resources/References

2. **PRD.md Structure**:
   - Core Requirements (categorized)
   - Feature Requirements
   - Configuration Categories
   - Key Mappings (if applicable)
   - Configuration Principles
   - Customization Areas

3. **VERSION.md Structure**:
   - Version Information
   - Dependencies
   - Configuration Health
   - Debug Information
   - Command Line Tools
   - Just Integration
   - Recent Changes

## Coding Style

### Lua

1. **Indentation**: 2 spaces
2. **Line Length**: 100 characters maximum
3. **String Quotes**: Single quotes for strings
4. **Tables**: Use explicit table constructors with proper spacing
   ```lua
   local config = {
     option1 = 'value1',
     option2 = 'value2',
   }
   ```
5. **Function Style**: Prefer function expressions over declarations
   ```lua
   local function my_function(arg)
     -- implementation
   end
   ```
6. **Comments**: Use -- for comments, --- for documentation comments

### Shell Scripts

1. **Indentation**: 2 spaces
2. **Line Length**: 80 characters when possible
3. **String Quotes**: Double quotes for strings with variables, single quotes otherwise
4. **Function Style**: Use function keyword and braces on same line
   ```bash
   function my_function() {
     # implementation
   }
   ```
5. **Variable References**: Use `${variable}` style for clarity
6. **Error Handling**: Include error handling with set -e or trap
7. **Comments**: Use # for comments, add section separators with #####

### TOML

1. **Indentation**: 2 spaces
2. **Section Order**: Core settings first, then feature-specific sections
3. **Comments**: Use # for comments, add section separators
4. **Arrays**: One item per line for multi-line arrays
   ```toml
   array = [
     "item1",
     "item2",
     "item3",
   ]
   ```
5. **Tables**: Group related settings in tables

## Design Principles

These core design principles should be reflected across all configurations:

1. **Minimalism**: Keep configurations simple and focused
2. **Performance**: Optimize for speed and responsiveness
3. **Consistency**: Maintain consistent style and behaviors across tools
4. **Modularity**: Enable easy addition/removal of specific configurations
5. **Discoverability**: Make features and commands easy to discover
6. **Documentation**: Document everything thoroughly
7. **Maintainability**: Code should be clean and well-organized

## Visual Design

### Color Scheme

The Tokyo Night theme palette should be used consistently:

```toml
# TokyoNight Colors
bg = "#1a1b26"       # Background
fg = "#c0caf5"       # Foreground
black = "#15161e"    # Black
red = "#f7768e"      # Red
green = "#9ece6a"    # Green
yellow = "#e0af68"   # Yellow
blue = "#7aa2f7"     # Blue
magenta = "#bb9af7"  # Magenta
cyan = "#7dcfff"     # Cyan
white = "#a9b1d6"    # White
```

### Typography

1. **Terminal Font**: Nerd Font compatible monospace font
2. **Documentation Headers**: Use Markdown ATX headers (# for h1, ## for h2, etc.)
3. **Lists**: Use - for unordered lists, 1. for ordered lists
4. **Emphasis**: Use **bold** for important items, *italic* for emphasis
5. **Code Blocks**: Use triple backticks with language specification

### Icons and Symbols

1. **Success**: ✅ or ✓
2. **Failure/Warning**: ❌ or ⚠️
3. **Information**: ℹ️ or 🛈
4. **Note**: 📝
5. **Important**: ❗
6. **Link**: 🔗
7. **Settings**: ⚙️
8. **Tool**: 🛠️
9. **Theme**: 🎨
10. **Time**: ⏱️

## Version Control

### Commit Messages

1. **Structure**:
   ```
   Subject line (50 chars max)

   Detailed explanation of what and why (not how)
   - Bullet points for multiple changes
   - Keep lines to 72 characters
   
   🤖 Generated with [Claude Code](https://claude.ai/code)
   Co-Authored-By: Claude <noreply@anthropic.com>
   ```

2. **Subject Line Style**:
   - Use imperative mood ("Add feature" not "Added feature")
   - Start with capital letter
   - No period at the end
   - Keep under 50 characters
   - Be specific about what changed

3. **Body Style**:
   - Explain what and why, not how
   - Use bullet points for multiple changes
   - Separate paragraphs with blank line
   - Reference issues if applicable

### Branch Names

1. **Feature Branches**: `feature/descriptive-name`
2. **Bug Fixes**: `fix/descriptive-name`
3. **Documentation**: `docs/descriptive-name`
4. **Refactoring**: `refactor/descriptive-name`

## Tool-Specific Guidelines

### Neovim

- Use LazyVim framework
- Organize plugins into logical categories
- Use Space as leader key
- Keep startup time below 100ms
- Follow Vim conventions for key mappings

### ZSH

- Keep startup time below 200ms
- Organize aliases by category with comments
- Use descriptive function names
- Follow consistent prompt style
- Keep shell scripts POSIX-compatible when possible

### Yazi

- Use Vim-style navigation
- Optimize worker counts for Apple Silicon
- Set file preview limits for performance
- Organize by file type
- Use consistent key mappings

### Aerospace

- Use Alt as primary modifier key
- Follow Vim-style directional navigation
- Use service mode for special operations
- Maintain consistent window gaps
- Keep workspace count at 5

### Starship

- Keep scan timeout at 10ms
- Place time and battery on right side
- Use two-line prompt with clean separation
- Show relevant language versions
- Use consistent icons for all sections

## Documentation Guidelines

1. **README Files**:
   - Focus on user-oriented information
   - Include installation, usage, customization
   - Show examples for common operations
   - Keep language simple and direct

2. **PRD Files**:
   - Focus on requirements and design decisions
   - Organize into logical categories
   - Include rationale for design choices
   - Be specific about implementation details

3. **VERSION Files**:
   - Focus on current state and dependencies
   - Include exact version numbers
   - Document any health issues
   - List recent changes

## Justfile Guidelines

1. **Recipe Naming**:
   - Use kebab-case for recipe names
   - Group related commands with common prefix
   - Use descriptive, action-oriented names
   - Keep names concise but clear

2. **Recipe Documentation**:
   - Add comments above each recipe
   - Explain purpose and any side effects
   - Document any required parameters
   - Group related recipes with section comments

3. **Recipe Implementation**:
   - Use @echo for user feedback
   - Use conditional execution when appropriate
   - Capture errors and provide feedback
   - Use variables for repeated values

## Adherence to This Guide

This style guide should be followed for all new additions and modifications to the dotfiles repository. When working with existing files, gradually update them to match this guide's specifications.

For automatic verification, consider using:
- `stylua` for Lua formatting
- `shfmt` for shell script formatting
- `markdownlint` for Markdown formatting
- `toml-lint` for TOML validation

When using LLMs to generate or modify files, reference this guide to ensure consistency.