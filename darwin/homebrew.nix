{ config, lib, ... }:

{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap"; # Uninstall not listed packages/casks
      upgrade = true;
    };

    # Taps
    taps = [
      "homebrew/bundle"
      "homebrew/services"
      "homebrew/cask-fonts"
      "koekeishiya/formulae"
      "olets/tap"
      "rfidresearchgroup/proxmark3"
      "stripe/stripe-cli"
      "temporalio/brew"
      "typesense/tap"
      "waydabber/betterdisplay"
      "xo/xo"
    ];

    # Brew Packages
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
      "gh"
      "ghi"
      "helix"
      "lazygit"
      "lua-language-server"
      "neovim"
      "prettier"
      "ruff"
      "rust"

      # Shell Tools
      "atuin"
      "direnv"
      "fzf"
      "mcfly"
      "starship"
      "zoxide"
      "zsh-autopair"
      "zsh-autosuggestions"
      "zsh-completions"
      "zsh-history-substring-search"
      "zsh-syntax-highlighting"
      "zsh-abbr"

      # System Tools
      "bat"
      "broot"
      "curlie"
      "diff-so-fancy"
      "duf"
      "dust"
      "eza"
      "fastfetch"
      "fd"
      "git-delta"
      "glances"
      "glow"
      "gping"
      "grex"
      "gron"
      "hexyl"
      "htop"
      "hyperfine"
      "jq"
      "just"
      "miller"
      "nnn"
      "parallel"
      "procs"
      "ripgrep"
      "sd"
      "tldr"
      "tree"
      "yazi"
      "yq"
      "zellij"

      # Cloud & Infrastructure
      "awscli-local"
      "k9s"
      "localstack"
      "minio"
      "skaffold"
      "temporal"
      "traefik"

      # Media & Files
      "exiftool"
      "ffmpeg"
      "pandoc"
      "poppler"
      "rclone"

      # Network Tools
      "netcat"
      "nextdns"
      "nmap"
      "rustscan"
      "speedtest-cli"
      "wget"

      # Security
      "bitwarden-cli"

      # Other
      "luarocks"
      "mas"
      "odin"
      "onefetch"
      "pinentry-mac"
      "pkgconf"
      "posting"
      "prometheus"
      "pyenv"
      "rollup"
      "scrapy"
      "speexdsp"
      "sq"
      "syncthing"
      "uv"
      "vite"
      "volta"
      "weasyprint"
    ];

    # Cask Apps
    casks = [
      # Browsers
      "arc"
      "brave-browser"
      "firefox"
      "google-chrome"
      "vivaldi"
      "zen-browser"

      # Development
      "cursor"
      "dash"
      "devtoys"
      "devutils"
      "fork"
      "ghostty"
      "gitkraken"
      "hopper-disassembler"
      "httpie"
      "orbstack"
      "proxyman"
      "tableplus"
      "tower"
      "visual-studio-code"
      "warp"

      # Productivity
      "affine"
      "anki"
      "bartender"
      "cardhop"
      "cleanshot-x"
      "fantastical"
      "hazel"
      "homerow"
      "obsidian"
      "pdf-expert"
      "raycast"
      "superhuman"
      "todoist"
      "typora"
      "zotero"

      # Media
      "iina"
      "soundsource"
      "spotify"

      # Communication
      "discord"
      "signal"
      "slack"
      "whatsapp"
      "zoom"

      # Security & Privacy
      "bitwarden"
      "little-snitch"
      "proton-drive"
      "proton-mail"
      "proton-mail-bridge"
      "proton-pass"
      "protonvpn"
      "yubico-yubikey-manager"

      # System Tools
      "a-better-finder-rename"
      "betterdisplay"
      "carbon-copy-cloner"
      "hammerspoon"
      "karabiner-elements"
      "keycastr"
      "sensei"
      "swish"

      # AI & ML
      "boltai"
      "chatgpt"
      "claude"
      "copilot"
      "lm-studio"
      "ollama"

      # Other
      "apidog"
      "bruno"
      "excalidrawz"
      "figma"
      "hoppscotch"
      "miro"
      "motrix"
      "neo4j"
      "qlmarkdown"
      "rize"
      "synologyassistant"
      "tailscale"
      "termius"
    ];

    # Mac App Store
    masApps = {
      "Bear" = 1091189122;
      "Bitwarden" = 1352778147;
      "Charmstone" = 1563735522;
      "Cleaner One Pro" = 1133028347;
      "Drafts" = 1435957248;
      "Dropover" = 1355679052;
      "Fantastical" = 975937182;
      "Flow" = 1423210932;
      "KakaoTalk" = 869223134;
      "Keka" = 470158793;
      "Keynote" = 409183694;
      "LanScan" = 472226235;
      "Logic Pro" = 634148309;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Pandan" = 1569600264;
      "Perplexity" = 6714467650;
      "Pixea" = 1507782672;
      "stoic." = 1312926037;
      "Toggl Track" = 1291898086;
      "Tripsy" = 1429967544;
      "Yubico Authenticator" = 1497506650;
      "WhatsApp" = 310633997;
    };
  };
}