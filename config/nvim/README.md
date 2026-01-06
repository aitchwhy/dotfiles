# Neovim Configuration - ELI5 Guide

A modern Neovim setup based on LazyVim with treesitter-first code intelligence. This guide explains what each component does and why it's configured this way.

> **Last Updated:** January 2026 | **Neovim Version:** 0.10+ | **Base:** LazyVim 15.x

---

## Table of Contents

1. [The Big Picture](#the-big-picture)
2. [Core Components Explained](#core-components-explained)
3. [How Code Intelligence Works](#how-code-intelligence-works)
4. [Plugin Categories](#plugin-categories)
5. [Keybindings Reference](#keybindings-reference)
6. [Directory Structure](#directory-structure)
7. [Why This Setup (SOTA January 2026)](#why-this-setup-sota-january-2026)

---

## The Big Picture

Think of this Neovim setup as a **smart code workbench** with different tools:

```
┌─────────────────────────────────────────────────────────────────┐
│                         NEOVIM                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │  Treesitter  │  │     LSP      │  │      Snacks.nvim     │  │
│  │  "Grammar"   │  │  "Expert"    │  │  "Swiss Army Knife"  │  │
│  │              │  │              │  │                      │  │
│  │ - Syntax     │  │ - Types      │  │ - File picker        │  │
│  │ - Structure  │  │ - Errors     │  │ - Git integration    │  │
│  │ - Selection  │  │ - Go-to-def  │  │ - Notifications      │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
│                              │                                  │
│                              ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                     aerial.nvim                          │  │
│  │         Symbol Outline (treesitter + LSP hybrid)         │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Core Components Explained

### 1. Neovim - The Smart Notebook

**What it is:** Your text editor - where you actually type code.

**ELI5:** Imagine a notebook that can read your handwriting, suggest corrections, and help you find pages you wrote before.

**Why Neovim in 2026:**
- Built-in LSP client (no plugins needed for basic code smarts)
- Built-in Treesitter (understands code structure natively)
- Lua scripting (fast, modern configuration)
- Never freezes while working (async architecture)

---

### 2. LazyVim - The Pre-Built House

**What it is:** A Neovim "distribution" - pre-configured plugins that work together.

**ELI5:** Instead of building a house from scratch, you move into one that's already furnished. You can still repaint walls and move furniture.

**Your setup uses LazyVim because:**
- One-line plugin installation via "extras"
- Maintained by folke (author of most popular plugins)
- Easy to override without breaking things

```lua
-- This one line gives you full TypeScript support:
{ import = "lazyvim.plugins.extras.lang.typescript" }
```

---

### 3. LSP (Language Server Protocol) - The Expert Translator

**What it is:** A background program that understands your programming language deeply.

**ELI5:** Imagine hiring an expert who reads your entire project, knows every file and type, and can answer questions like "where is this defined?" or "who uses this function?"

**How it works:**
```
You type code → Neovim sends it to tsserver → tsserver analyzes → Neovim shows results
```

**What LSP provides:**
| Feature | Keybinding | What it does |
|---------|------------|--------------|
| Go to Definition | `gd` | Jump to where something is defined |
| Find References | `gr` | Find all places that use something |
| Hover Documentation | `K` | Show type info and docs |
| Rename Symbol | `<leader>cr` | Rename everywhere safely |
| Code Actions | `<leader>ca` | Quick fixes and refactors |

**The limitation:** tsserver (TypeScript's LSP) doesn't report `const` variables as "document symbols" - it only reports "structural" things like functions and classes.

---

### 4. Treesitter - The Grammar Teacher

**What it is:** A parser that builds a syntax tree of your code.

**ELI5:** Someone who diagrams every sentence in your code, knowing exactly where each part begins and ends.

**What Treesitter sees:**
```
File
├── ImportDeclaration (line 1-2)
├── VariableDeclaration "Server" (line 65)  ← LSP misses this!
│   └── CallExpression "Layer.unwrapEffect"
│       └── ArrowFunction
│           └── BlockStatement
└── ExpressionStatement (line 97)
```

**What Treesitter provides:**
| Feature | How to use | What it does |
|---------|------------|--------------|
| Syntax Highlighting | Automatic | Colors code by meaning, not regex |
| Incremental Selection | `+` / `-` | Expand/shrink selection by AST node |
| Text Objects | `]f` / `[f` | Jump to next/previous function |
| Sticky Context | Automatic | Shows current function at top of screen |

**Your configuration:**
```lua
-- lua/plugins/nvim-treesitter.lua
incremental_selection = {
  enable = true,
  keymaps = {
    init_selection = "+",      -- Start selection
    node_incremental = "+",    -- Expand to parent node
    node_decremental = "-",    -- Shrink to child node
  },
},
```

---

### 5. aerial.nvim - The Smart Table of Contents

**What it is:** A sidebar showing all symbols in your file.

**ELI5:** Like a book's table of contents, but it updates as you write and shows EVERYTHING - including variables that LSP misses.

**Why aerial over outline.nvim:**
```lua
-- aerial uses treesitter FIRST, then falls back to LSP
backends = { "treesitter", "lsp", "markdown", "man" }
```

This means for TypeScript files:
- Treesitter runs first → finds `const Server`, `const Main`, etc.
- LSP provides type info for hover/go-to-def
- You get the best of both worlds

**Your aerial config:**
```lua
-- lua/plugins/aerial.lua
return {
  "stevearc/aerial.nvim",
  opts = {
    backends = { "treesitter", "lsp", "markdown", "man" },
  },
}
```

---

### 6. Snacks.nvim - The Swiss Army Knife

**What it is:** One plugin that replaces many others (file picker, git, notifications, etc.)

**ELI5:** Instead of carrying 10 different tools, you have one multi-tool that does everything.

**What Snacks replaces:**
| Old Plugin | Snacks Feature |
|------------|----------------|
| telescope.nvim / fzf-lua | `Snacks.picker` |
| neo-tree.nvim | `Snacks.explorer` |
| lazygit.nvim | `Snacks.lazygit` |
| nvim-notify | `Snacks.notifier` |
| indent-blankline | `Snacks.indent` |

**Key bindings from your config:**
| Key | Action |
|-----|--------|
| `<leader><space>` | Find files |
| `<leader>/` | Grep (search text) |
| `<leader>e` | File explorer |
| `<leader>gg` | LazyGit |
| `<leader>ss` | LSP symbols |

---

## How Code Intelligence Works

Here's the complete data flow when you're editing TypeScript:

```
┌─────────────────────────────────────────────────────────────────┐
│                        YOUR CODE                                │
│   const Server = Layer.unwrapEffect(Effect.gen(function* () {   │
│     const config = yield* ServerConfig                          │
│   }))                                                           │
└─────────────────────────────────────────────────────────────────┘
                    │                    │
                    ▼                    ▼
        ┌───────────────────┐  ┌───────────────────┐
        │     Treesitter    │  │   LSP (tsserver)  │
        │                   │  │                   │
        │ Parses syntax     │  │ Type checking     │
        │ Sees ALL tokens   │  │ Go-to-definition  │
        │ Fast (incremental)│  │ Find references   │
        │                   │  │ Rename refactor   │
        │ ✓ const Server    │  │ ✗ const Server    │
        │ ✓ const config    │  │   (not reported)  │
        └───────────────────┘  └───────────────────┘
                    │                    │
                    └────────┬───────────┘
                             ▼
        ┌───────────────────────────────────────────┐
        │              aerial.nvim                  │
        │   backends = { "treesitter", "lsp" }      │
        │                                           │
        │   1. Try treesitter first                 │
        │   2. Fall back to LSP if no TS queries    │
        │   3. Merge results for best coverage      │
        └───────────────────────────────────────────┘
                             │
                             ▼
        ┌───────────────────────────────────────────┐
        │           Symbol Outline (<leader>cs)     │
        │                                           │
        │   ├── PublicHandlers                      │
        │   ├── ProtectedHandlers                   │
        │   ├── ApiComposition                      │
        │   ├── serveMiddleware                     │
        │   ├── Server           ← Now visible!     │
        │   └── Main                                │
        └───────────────────────────────────────────┘
```

---

## Plugin Categories

### Enabled LazyVim Extras

Your `lua/config/lazy.lua` enables these extras:

#### Completion
```lua
{ import = "lazyvim.plugins.extras.coding.blink" }  -- Fast completion engine
```

#### AI
```lua
{ import = "lazyvim.plugins.extras.ai.sidekick" }   -- Claude CLI integration
```

#### Debugging
```lua
{ import = "lazyvim.plugins.extras.dap.core" }      -- Debug Adapter Protocol
{ import = "lazyvim.plugins.extras.dap.nlua" }      -- Lua debugging
```

#### Languages
```lua
{ import = "lazyvim.plugins.extras.lang.typescript" }
{ import = "lazyvim.plugins.extras.lang.python" }
{ import = "lazyvim.plugins.extras.lang.go" }
{ import = "lazyvim.plugins.extras.lang.rust" }
{ import = "lazyvim.plugins.extras.lang.nix" }
{ import = "lazyvim.plugins.extras.lang.json" }
{ import = "lazyvim.plugins.extras.lang.yaml" }
{ import = "lazyvim.plugins.extras.lang.markdown" }
{ import = "lazyvim.plugins.extras.lang.docker" }
{ import = "lazyvim.plugins.extras.lang.sql" }
{ import = "lazyvim.plugins.extras.lang.tailwind" }
{ import = "lazyvim.plugins.extras.lang.toml" }
```

#### Formatting
```lua
{ import = "lazyvim.plugins.extras.formatting.biome" }  -- JS/TS formatting
{ import = "lazyvim.plugins.extras.formatting.black" }  -- Python formatting
```

#### UI
```lua
{ import = "lazyvim.plugins.extras.ui.edgy" }           -- IDE-like panels
{ import = "lazyvim.plugins.extras.ui.treesitter-context" }  -- Sticky headers
```

#### Navigation & Symbols
```lua
{ import = "lazyvim.plugins.extras.editor.aerial" }     -- Symbol outline
{ import = "lazyvim.plugins.extras.editor.navic" }      -- Breadcrumbs
{ import = "lazyvim.plugins.extras.editor.illuminate" } -- Highlight word under cursor
```

#### Refactoring
```lua
{ import = "lazyvim.plugins.extras.editor.refactoring" }  -- Extract, inline, etc.
{ import = "lazyvim.plugins.extras.editor.inc-rename" }   -- Interactive rename
```

#### Editor
```lua
{ import = "lazyvim.plugins.extras.editor.harpoon2" }   -- Quick file switching
{ import = "lazyvim.plugins.extras.editor.overseer" }   -- Task runner
```

---

## Keybindings Reference

### Code Intelligence

| Key | Action | Source |
|-----|--------|--------|
| `gd` | Go to definition | LSP |
| `gr` | Find references | LSP |
| `gI` | Go to implementation | LSP |
| `gy` | Go to type definition | LSP |
| `K` | Hover documentation | LSP |
| `<leader>cr` | Rename symbol | LSP + inc-rename |
| `<leader>ca` | Code actions | LSP |
| `<leader>cR` | Refactoring menu | refactoring.nvim |

### Symbols & Navigation

| Key | Action | Source |
|-----|--------|--------|
| `<leader>cs` | Toggle aerial outline | aerial.nvim |
| `<leader>ss` | File symbols (fuzzy) | Snacks picker |
| `<leader>sS` | Workspace symbols | Snacks picker |
| `]f` / `[f` | Next/prev function | Treesitter textobjects |
| `]c` / `[c` | Next/prev class | Treesitter textobjects |

### Selection (AST-aware)

| Key | Action | Source |
|-----|--------|--------|
| `+` | Start/expand selection | Treesitter incremental |
| `-` | Shrink selection | Treesitter incremental |

### File Operations

| Key | Action | Source |
|-----|--------|--------|
| `<leader><space>` | Find files | Snacks picker |
| `<leader>/` | Grep (search text) | Snacks picker |
| `<leader>e` | File explorer | Snacks explorer |
| `<leader>fr` | Recent files | Snacks picker |
| `<leader>fb` | Buffers | Snacks picker |

### Git

| Key | Action | Source |
|-----|--------|--------|
| `<leader>gg` | LazyGit | Snacks lazygit |
| `<leader>gs` | Git status | Snacks picker |
| `<leader>gl` | Git log | Snacks picker |
| `<leader>gb` | Git blame line | Snacks picker |

---

## Directory Structure

```
~/.config/nvim/
├── init.lua                    # Entry point (loads config.lazy)
├── lazyvim.json                # LazyVim state
└── lua/
    ├── config/
    │   ├── lazy.lua            # Plugin manager + extras
    │   ├── options.lua         # Vim options
    │   ├── keymaps.lua         # Custom keymaps
    │   └── autocmds.lua        # Auto commands
    └── plugins/                # Custom plugin configs (override LazyVim)
        ├── aerial.lua          # Treesitter-first symbol outline
        ├── nvim-treesitter.lua # Incremental selection (+/-)
        ├── snacks.lua          # Swiss army knife config
        ├── edgy.lua            # IDE panel layout
        ├── blink-cmp.lua       # Completion
        ├── conform.lua         # Formatting
        ├── nvim-lspconfig.lua  # LSP server configs
        ├── neotest.lua         # Test runner
        ├── overseer.lua        # Task runner
        └── ...
```

---

## Why This Setup (SOTA January 2026)

### The Evolution

| Era | Syntax | Intelligence | Config |
|-----|--------|--------------|--------|
| **2015** | Regex patterns | ctags | 1000+ lines vimscript |
| **2018** | Regex patterns | YouCompleteMe | 500+ lines vimscript |
| **2020** | Treesitter (new!) | Native LSP | 300+ lines Lua |
| **2024** | Treesitter mature | LSP mature | LazyVim extras |
| **2026** | Treesitter + LSP hybrid | Best of both | One-line extras |

### Why Treesitter + LSP Hybrid?

**LSP knows semantics** (types, references, what code *means*):
- "This variable is type `Effect<never, ConfigError, Layer>`"
- "This function is called in 5 places"
- "Renaming this will update all usages"

**Treesitter knows syntax** (structure, every token, what code *looks like*):
- "This is a `const` declaration on line 65"
- "This selection is inside a function argument"
- "The parent node is a call expression"

**By using both with treesitter-first priority:**
```lua
backends = { "treesitter", "lsp", "markdown", "man" }
```

You get:
- Symbol outline shows ALL symbols (including `const`)
- Go-to-definition still works (LSP)
- References still work (LSP)
- AST-aware selection works (Treesitter)
- Sticky context works (Treesitter)

### Why Snacks.nvim?

Before Snacks (2024):
```lua
-- 5 different plugins with 5 different configs
{ "nvim-telescope/telescope.nvim", ... }
{ "nvim-neo-tree/neo-tree.nvim", ... }
{ "kdheepak/lazygit.nvim", ... }
{ "rcarriga/nvim-notify", ... }
{ "lukas-reineke/indent-blankline.nvim", ... }
```

With Snacks (2025+):
```lua
-- One plugin, one config, everything works together
{ "folke/snacks.nvim", opts = { ... } }
```

### Why LazyVim?

1. **folke maintains everything** - The author of lazy.nvim, which-key, snacks, noice, trouble, flash, etc.
2. **Extras system** - Enable features with one line
3. **Override-friendly** - Your configs merge with defaults
4. **Community tested** - Thousands of users find edge cases

---

## Troubleshooting

### Symbols not showing in aerial?
```vim
:checkhealth aerial
```
Ensure treesitter parser is installed for your language.

### Incremental selection not working?
Make sure you're pressing `+` (Shift+=), not just `=`.

### LSP not starting?
```vim
:LspInfo
:Mason
```
Check if the language server is installed.

### Plugin issues?
```vim
:Lazy health
:Lazy update
:Lazy clean
```

---

## Resources

- [LazyVim Documentation](https://www.lazyvim.org/)
- [Neovim Lua Guide](https://neovim.io/doc/user/lua.html)
- [Treesitter Playground](https://tree-sitter.github.io/tree-sitter/playground)
- [LSP Specification](https://microsoft.github.io/language-server-protocol/)
