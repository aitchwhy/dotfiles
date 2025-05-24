# Add dotfiles bin to PATH
export PATH="$HOME/dotfiles/bin:$PATH"

eval "$(/opt/homebrew/bin/brew shellenv)"

# Source bashrc if it exists
if [ -f "$HOME/.bashrc" ]; then
  . "$HOME/.bashrc"
fi

# load all completions
if [ -d "./.bash_completion.d" ]; then
  for f in "./.bash_completion.d"/*.sh; do
    [ -r "$f" ] && . "$f"
  done
fi
