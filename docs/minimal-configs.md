# Minimal Configs for Zellij, Zsh, Nix, Neovim and Yazi

This guide shows the bare minimum configuration files so these tools work together without extra features.
The `.config` directory now contains these minimal versions directly.
Each file has the complete original configuration commented out so you can
uncomment pieces as needed.

## Directory layout

```
~/.config/
├── zsh/
│   ├── .zshenv
│   └── .zshrc
├── nvim/
│   └── init.lua
├── zellij/
│   └── config.kdl
└── yazi/
    └── yazi.toml
```

Set `DOTFILES` and `XDG_CONFIG_HOME` in `~/.zshenv` so all tools share the same directory:

```zsh
# ~/.config/zsh/.zshenv
export DOTFILES="$HOME/dotfiles"
export XDG_CONFIG_HOME="$DOTFILES/.config"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
source "$ZDOTDIR/.zshrc"
```

A tiny `~/.config/zsh/.zshrc` that wires the tools together:

```zsh
export EDITOR="nvim"
export YAZI_CONFIG_DIR="$XDG_CONFIG_HOME/yazi"
export ZELLIJ_CONFIG_DIR="$XDG_CONFIG_HOME/zellij"

# add local bin to PATH
path=("$HOME/.local/bin" $path)
```

Minimal `~/.config/zellij/config.kdl`:

```kdl
layout default {
    pane command="zsh" {}
}
```

Minimal `~/.config/nvim/init.lua` just to open files:

```lua
vim.o.number = true
```

Minimal `~/.config/yazi/yazi.toml` that uses Neovim for editing:

```toml
[opener]
default = ["nvim", "$1"]
```

With these files in place you can start Zellij and run Yazi or Neovim inside. Nix flakes or `home-manager` can symlink the same directory on any machine to keep it consistent.

