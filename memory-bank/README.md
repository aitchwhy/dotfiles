# Memory Bank

A structured, markdown-based knowledge repository for development environment information, commands, configurations, and troubleshooting. Designed to be keyboard-navigable, searchable, and incrementally maintainable.

## Overview

This memory bank stores information about your dotfiles, development environment, and technical workflows in a hierarchical, well-organized format. It's designed to complement your dotfiles by documenting:

- Commands and shortcuts for the tools you use
- Configuration reference and explanations
- Development workflow patterns
- Troubleshooting guides
- Reference materials and cheatsheets

## Structure

```
memory-bank/
├── index.md                  # Main entry point
├── commands/                 # Command references
│   ├── index.md              # Command category index
│   ├── neovim.md             # Neovim commands
│   └── ...
├── configurations/           # Configuration references
│   ├── index.md              # Configuration category index
│   ├── zsh.md                # ZSH configuration
│   └── ...
├── workflows/                # Workflow documentation
│   ├── index.md              # Workflow category index
│   ├── git.md                # Git workflows
│   └── ...
├── troubleshooting/          # Problem-solving guides
│   ├── index.md              # Troubleshooting category index
│   ├── package-management.md # Package manager issues
│   └── ...
└── references/               # External information
    ├── index.md              # References category index
    ├── cheatsheets.md        # Quick reference sheets
    └── ...
```

## Usage

### 1. Navigation

Start with `index.md` and navigate through the links to find the information you need. The structure is designed to be intuitive and hierarchical.

### 2. Searching

Use your editor's search functionality or tools like `rg` (ripgrep) to search through the memory bank:

```bash
# Search for all mentions of "git"
rg "git" memory-bank/

# Search only in workflow files
rg "branch" memory-bank/workflows/
```

### 3. Viewing

For best results, use a markdown viewer or editor that supports:
- Syntax highlighting
- Table formatting
- Link navigation
- Mermaid diagrams (for workflows)

Recommended tools:
- VS Code with Markdown All in One extension
- Obsidian for networked knowledge views
- Any text editor + browser with a markdown preview extension

### 4. Maintaining

Add to this memory bank whenever you:
- Learn a new command or shortcut
- Set up a new tool or configuration
- Establish a useful workflow
- Solve a difficult problem
- Find a valuable reference

## Integration with Your Workflow

### Editor Integration

Add these VS Code tasks to your `tasks.json` to quickly access the memory bank:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Open Memory Bank",
      "type": "shell",
      "command": "code ${workspaceFolder}/memory-bank/index.md",
      "problemMatcher": []
    },
    {
      "label": "Search Memory Bank",
      "type": "shell",
      "command": "rg '${input:searchTerm}' ${workspaceFolder}/memory-bank/ | less",
      "problemMatcher": []
    }
  ],
  "inputs": [
    {
      "id": "searchTerm",
      "description": "Search term",
      "default": "",
      "type": "promptString"
    }
  ]
}
```

### Shell Integration

Add this to your `.zshrc` or equivalent:

```bash
# Memory Bank shortcuts
alias mb="cd $HOME/dotfiles/memory-bank && $EDITOR index.md"
alias mbs="cd $HOME/dotfiles/memory-bank && $EDITOR \$(rg --files | fzf)"

# Function to search memory bank
mbf() {
  cd $HOME/dotfiles/memory-bank
  if [ "$#" -eq 0 ]; then
    rg "" | fzf --preview "bat --color=always --style=numbers {1}"
  else
    rg "$@" | fzf --preview "bat --color=always --style=numbers {1}"
  fi
}
```

## Expansion Ideas

- **Automation scripts**: Add scripts to automate common tasks documented in the workflows
- **Link to dotfiles**: Add direct links to the relevant dotfiles for each configuration
- **Version history**: Track changes and improvements to your configurations over time
- **Multi-machine configurations**: Document differences between machine-specific setups
