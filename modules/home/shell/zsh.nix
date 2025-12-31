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
