# Zsh shell configuration
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.modules.home.shell.zsh = {
    enable = mkEnableOption "Zsh shell configuration";
  };

  config = mkIf config.modules.home.shell.zsh.enable {
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      enableCompletion = true;

      # NH (Nix Helper) aliases for modern nix-darwin experience
      shellAliases = {
        nhs = "nh darwin switch";
        nhb = "nh darwin build";
        nhc = "nh clean all --keep 5 --keep-since 7d";
        nhu = "nix flake update && nh darwin switch";
      };

      initContent = ''
        # fnm (Fast Node Manager) - must be before direnv
        eval "$(fnm env --use-on-cd --shell zsh)"
        # Fast directory navigation
        setopt AUTO_CD
        setopt AUTO_PUSHD
        setopt PUSHD_IGNORE_DUPS
        setopt PUSHD_SILENT

        # Better history
        setopt HIST_IGNORE_ALL_DUPS
        setopt HIST_FIND_NO_DUPS
        setopt HIST_SAVE_NO_DUPS
        setopt SHARE_HISTORY

        # Modern completions
        setopt MENU_COMPLETE
        setopt AUTO_LIST
        setopt COMPLETE_IN_WORD

        # ========================================
        # Shell Functions (restored from backup)
        # ========================================

        # Yazi with directory tracking
        function y() {
          local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
          yazi "$@" --cwd-file="$tmp"
          if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            builtin cd -- "$cwd"
          fi
          rm -f -- "$tmp"
        }

        # Nix develop with flake attribute
        function nz() {
          nix develop ".#$1" --command zsh
        }

        # Fuzzy zellij session attach
        function zja() {
          zellij attach "$(zellij list-sessions -n | fzf --reverse --border --no-sort --height 40% | awk '{print $1}')"
        }

        # Fuzzy file finder with preview
        function ff() {
          local mode="''${1:-find}"
          case "$mode" in
            find|f)   fd --type f --hidden --exclude .git | fzf --preview 'bat --color=always {}' ;;
            edit|e)   $EDITOR "$(fd --type f --hidden --exclude .git | fzf --preview 'bat --color=always {}')" ;;
            dir|d)    cd "$(fd --type d --hidden --exclude .git | fzf --preview 'eza --tree --level=2 {}')" ;;
            *)        echo "Usage: ff [find|edit|dir]" ;;
          esac
        }

        # Clean Python caches
        function clean-python() {
          find . -type d \( -name ".venv" -o -name ".pytest_cache" -o -name ".ruff_cache" -o -name "__pycache__" \) -exec rm -rf {} + 2>/dev/null
        }

        # Clean Node caches
        function clean-node() {
          find . -type d \( -name "node_modules" -o -name ".next" -o -name ".turbo" \) -exec rm -rf {} + 2>/dev/null
        }

        # SSH key generation
        function generate_ssh() {
          local name="''${1:-id_ed25519}"
          ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)" -f ~/.ssh/"$name"
        }

        # Quick directory shortcuts
        function cfs() {
          cd "$CFS/$1"
        }

        # Check if command exists
        function has_command() {
          command -v "$1" &> /dev/null
        }

        # ========================================
        # Ghostty terminfo helpers
        # ========================================

        # Deploy xterm-ghostty terminfo to a remote server
        # Usage: ghostty-terminfo user@host
        function ghostty-terminfo() {
          if [[ -z "$1" ]]; then
            echo "Usage: ghostty-terminfo user@host"
            echo "Installs Ghostty terminfo on remote server to fix backspace/rendering issues"
            return 1
          fi
          infocmp -x xterm-ghostty | ssh "$1" -- tic -x -
          echo "✓ Installed xterm-ghostty terminfo on $1"
        }

        # ========================================
        # Agent Browser helpers
        # ========================================

        # Quick frontend test - opens URL and snapshots
        # Usage: ab-test <url>
        function ab-test() {
          if [[ -z "$1" ]]; then
            echo "Usage: ab-test <url>"
            return 1
          fi
          agent-browser open "$1"
          agent-browser snapshot -i -c
        }

        # Screenshot with timestamp
        # Usage: ab-screenshot [name]
        function ab-screenshot() {
          local name="''${1:-screenshot}"
          agent-browser screenshot "./$name-$(date +%Y%m%d-%H%M%S).png"
        }

        # ========================================
        # Claude Code Multi-Account (cc)
        # ========================================

        function cc() {
          local account="''${1:-}"
          shift 2>/dev/null || true

          if [[ -z "$account" ]]; then
            account=$(printf '%s\n' \
              "max-1    Max 20x — primary" \
              "max-2    Max 20x — overflow 1" \
              "max-3    Max 20x — overflow 2" \
              "glm      GLM 5.1 via Z.ai" \
              "openai   GPT-5 via OpenRouter" \
              | fzf --reverse --height=40% --prompt="cc > " \
              | awk '{print $1}')
            [[ -z "$account" ]] && return 1
          fi

          case "$account" in
            max-1) claude "$@" ;;
            max-2) CLAUDE_CONFIG_DIR="$HOME/.claude-max-2" claude "$@" ;;
            max-3) CLAUDE_CONFIG_DIR="$HOME/.claude-max-3" claude "$@" ;;
            glm)
              local key; key=$(_cc_secret "told/vendor/zai/api-key") || return 1
              echo "-> cc glm" >&2
              ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic" \
              ANTHROPIC_AUTH_TOKEN="$key" \
              ANTHROPIC_DEFAULT_OPUS_MODEL="glm-5.1" \
              ANTHROPIC_DEFAULT_SONNET_MODEL="glm-5.1" \
              ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.5-air" \
              CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 \
              claude "$@" ;;
            openai)
              local key; key=$(_cc_secret "told/vendor/openrouter/api-key") || return 1
              echo "-> cc openai" >&2
              ANTHROPIC_BASE_URL="https://openrouter.ai/api" \
              ANTHROPIC_AUTH_TOKEN="$key" \
              ANTHROPIC_MODEL="openai/gpt-5" \
              CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 \
              claude "$@" ;;
            status) _cc_status ;;
            *) echo "Unknown: $account. Valid: max-1 max-2 max-3 glm openai status" >&2; return 1 ;;
          esac
        }

        function _cc_secret() {
          local val
          val=$(aws secretsmanager get-secret-value --secret-id "$1" --region us-east-1 --query SecretString --output text 2>/dev/null)
          [[ -z "$val" ]] && { echo "ERROR: Secret $1 missing" >&2; return 1; }
          echo "$val"
        }

        function _cc_status() {
          echo "=== max-1 (primary) ==="
          claude auth status 2>&1 | head -3
          echo ""
          echo "=== max-2 ==="
          CLAUDE_CONFIG_DIR="$HOME/.claude-max-2" claude auth status 2>&1 | head -3
          echo ""
          echo "=== max-3 ==="
          CLAUDE_CONFIG_DIR="$HOME/.claude-max-3" claude auth status 2>&1 | head -3
          echo ""
          echo "=== glm ==="
          _cc_secret "told/vendor/zai/api-key" >/dev/null 2>&1 && echo "Key: OK" || echo "Key: MISSING"
          echo ""
          echo "=== openai ==="
          _cc_secret "told/vendor/openrouter/api-key" >/dev/null 2>&1 && echo "Key: OK" || echo "Key: MISSING"
        }
      '';

      history = {
        size = 50000;
        save = 50000;
        ignoreDups = true;
        ignoreSpace = true;
        share = true;
      };
    };
  };
}
