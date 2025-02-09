# # ~/.config/zsh/.zshrc - Main Zsh configuration file
# export ZDOTDIR="$HOME/.config/zsh"
# . "$ZDOTDIR/.zshenv"

# Runs in all sessions
export CARGO_HOME="$HOME/.cargo"
export CLICOLOR=1
export EDITOR="nvim"
export GOPATH="$HOME/go"

export PYENV_ROOT="$HOME/.pyenv"
export PYENV_HOME_BIN="$HOME/.pyenv/bin"

# Starship takes care of this for me.
export PYENV_VIRTUALENV_DISABLE_PROMPT=1

# export RBENV_HOME="$HOME/.rbenv"
export VOLTA_HOME="$HOME/.volta"
# export DOTNET_ROOT="/usr/local/opt/dotnet/libexec"

eval "$(/Users/random/.rakubrew/bin/rakubrew init Zsh)"

if [[ -d "$CARGO_HOME" ]]; then
    source "$HOME/.cargo/env"
fi

if [ -e /home/random/.nix-profile/etc/profile.d/nix.sh ]; then . /home/random/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
. "$HOME/.cargo/env"
if [ -n "$PYTHONPATH" ]; then
    export PYTHONPATH='/opt/homebrew/Cellar/pdm/2.2.1/libexec/lib/python3.11/site-packages/pdm/pep582':$PYTHONPATH
else
    export PYTHONPATH='/opt/homebrew/Cellar/pdm/2.2.1/libexec/lib/python3.11/site-packages/pdm/pep582'
fi
