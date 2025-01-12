{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    syntaxHighlighting.enable = true;
    
    # History
    history = {
      size = 50000;
      save = 50000;
      path = "${config.xdg.dataHome}/zsh/history";
      extended = true;
      ignoreDups = true;
      share = true;
    };

    # Initialize completions
    initExtra = ''
      # Load and initialize the completion system
      autoload -Uz compinit
      compinit

      # Case insensitive completion
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

      # Enable menu selection
      zstyle ':completion:*' menu select

      # Group matches and describe groups
      zstyle ':completion:*' group-name '''
      zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'

      # Colorize completions using default colors
      zstyle ':completion:*:default' list-colors ''${(s.:.)LS_COLORS}

      # Cache completions
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/.zcompcache"

      # Better SSH/SCP/RSYNC completion
      zstyle ':completion:*:(scp|rsync):*' tag-order ' hosts:-ipaddr:ip\ address hosts:-host:host files'
      zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
      zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'

      # Allow for autocomplete to be case insensitive
      zstyle ':completion:*' matcher-list '''' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' '+l:|=* r:|=*'

      # Initialize zoxide
      eval "$(zoxide init zsh)"

      # Initialize direnv
      eval "$(direnv hook zsh)"

      # Better directory navigation
      setopt AUTO_CD              # If a command is issued that can't be executed as a normal command, and the command is the name of a directory, perform the cd command to that directory
      setopt AUTO_PUSHD          # Make cd push the old directory onto the directory stack
      setopt PUSHD_IGNORE_DUPS   # Don't push multiple copies of the same directory onto the directory stack
      setopt PUSHD_MINUS         # Exchanges the meanings of '+' and '-' when used with a number to specify a directory in the stack

      # History settings
      setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format
      setopt SHARE_HISTORY             # Share history between all sessions
      setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history
      setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again
      setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate
      setopt HIST_FIND_NO_DUPS         # Do not display a line previously found
      setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space
      setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file
      setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry
      setopt HIST_VERIFY               # Don't execute immediately upon history expansion
    '';

    # Shell aliases
    shellAliases = {
      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
      
      # List directory contents
      ls = "eza";
      ll = "eza -l";
      la = "eza -la";
      lt = "eza --tree";
      l = "eza -F";

      # Git
      g = "git";
      ga = "git add";
      gc = "git commit";
      gco = "git checkout";
      gd = "git diff";
      gl = "git log";
      gp = "git push";
      gs = "git status";
      
      # Directory navigation
      md = "mkdir -p";
      rd = "rmdir";
      
      # Grep
      grep = "grep --color=auto";
      fgrep = "fgrep --color=auto";
      egrep = "egrep --color=auto";
      
      # Network
      ip = "ip --color=auto";
      
      # Other
      vim = "nvim";
      vi = "nvim";
      v = "nvim";
      cat = "bat";
      top = "htop";
      du = "dust";
      df = "duf";
      http = "curlie";
      
      # Nix
      nd = "nix develop";
      ns = "nix shell";
      nb = "nix build";
      nf = "nix flake";
      
      # Docker
      d = "docker";
      dc = "docker-compose";
      dps = "docker ps";
      
      # Kubernetes
      k = "kubectl";
      kc = "kubectx";
      kn = "kubens";
      
      # System
      update = "darwin-rebuild switch --flake .";
    };

    plugins = [
      {
        name = "zsh-nix-shell";
        file = "nix-shell.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "chisui";
          repo = "zsh-nix-shell";
          rev = "v0.7.0";
          sha256 = "149zh2rm59blr2q458a5irkfh82y3dwdich60s9670kl3cl5h2m1";
        };
      }
      {
        name = "zsh-autopair";
        file = "autopair.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "hlissner";
          repo = "zsh-autopair";
          rev = "34a8bca0c18fcf3ab1561caef9790abffc1d3d49";
          sha256 = "1h0vm2dgrmb8i2pvsgis3lshc5b0ad846836m62y8h3rdb3zmpy1";
        };
      }
    ];

    # Environment variables
    sessionVariables = {
      # XDG Base Directory
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";

      # Path
      PATH = "$HOME/.local/bin:$PATH";

      # Editor
      EDITOR = "nvim";
      VISUAL = "nvim";
      
      # Locale
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      
      # Colors
      CLICOLOR = 1;
      
      # Less
      LESS = "-R";
      LESSHISTFILE = "-";
      
      # Node
      NODE_REPL_HISTORY = "$XDG_DATA_HOME/node_repl_history";
      
      # Python
      PYTHONSTARTUP = "$XDG_CONFIG_HOME/python/pythonrc";
      IPYTHONDIR = "$XDG_CONFIG_HOME/ipython";
      
      # Rust
      CARGO_HOME = "$XDG_DATA_HOME/cargo";
      RUSTUP_HOME = "$XDG_DATA_HOME/rustup";
      
      # Go
      GOPATH = "$XDG_DATA_HOME/go";
      
      # Docker
      DOCKER_CONFIG = "$XDG_CONFIG_HOME/docker";
      
      # Kubernetes
      KUBECONFIG = "$XDG_CONFIG_HOME/kube/config";
    };
  };
}
