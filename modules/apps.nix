{ config, pkgs, ... }:

{
  # Homebrew Configuration
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };

    # Homebrew taps
    taps = [
      "homebrew/bundle"
      "homebrew/services"
      "coder/coder"
      "koekeishiya/formulae"
      "olets/tap"
      "rfidresearchgroup/proxmark3"
      "stripe/stripe-cli"
      "temporalio/brew"
      "typesense/tap"
      "waydabber/betterdisplay"
      "xo/xo"
    ];

    # Homebrew packages (brew install)
    brews = [
      # Development Tools
      "act"
      "shellcheck"
      "actionlint"
      "aider"
      "ast-grep"
      "biome"
      "cloudflare-wrangler2"
      "esbuild"
      "eslint"
      "prettier"
      "rust"
      "volta"

      # Shell Tools
      "atuin"
      "bat"
      "broot"
      "cheat"
      "curlie"
      "diff-so-fancy"
      "direnv"
      "dust"
      "eza"
      "fastfetch"
      "fd"
      "fzf"
      "git-delta"
      "glow"
      "grex"
      "gron"
      "zoxide"
      "zsh-autopair"
      "zsh-autosuggestions"
      "zsh-completions"
      "zsh-history-substring-search"
      "zsh-syntax-highlighting"
      "olets/tap/zsh-abbr"

      # System Tools
      "glances"
      "htop"
      "duf"
      "gping"
      "hexyl"
      "hyperfine"
      "procs"
      "ripgrep"
      "sd"
      "tree"

      # Cloud & Infrastructure
      "awscli-local"
      "k9s"
      "localstack"
      "skaffold"
      "terraform"
      "traefik"

      # Database Tools
      "minio"
      "sq"

      # Media Tools
      "ffmpeg"
      "pandoc"
      "poppler"

      # Version Control
      "gh"
      "ghi"
      "lazygit"

      # Terminal Multiplexer
      "zellij"

      # Language Servers & Development
      "lua-language-server"
      "ruff"

      # Security Tools
      "bitwarden-cli"
      "pinentry-mac"

      # Other Tools
      "jq"
      "yq"
      "wget"
      "coder/coder/coder"
      "koekeishiya/formulae/skhd"
      "rfidresearchgroup/proxmark3/proxmark3"
      "stripe/stripe-cli/stripe"
      "temporalio/brew/tcld"
    ];

    # Mac App Store applications
    masApps = {
      Amphetamine = 937984704;
      Bear = 1091189122;
      BetterSnapTool = 417375580;
      Bitwarden = 1352778147;
      Charmstone = 1563735522;
      Cheatsheet = 1468213484;
      "Cleaner One Pro" = 1133028347;
      Drafts = 1435957248;
      Dropover = 1355679052;
      Fantastical = 975937182;
      Flow = 1423210932;
      Instapaper = 288545208;
      Journey = 1662059644;
      KakaoTalk = 869223134;
      Keka = 470158793;
      Keynote = 409183694;
      "Logic Pro" = 634148309;
      "Marked 2" = 890031187;
      Numbers = 409203825;
      Pages = 409201541;
      Pandan = 1569600264;
      Perplexity = 6714467650;
      Pixea = 1507782672;
      stoic = 1312926037;
      "Toggl Track" = 1291898086;
      Tripsy = 1429967544;
      "Yubico Authenticator" = 1497506650;
      WhatsApp = 310633997;
    };

    # Homebrew Casks (GUI Applications)
    casks = [
      # Productivity
      "a-better-finder-rename"
      "affine"
      "aide-app"
      "anki"
      "bartender"
      "bettertouchtool"
      "cardhop"
      "devtoys"
      "devutils"
      "fantastical"
      "hazel"
      "homerow"
      "itsycal"
      "keyclu"
      "raycast"
      "rize"
      "soulver"
      "timing"
      "todoist"

      # Development
      "apidog"
      "bruno"
      "cursor"
      "dash"
      "fork"
      "ghostty"
      "gitkraken"
      "hoppscotch"
      "httpie"
      "kaleidoscope"
      "proxyman"
      "termius"
      "visual-studio-code"
      "warp"
      "zed"

      # Browsers
      "arc"
      "brave-browser"
      "firefox"
      "google-chrome"
      "vivaldi"
      "zen-browser"

      # Communication
      "discord"
      "signal"
      "superhuman"
      "zoom"

      # Media
      "iina"
      "spotify"

      # Security
      "1password"
      "bitwarden"
      "little-snitch"
      "proton-drive"
      "proton-mail"
      "proton-mail-bridge"
      "proton-pass"
      "protonvpn"
      "yubico-yubikey-manager"

      # System Tools
      "appcleaner"
      "betterdisplay"
      "hammerspoon"
      "istat-menus"
      "karabiner-elements"
      "maccy"
      "sensei"

      # AI & ML
      "boltai"
      "chatgpt"
      "claude"
      "copilot"
      "lm-studio"
      "ollama"

      # Design
      "excalidrawz"
      "figma"
      "imageoptim"
      "miro"

      # Fonts
      "font-jetbrains-mono-nerd-font"
      "font-mononoki-nerd-font"
      "font-noto-nerd-font"
      "font-ubuntu-nerd-font"

      # Other
      "anydesk"
      "arq"
      "carbon-copy-cloner"
      "obsidian"
      "orbstack"
      "pdf-expert"
      "synologyassistant"
      "tailscale"
      "typora"
      "virtualbuddy"
      "wireshark"
      "zotero"
    ];
  };

  # System packages (installed via nix)
  environment.systemPackages = with pkgs; [
    # Development
    git
    neovim
    vscode
    
    # Shell
    zsh
    starship
    
    # System Tools
    htop
    ripgrep
    fd
    eza
    bat
    
    # Other
    curl
    wget
    jq
  ];
}
