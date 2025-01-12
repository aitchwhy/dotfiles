{ config, pkgs, ... }:

{
  programs = {
    # Shell
    zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableSyntaxHighlighting = true;
      historySubstringSearch.enable = true;
      
      initExtra = ''
        # Homebrew environment setup for Apple Silicon
        eval "$(/opt/homebrew/bin/brew shellenv)"
        autoload -Uz compinit; compinit

        # Key bindings
        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down

        # Ensure PATH updates are applied
        export PATH="/opt/homebrew/bin:$PATH"

        # Custom functions
        mkcd() {
          mkdir -p "$1" && cd "$1"
        }

        # Source Homebrew-installed completions
        if [ -d /opt/homebrew/share/zsh/site-functions ]; then
          fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
        fi

        # Source additional Zsh plugins
        source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
      '';

      shellAliases = {
        # Modern CLI alternatives
        ls = "eza --icons";
        ll = "eza -l --icons";
        la = "eza -al --icons";
        cat = "bat --paging=always";
        grep = "rg";
        find = "fd";
        md = "glow";
        cd = "z";

        # Git shortcuts
        gs = "git status";
        ga = "git add";
        gc = "git commit";
        gp = "git push";
        gl = "git pull";
        lg = "lazygit";

        # FZF enhanced commands
        flog = "fzf --preview \"bat --style=numbers --color=always --line-range=:500 {}\"";
        falias = "alias | fzf";
        fman = "man -k . | fzf --preview \"man {}\"";

        # Homebrew shortcuts
        b = "brew";
        bdr = "brew doctor";
        blk = "brew leaves";
        boc = "brew outdated --cask";
        bof = "brew outdated --formula";
        bupd = "brew update";
        bupg = "brew upgrade";
        bclean = "brew cleanup --prune=all";
        bcleanall = "brew cleanup --prune=all && rm -rf $(brew --cache)";
        bpull = "bupd && bupg && bclean";
        bin = "brew install";
        brein = "brew reinstall";
        bi = "brew info";
        bs = "brew search";
        bcl = "brew list --cask";
        bcin = "brew install --cask";
        bcup = "brew upgrade --cask";
        bb = "brew bundle";
        bbls = "brew bundle dump --all --file=- --verbose";
        bbcheck = "brew bundle check --all --global --verbose";

        # Directory navigation
        gdl = "cd ~/Downloads";
        gcf = "cd ~/.config/";

        # Python virtual environment
        uvgn = "uv venv $GLOBAL_PYTHON_VENV";
        uvg = "source $GLOBAL_PYTHON_VENV/bin/activate";

        # Zsh configuration
        ze = "nvim ~/.zshrc";
        zs = "source ~/.zshrc";
        zcompreset = "rm -f ~/.zcompdump; compinit";

        # Tailscale
        ts = "tailscale";

        # Marta file manager
        marta = "/Applications/Marta.app/Contents/Resources/launcher";
      };
    };

    # Shell prompt
    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        add_newline = true;
        command_timeout = 1000;
        
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
        };

        directory = {
          truncation_length = 3;
          truncate_to_repo = true;
        };

        git_branch = {
          symbol = "🌱 ";
          truncation_length = 20;
        };

        nix_shell = {
          symbol = "❄️ ";
          format = "via [$symbol$state( \($name\))]($style) ";
        };
      };
    };

    # Shell history
    atuin = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        auto_sync = true;
        update_check = true;
        sync_frequency = "5m";
        search_mode = "fuzzy";
      };
    };

    # Directory navigation
    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [
        "--cmd cd"
      ];
    };

    # Command history search
    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
        "--inline-info"
      ];
    };

    # Development environment manager
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
  };
}
