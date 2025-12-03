export PATH="$HOME/.local/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/hank/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
