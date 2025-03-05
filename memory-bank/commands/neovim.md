# Neovim Commands

A collection of useful Neovim commands, shortcuts, and mappings based on my LazyVim configuration.

## Navigation

| Shortcut | Mode | Description |
|----------|------|-------------|
| `j`, `k`, `h`, `l` | Normal | Basic movement (down, up, left, right) |
| `w`, `b` | Normal | Move forward/backward by word |
| `}`, `{` | Normal | Move forward/backward by paragraph |
| `gg`, `G` | Normal | Go to start/end of file |
| `Ctrl-d`, `Ctrl-u` | Normal | Scroll half-page down/up |
| `Ctrl-f`, `Ctrl-b` | Normal | Scroll full page down/up |
| `zz` | Normal | Center current line on screen |
| `H`, `M`, `L` | Normal | Move cursor to top/middle/bottom of screen |
| `%` | Normal | Jump to matching bracket |
| `gd` | Normal | Go to definition |
| `gr` | Normal | Go to references |

## Editing

| Shortcut | Mode | Description |
|----------|------|-------------|
| `i`, `a` | Normal | Enter insert mode (at cursor/after cursor) |
| `o`, `O` | Normal | Insert new line below/above current line |
| `yy`, `dd` | Normal | Yank/delete current line |
| `y{motion}`, `d{motion}` | Normal | Yank/delete with motion |
| `p`, `P` | Normal | Paste after/before cursor |
| `r{char}` | Normal | Replace character under cursor |
| `c{motion}` | Normal | Change text with motion |
| `u`, `Ctrl-r` | Normal | Undo/redo |
| `>>`/`<<` | Normal | Indent/unindent line |
| `=G` | Normal | Fix indentation to end of file |
| `Ctrl-n` | Insert | Trigger completion |

## Search and Replace

| Shortcut | Mode | Description |
|----------|------|-------------|
| `/pattern` | Normal | Search forward for pattern |
| `?pattern` | Normal | Search backward for pattern |
| `n`, `N` | Normal | Go to next/previous match |
| `*`, `#` | Normal | Search for word under cursor forward/backward |
| `:%s/old/new/g` | Command | Replace all occurrences of 'old' with 'new' |
| `:%s/old/new/gc` | Command | Replace with confirmation |
| `:Telescope live_grep` | Normal | Search in project files |
| `:Telescope grep_string` | Normal | Search for word under cursor in project |

## File Operations

| Shortcut | Mode | Description |
|----------|------|-------------|
| `:e filename` | Command | Edit file |
| `:w` | Command | Save file |
| `:q`, `:q!` | Command | Quit (or force quit) |
| `:wq` | Command | Save and quit |
| `:Telescope find_files` | Normal | Find files in project |
| `:Telescope oldfiles` | Normal | Show recently opened files |
| `:Telescope file_browser` | Normal | Browse file system |
| `:Telescope buffers` | Normal | List open buffers |

## LazyVim-Specific

| Shortcut | Mode | Description |
|----------|------|-------------|
| `<leader>` | Normal | Space key (my leader key) |
| `<leader>e` | Normal | Toggle file explorer |
| `<leader>ff` | Normal | Find files |
| `<leader>fg` | Normal | Live grep |
| `<leader>fb` | Normal | Browse files |
| `<leader>gs` | Normal | Git status |
| `<leader>gc` | Normal | Git commits |
| `<leader>la` | Normal | Code actions |
| `<leader>lr` | Normal | Rename symbol |
| `<leader>lf` | Normal | Format document |

## Terminal

| Shortcut | Mode | Description |
|----------|------|-------------|
| `:terminal` | Command | Open integrated terminal |
| `<Ctrl-\><Ctrl-n>` | Terminal | Exit terminal mode |
| `<leader>h` | Normal | Toggle terminal (horizontal split) |
| `<leader>v` | Normal | Toggle terminal (vertical split) |

## Window Management

| Shortcut | Mode | Description |
|----------|------|-------------|
| `<Ctrl-w>s`, `<Ctrl-w>v` | Normal | Split window horizontally/vertically |
| `<Ctrl-w>h/j/k/l` | Normal | Navigate between windows |
| `<Ctrl-w>q` | Normal | Close current window |
| `<Ctrl-w>=` | Normal | Make all windows equal size |
| `<Ctrl-w>_`, `<Ctrl-w>\|` | Normal | Maximize window height/width |

## Tips & Tricks

- Use `.` to repeat the last change
- Use macro recording with `q{register}` to start recording, and `q` to stop
- Use `@{register}` to execute a macro
- Use `:set spell` to enable spell checking
- Use `Ctrl-x Ctrl-f` in insert mode for filename completion
- Use `gx` to open URL under cursor in browser
