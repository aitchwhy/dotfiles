# darwin/configuration.nix
{ pkgs, ... }: {

  # Because I got this error when running (nix run nix-darwin -- switch --flake {dotfiles dir})
  # Failed assertions:
  #   - The `system.stateVersion` option is not defined in your
  #   nix-darwin configuration. The value is used to conditionalize
  #   backwards‐incompatible changes in default settings. You should
  #   usually set this once when installing nix-darwin on a new system
  #   and then never change it (at least without reading all the relevant
  #   entries in the changelog using `darwin-rebuild changelog`).
  system.stateVersion = 5;

  users.users.hank = {
    name = "hank";
    home = "/Users/hank";
  };

  # fonts.packages =  [
  #   pkgs.font-jetbrains-mono
  #   pkgs.font-mononoki
  #   pkgs.font-noto
  #   pkgs.font-ubuntu
  # ];

  environment = {
    # Use a custom configuration.nix location.
    # Change requires a rebuild (darwin-rebuild switch -I darwin-config=/path/to/configuration.nix)
    # $ darwin-rebuild switch -I darwin-config=$HOME/dotfiles/darwin/configuration.nix
    darwinConfig = "$HOME/dotfiles/darwin";

    # System-wide packages
    systemPackages = [
      # do I need this explicit home-manager install?
      pkgs.home-manager
      pkgs.tailscale
      pkgs.vim
      pkgs.git
      pkgs.curl
    ];

    variables = {
      # Set the default editor
      EDITOR = "vim";
      VISUAL = "vim";
      # Set the default pager
      PAGER = "less";
      # Set the default browser
      # BROWSER = "brave";
    };
  };


  # Auto upgrade nix package and the daemon service.
  nix = {
    package = pkgs.nix;
    settings = {
      "experimental-features" = [ "nix-command" "flakes" ];
      "extra-experimental-features" = [ "nix-command" "flakes" ];
      # Nice for developers
      "keep-outputs" = "true";
      # Idem (?)
      "keep-derivations" = "true";
    };
  };

  # Auto upgrade nix package and the daemon service
  services = {
    nix-daemon = {
      enable = true;
    };
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      # cleanup = "zap"; # Uninstalls all formulae not listed here
    };

    brews = [

      "act"
"actionlint"
"aider"
"angle-grinder"
"ast-grep"
"atuin"
"awscli-local"
"bat"
"biome"
"bitwarden-cli"
"broot"
"cheat"
"cloudflare-wrangler2"
"curlie"
"datasette"
"diff-so-fancy"
"direnv"
"duf"
"dust"
"esbuild"
"eslint"
"exiftool"
"eza"
"fastfetch"
"fd"
"ffmpeg"
"fx"
"fzf"
"gh"
"ghi"
"git-delta"
"glances"
"glow"
"gping"
"grex"
"gron"
"helix"
"hexyl"
"htop"
"http-prompt"
"httrack"
"hurl"
"hyperfine"
"jd"
"jq"
"just"
"k9s"
"kanata"
"koekeishiya/formulae/skhd"
"lazygit"
"localstack"
"lua-language-server"
"luarocks"
"mas"
"mcfly"
"miller"
"minio"
"neovim"
"netcat"
"nmap"
"nnn"
"odin"
"olets/tap/zsh-abbr"
"olets/tap/zsh-autosuggestions-abbreviations-strategy"
"onefetch"
"pandoc"
"pinentry-mac"
"pkgconf"
"poppler"
"posting"
"prettier"
"procs"
"prometheus"
"pyenv"
"rclone"
"ripgrep"
"rollup"
"ruff"
"rust"
"rustscan"
"scrapy"
"sd"
"shellcheck"
"skaffold"
"speedtest-cli"
"speexdsp"
"sq"
"starship"
"stripe/stripe-cli/stripe"
"syncthing"
"temporal"
"temporalio/brew/tcld"
"tldr"
"traefik"
"tree"
"trippy"
"uv"
"vite"
"volta"
"weasyprint"
"wget"
"yazi"
"yq"
"zellij"
"zoxide"
"zsh-autopair"
"zsh-autosuggestions"
"zsh-completions"
"zsh-history-substring-search"
"zsh-syntax-highlighting"

      # For proxmark3, we specify an arg with “with-generic”
      {
        name = "rfidresearchgroup/proxmark3/proxmark3";
        args = [ "with-generic" ];
      }    
      ];

    casks = [
      "a-better-finder-rename"
      "affine"
      "aide-app"
      "anki"
      "apidog"
      "arq"
      "bartender"
      "betterdisplay"
      "boltai"
      "brave-browser"
      "bruno"
      "carbon-copy-cloner"
      "cardhop"
      "chatgpt"
      "claude"
      "cleanshot"
      "copilot"
      "cursor"
      "dash"
      "devutils"
      "fantastical"
      "figma"
      "firefox"
      "follow"
      "font-jetbrains-mono-nerd-font"
      "font-mononoki-nerd-font"
      "font-noto-nerd-font"
      "font-ubuntu-nerd-font"
      "ghidra"
      "ghostty"
      "gitkraken"
      "google-chrome"
      "hammerspoon"
      "hazel"
      "homerow"
      "hopper-disassembler"
      "hoppscotch"
      "httpie"
      "istat-menus"
      "kaleidoscope"
      "karabiner-elements"
      "keycastr"
      "keymapp"
      "lm-studio"
      "marta"
      "miro"
      "motrix"
      "neo4j"
      "obsidian"
      "ollama"
      "orbstack"
      "osquery"
      "pdf-expert"
      "proton-mail"
      "proxyman"
      "qflipper"
      "raycast"
      "signal"
      "slack"
      "soulver"
      "soundsource"
      "spotify"
      "stack"
      "superhuman"
      "swish"
      "tableplus"
      "tailscale"
      "termius"
      "timelane"
      "todoist"
      "tower"
      "typora"
      "visual-studio-code"
      "warp"
      "wireshark"
      "zed"
      "zen-browser"
      "zoom"
      "zotero"
    ];

    masApps = {
      "Bear" = 1091189122;
      "Bitwarden" = 1352778147;
      "Drafts" = 1435957248;
      "Dropover" = 1355679052;
      "KakaoTalk" = 869223134;
      "Keka" = 470158793;
      "LanScan" = 472226235;
      "Pandan" = 1569600264;
      "Perplexity" = 6714467650;
      "Pixea" = 1507782672;
      "Tripsy" = 1429967544;
      "rcmd" = 1596283165;
      "stoic." = 1312926037;
    };
  };

  # System settings
  system = {
    defaults = {
      dock = {
        autohide = true;
        orientation = "bottom";
      };
      finder = {
        AppleShowAllExtensions = true;
        _FXShowPosixPathInTitle = true;
        ShowPathbar = true;

      };
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
      };
    };
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };
  };

  # Enable touch ID for sudo
  security.pam.enableSudoTouchIdAuth = true;

  programs.zsh.enable = true;


  # Set hostname
  # networking.hostName = "Hanks-MacBook-Pro";
}
