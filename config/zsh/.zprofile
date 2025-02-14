# ====== Path Configuration ======
# Initialize Homebrew on Apple Silicon (this also sets up PATH)
# eval "$(/opt/homebrew/bin/brew shellenv)"
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# PATH Configuration

typeset -U path  # Ensure unique entries
local additional_paths=(
    "$HOME/.local/bin"
    "$HOMEBREW_PREFIX/opt/ruby/bin"
    "$(gem environment gemdir)/bin"


)
for p in $additional_paths; do
    if [[ -d "$p" ]] && [[ ":$PATH:" != *":$p:"* ]]; then
        path+=("$p")
    fi
done


