# Cursor IDE Keymaps

This document describes the LazyVim-inspired keymaps configured for Cursor IDE using VSCodeVim and VSpaceCode Which-Key.

## Setup

1. **Install Extensions:**
   - `vscodevim.vim` - Vim emulation
   - `VSpaceCode.whichkey` - Discoverable keymap UI

2. **Apply Configuration:**
   - Copy `.cursor/settings.json` to `~/Library/Application Support/Cursor/User/settings.json` (merge with existing)
   - The keybindings in your user `keybindings.json` have been updated with context-aware navigation

## Leader Key

**Space** is configured as the leader key (`<leader>`).

## Which-Key UI

Press **Space** in Normal mode to see the discoverable menu tree, or:
- `Cmd+;` - Show which-key menu
- `Ctrl+Space` - Show which-key menu (when in editor)

## LSP Motions (Normal Mode)

| Key | Command | Description |
|-----|---------|-------------|
| `gd` | Go to Definition | Jump to symbol definition |
| `gr` | Go to References | Show all references |
| `gi` | Go to Implementation | Jump to implementation |
| `gt` | Go to Type Definition | Jump to type definition |
| `gD` | Go to Declaration | Jump to declaration |
| `K` | Hover | Show hover information |

## Leader Mappings

### Find (`<leader>f`)
| Key | Command | Description |
|-----|---------|-------------|
| `<leader>ff` | Quick Open | Find files |
| `<leader>fg` | Find in Files | Grep workspace |
| `<leader>fr` | Open Recent | Recent files |
| `<leader>fb` | Show All Editors | List buffers |

### Search (`<leader>s`)
| Key | Command | Description |
|-----|---------|-------------|
| `<leader>ss` | Show All Symbols | Workspace symbols |
| `<leader>sd` | View Problems | Diagnostics panel |

### Buffers (`<leader>b`)
| Key | Command | Description |
|-----|---------|-------------|
| `<leader>bb` | Show All Editors | Switch buffer |
| `<leader>bd` | Close Active Editor | Delete buffer |

### Windows (`<leader>w`)
| Key | Command | Description |
|-----|---------|-------------|
| `<leader>wv` | Split Editor Right | Vertical split |
| `<leader>ws` | Split Editor Down | Horizontal split |
| `<leader>wd` | Close Group | Close split |
| `<leader>wm` | Maximize Editor | Toggle zoom |

### Tabs/Terminal (`<leader>t`)
| Key | Command | Description |
|-----|---------|-------------|
| `<leader>tt` | Toggle Terminal | Show/hide terminal |
| `<leader>tn` | Next Editor | Next tab |
| `<leader>tp` | Previous Editor | Previous tab |

### LSP (`<leader>l`)
| Key | Command | Description |
|-----|---------|-------------|
| `<leader>la` | Code Action | Show code actions |
| `<leader>lr` | Rename | Rename symbol |
| `<leader>lf` | Format Document | Format file |
| `<leader>ld` | View Problems | Diagnostics |

### Git (`<leader>g`)
| Key | Command | Description |
|-----|---------|-------------|
| `<leader>gs` | Source Control | Open SCM view |
| `<leader>gl` | Show All History | Git log |

### Diagnostics (`<leader>x`)
| Key | Command | Description |
|-----|---------|-------------|
| `<leader>xx` | View Problems | Problems panel |
| `<leader>xq` | Toggle Panel | Show/hide panel |

### UI (`<leader>u`)
| Key | Command | Description |
|-----|---------|-------------|
| `<leader>uz` | Toggle Zen Mode | Zen mode |
| `<leader>um` | Toggle Minimap | Minimap |
| `<leader>uw` | Toggle Word Wrap | Word wrap |
| `<leader>us` | Toggle Sidebar | Sidebar visibility |

### Explorer (`<leader>e`)
| Key | Command | Description |
|-----|---------|-------------|
| `<leader>ee` | Explorer | File explorer |
| `<leader>eE` | Reveal Active File | Show current file |

## Context-Aware Navigation

### Editor (Normal Mode)
| Key | Command | Description |
|-----|---------|-------------|
| `Ctrl+h` | Navigate Left | Move to left split |
| `Ctrl+j` | Navigate Down | Move to bottom split |
| `Ctrl+k` | Navigate Up | Move to top split |
| `Ctrl+l` | Navigate Right | Move to right split |

### Terminal
| Key | Command | Description |
|-----|---------|-------------|
| `Ctrl+h` | Focus Previous Pane | Left terminal pane |
| `Ctrl+l` | Focus Next Pane | Right terminal pane |
| `Ctrl+j` | Focus Next | Next terminal |
| `Ctrl+k` | Focus Previous | Previous terminal |
| `Shift+Enter` | Line Continuation | Multi-line command |

## Insert Mode

| Key | Command | Description |
|-----|---------|-------------|
| `jj` | Escape | Exit insert mode |

## Global Shortcuts

| Key | Command | Description |
|-----|---------|-------------|
| `Cmd+K` | Show Commands | Command palette |
| `Cmd+I` | Composer Agent | Cursor AI agent |
| `Cmd+O` | Go to Symbol | Symbol in file |

## Notes

- **Vim motions** are handled by VSCodeVim
- **Which-Key** provides the discoverable menu tree
- **Context-aware** navigation respects editor vs terminal focus
- All keybindings use native VS Code commands for maximum compatibility
