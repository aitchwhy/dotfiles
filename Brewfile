tap "dotenvx/brew"
tap "homebrew/bundle"
tap "homebrew/services"
tap "koekeishiya/formulae"
tap "olets/tap"
tap "sachaos/todoist"
tap "stripe/stripe-cli"
tap "temporalio/brew"
tap "typesense/tap"
tap "waydabber/betterdisplay"
tap "xo/xo"
tap "yakitrak/yakitrak"

# Set cask install dir to ~/Applications (user level)
cask_args appdir: "~/Applications", require_sha: true

###############################################################################
# Development Tools & Languages
###############################################################################
# Databases
brew "postgresql@17" 
brew "minio"                     # High Performance, Kubernetes Native Object Storage
brew "neo4j"                     # Graph database

# JavaScript/TypeScript
brew "biome"                     # Toolchain of the web
brew "esbuild"                   # Extremely fast JavaScript bundler and minifier
brew "eslint"                    # AST-based pattern checker for JavaScript
brew "prettier"                  # Code formatter for JavaScript, CSS, JSON, GraphQL, Markdown, YAML
brew "rollup"                    # Next-generation ES module bundler
brew "typescript-language-server" # Language Server Protocol implementation for TypeScript
brew "vite"                      # Next generation frontend tooling
brew "volta"                     # JavaScript toolchain manager for reproducible environments
brew "vscode-langservers-extracted" # Language servers for HTML, CSS, JavaScript, and JSON

# Python
brew "black"                     # Python code formatter
brew "pyenv"                     # Python version management
brew "pyright"                   # Static type checker for Python
brew "scrapy"                    # Web crawling & scraping framework

# Lua
brew "lua"                       # Powerful, lightweight programming language
brew "lua-language-server"       # Language Server for the Lua language
brew "luarocks"                  # Package manager for the Lua programming language
brew "stylua"                    # Opinionated Lua code formatter

# Rust
brew "rust-analyzer"             # Experimental Rust compiler front-end for IDEs

# Go
brew "gopls"                     # Language server for the Go language

# Ruby
brew "ruby"                      # Powerful, clean, object-oriented scripting language

# Other Languages & Language Servers
brew "bash-language-server"      # Language Server for Bash
brew "cmake"                     # Cross-platform make
brew "marksman"                  # Language Server Protocol for Markdown
brew "nasm"                      # Netwide Assembler (NASM) is an 80x86 assembler
brew "tectonic"                  # Modernized, complete, self-contained TeX/LaTeX engine
brew "yaml-language-server"      # Language Server for Yaml Files

###############################################################################
# Editors & IDEs
###############################################################################
brew "helix"                     # Post-modern modal text editor
brew "neovim"                    # Ambitious Vim-fork focused on extensibility and agility

###############################################################################
# CLI Utilities & Shell Tools
###############################################################################
# Shell Enhancements
# brew "atuin", restart_service: :changed  # Improved shell history for zsh, bash, fish and nushell
brew "direnv"                    # Load/unload environment variables based on $PWD
brew "starship"                  # Cross-shell prompt for astronauts
brew "zoxide"                    # Shell extension to navigate your filesystem faster
brew "zsh-autopair"              # Auto-close and delete matching delimiters in zsh
brew "zsh-autosuggestions"       # Fish-like fast/unobtrusive autosuggestions for zsh
brew "zsh-completions"           # Additional completion definitions for zsh
brew "zsh-history-substring-search" # Zsh port of Fish shell's history search
brew "zsh-syntax-highlighting"   # Fish shell like syntax highlighting for zsh
brew "olets/tap/zsh-abbr"        # Auto-expanding abbreviations manager for zsh, inspired by fish
brew "olets/tap/zsh-autosuggestions-abbreviations-strategy" # Plugin for zsh-abbr

# Terminal Multiplexers & Managers
brew "tmux"                      # Terminal multiplexer
brew "zellij"                    # Pluggable terminal workspace, with terminal multiplexer

# Terminal File Managers & Navigation
brew "broot"                     # New way to see and navigate directory trees
brew "eza"                       # Modern, maintained replacement for ls
brew "fd"                        # Simple, fast and user-friendly alternative to find
brew "fzf"                       # Command-line fuzzy finder
brew "just"                      # Handy way to save and run project-specific commands
brew "yazi"                      # Blazing fast terminal file manager written in Rust

# System Monitoring & Information
brew "duf"                       # Disk Usage/Free Utility - a better 'df' alternative
brew "dust"                      # More intuitive version of du in rust
brew "glances"                   # Alternative to top/htop
brew "gping"                     # Ping, but with a graph
brew "htop"                      # Improved top (interactive process viewer)
brew "hyperfine"                 # Command-line benchmarking tool
brew "procs"                     # Modern replacement for ps written in Rust
brew "speedtest-cli"             # Command-line interface for speedtest.net bandwidth tests
brew "trippy"                    # Network diagnostic tool, inspired by mtr

# Text Processing & Viewing
brew "angle-grinder"             # Slice and dice log files on the command-line
brew "bat"                       # Clone of cat(1) with syntax highlighting and Git integration
brew "diff-so-fancy"             # Good-lookin' diffs with diff-highlight and more
brew "glow"                      # Render markdown on the CLI
brew "gron"                      # Make JSON greppable
brew "hexyl"                     # Command-line hex viewer
brew "jq"                        # Lightweight and flexible command-line JSON processor
brew "lnav"                      # Curses-based tool for viewing and analyzing log files
brew "miller"                    # Like sed, awk, cut, join & sort for name-indexed data such as CSV
brew "pandoc"                    # Swiss-army knife of markup format conversion
brew "ripgrep"                   # Search tool like grep and The Silver Searcher
brew "sd"                        # Intuitive find & replace CLI
brew "sq"                        # Data wrangler with jq-like query language
brew "yq"                        # Process YAML, JSON, XML, CSV and properties documents from the CLI

# CLI Apps & Utilities
# brew "cheat"                     # Create and view interactive cheat sheets for *nix commands
brew "dasht"                     # Search API docs offline, in your terminal or browser
brew "tlrc"                      # Official tldr client written in Rust
brew "xxh"                       # Bring your favorite shell wherever you go through the ssh

###############################################################################
# Development Tools & Utilities
###############################################################################
# Version Control
brew "git"                       # Distributed revision control system
brew "git-delta"                 # Syntax-highlighting pager for git and diff output
brew "gh"                        # GitHub command-line tool
brew "ghi"                       # Work on GitHub issues on the command-line
brew "lazygit"                   # Simple terminal UI for git commands

# Code Quality & Analysis
brew "actionlint"                # Static checker for GitHub Actions workflow files
brew "ast-grep"                  # Code searching, linting, rewriting
brew "grex"                      # Command-line tool for generating regular expressions
brew "jd"                        # JSON diff and patch
brew "shfmt"                     # Autoformat shell script source code
brew "shellcheck"                # Static analysis and lint tool, for (ba)sh scripts

# AI & ML Tools
brew "aider"                     # AI pair programming in your terminal
brew "huggingface-cli"           # Client library for huggingface.co hub

###############################################################################
# DevOps, Cloud & Infrastructure
###############################################################################
# Container & Orchestration Tools
brew "act"                       # Run your GitHub Actions locally
brew "k9s"                       # Kubernetes CLI To Manage Your Clusters In Style!
brew "skaffold"                  # Easy and Repeatable Kubernetes Development
brew "traefik"                   # Modern reverse proxy

# AWS & Cloud Tools
brew "awscli-local"              # Thin wrapper around the `aws` command-line interface for use with LocalStack
brew "cloudflare-wrangler"       # CLI tool for Cloudflare Workers
# brew "gdrive"                    # Google Drive CLI Client
brew "localstack"                # Fully functional local AWS cloud stack
brew "rclone"                    # Rsync for cloud storage
brew "stripe/stripe-cli/stripe"  # Stripe CLI utility
brew "temporal"                  # Command-line interface for Temporal Server and UI
brew "temporalio/brew/tcld"      # Temporal Cloud CLI

# Security & Network
brew "gnupg" if OS.mac?          # GNU Privacy Guard
brew "kanata"                    # Cross-platform software keyboard remapper
brew "netcat"                    # Utility for managing network connections
brew "pinentry-mac"              # Pinentry for GPG on Mac
brew "prometheus"                # Service monitoring system and time series database
brew "rustscan"                  # Modern Day Portscanner
brew "sonic"                     # Fast, lightweight & schema-less search backend
brew "tailscale"                 # Mesh VPN built on WireGuard

###############################################################################
# Media, Files & System Utilities
###############################################################################
# Media Processing
brew "exiftool"                  # Perl lib for reading and writing EXIF metadata
brew "ffmpeg"                    # Play, record, convert, and stream audio and video
brew "imagemagick"               # Tools and libraries to manipulate images in many formats
brew "portaudio"                 # Cross-platform library for audio I/O
brew "speexdsp"                  # Speex audio processing library
brew "weasyprint"                # Convert HTML to PDF
brew "yt-dlp"                    # Feature-rich command-line audio/video downloader

# File & System Operations
brew "aria2"                     # Download with resuming and segmented downloading
brew "bitwarden-cli"             # Secure and free password manager
brew "curl"                      # Get a file from an HTTP, HTTPS or FTP server
brew "curlie"                    # Power of curl, ease of use of httpie
brew "datasette"                 # Open source multi-tool for exploring and publishing data
brew "httpx"                     # http toolkit
brew "httrack"                   # Website copier/offline browser
brew "mas"                       # Mac App Store command-line interface
brew "parallel"                  # Shell command parallelization utility
brew "pkgconf"                   # Package compiler and linker metadata toolkit
brew "posting"                   # Modern API client that lives in your terminal
brew "sevenzip"                  # 7-Zip is a file archiver with a high compression ratio
brew "wget"                      # Internet file retriever
brew "xclip"                     # Access X11 clipboards from the command-line
brew "xcodes"                    # Tool to install and switch between multiple Xcode versions
brew "xh"                        # Friendly and fast tool for sending HTTP requests

# Special Purpose Tools
brew "cutter"                    # Unit Testing Framework for C and C++
brew "chrome-cli"                # Control Google Chrome from the command-line
brew "dotenvx/brew/dotenvx"      # Better dotenv from the creator of `dotenv`
brew "fx"                        # Terminal JSON viewer
brew "koekeishiya/formulae/skhd" # Simple hotkey-daemon for macOS
brew "koekeishiya/formulae/yabai" # Tiling window manager for macOS
brew "sachaos/todoist/todoist"   # Todoist CLI client
brew "yakitrak/yakitrak/obsidian-cli" # CLI for Obsidian

###############################################################################
# Applications (Casks)
###############################################################################
# Cloud & Development Tools
cask "google-cloud-sdk", postinstall: "${HOMEBREW_PREFIX}/bin/gcloud components update"
cask "orbstack"                  # Container and VM manager
cask "tableplus"                 # Database management

# AI & ML Tools
cask "boltai"                    # AI assistant
cask "chatgpt"                   # ChatGPT desktop client
cask "claude"                    # Claude AI assistant
cask "copilot"                   # GitHub Copilot desktop
cask "cursor"                    # Code editor with AI
cask "draw-things"               # AI image generation
cask "lm-studio"                 # Language model studio
cask "macwhisper"                # Audio transcription
cask "ollama"                    # Run LLMs locally
cask "superwhisper"              # Audio transcription

# Productivity & Organization
cask "a-better-finder-rename"    # File renaming utility
cask "anki"                      # Flashcard app
cask "asana"                     # Project management
cask "bartender"                 # Menu bar organizer
cask "bitwarden"                 # Password manager
cask "bunch"                     # App automation
cask "cardhop"                   # Contact manager
cask "charmstone"                # Quick actions
cask "cleanshot"                 # Screenshot utility
cask "cork"                      # Note taking
cask "dash"                      # API documentation
# cask "devonthink"                # Document management
cask "espanso"                   # Text expander
cask "fantastical"               # Calendar app
cask "hazel"                     # File automation
cask "homerow"                   # Keyboard navigation
cask "iconjar"                   # Icon manager
cask "linear-linear"             # Project management
cask "obsidian"                  # Note taking
# cask "paletro"                   # Command palette
cask "pdf-expert"                # PDF editor
# cask "quit-all"                  # Quit all apps
cask "raycast"                   # App launcher
cask "rippling"                  # HR platform
cask "rize"                      # Time tracker
cask "soulver"                   # Smart calculator
cask "swish"                     # Window manager
cask "timelane"                  # Time tracking
cask "todoist"                   # Todo list
# cask "typora"                    # Markdown editor

# Development & Design
cask "apidog"                    # API development
cask "bruno"                     # API client
# cask "canva"                     # Design tool
cask "devutils"                  # Developer utilities
cask "excalidrawz"               # Diagramming
# cask "figma"                     # Design tool
cask "ghostty"                   # Terminal emulator
cask "hammerspoon"               # Automation tool
cask "hopper-disassembler"       # Disassembler
cask "httpie"                    # API client
cask "istat-menus"               # System monitor
cask "kaleidoscope"              # Diff tool
cask "karabiner-elements"        # Keyboard customizer
cask "proxyman"                  # HTTP debugging proxy
cask "syntax-highlight"          # Syntax highlighter
cask "termius"                   # SSH client
cask "tower"                     # Git client
cask "visual-studio-code"        # Code editor
cask "warp"                      # Terminal
# cask "zed"                       # Code editor

# System Utilities
cask "betterdisplay"             # Display management
# cask "blackhole-16ch"            # Audio routing
cask "cleanmymac"                # System cleaner
# cask "cleaneronepro"             # System cleaner
# cask "cloudflare-warp"           # Secure DNS
cask "daisydisk"                 # Disk space analyzer
cask "keka"                      # File archiver
cask "kekaexternalhelper"        # Helper for Keka
# cask "keycastr"                  # Key visualizer
cask "keymapp"                   # Keyboard mapping
cask "motrix"                    # Download manager
# cask "osquery"                   # OS instrumentation
cask "proton-mail"               # Email client
cask "protonvpn"                 # VPN client
cask "qflipper"                  # Flipper Zero utility
cask "royal-tsx"                 # Remote connections
cask "soundsource"               # Audio control
cask "tailscale"                 # Mesh VPN
cask "virtualbuddy"              # macOS VM manager
# cask "windsurf"                  # Window management
cask "yubico-authenticator"      # YubiKey tool
cask "yubico-yubikey-manager"    # YubiKey manager

# Communication & Media
# cask "arc"                       # Web browser
cask "descript"                  # Audio/video editor
cask "firefox"                   # Web browser
cask "follow"                    # RSS reader
cask "google-chrome"             # Web browser
cask "jump"                      # Remote desktop
cask "jump-desktop-connect"      # Remote desktop
# cask "parsec"                    # Remote desktop
cask "signal"                    # Messaging
cask "slack"                     # Team communication
cask "spotify"                   # Music streaming
cask "superhuman"                # Email client
cask "zen-browser"               # Minimal browser
cask "zoom"                      # Video conferencing

# Fonts
cask "font-fira-mono-nerd-font"  # Nerd Font
cask "font-jetbrains-mono-nerd-font" # Nerd Font
cask "font-mononoki-nerd-font"   # Nerd Font
cask "font-roboto-mono-nerd-font" # Nerd Font
cask "font-sf-mono-nerd-font-ligaturized" # Nerd Font
cask "font-symbols-only-nerd-font" # Nerd Font

# Specialist Tools
cask "audacity"                  # Audio editor
cask "ghidra"                    # Software reverse engineering

# Commented out less frequently used apps
# cask "session"                 # Messaging app
# cask "synologyassistant"       # Synology management
# cask "wireshark"               # Network protocol analyzer

###############################################################################
# Mac App Store Applications
###############################################################################
# Productivity & Organization
mas "Alpenglow", id: 978589174        # Sunset times
mas "Amphetamine", id: 937984704      # Keep Mac awake
mas "Bear", id: 1091189122            # Note-taking
mas "Day One", id: 1055511498         # Journaling
mas "Drafts", id: 1435957248          # Text capture
mas "HacKit", id: 1549557075          # Markdown editor
mas "Omnivore", id: 1564031042        # Read-it-later
mas "Parcel", id: 639968404           # Package tracking
mas "Paste", id: 967805235            # Clipboard manager
# mas "Monica AI: Deep Chat & Search", id: 6450770590

# Travel & Lifestyle
mas "Flighty", id: 1358823008         # Flight tracking
mas "Journey", id: 1662059644         # Journaling
mas "Mela", id: 1568924476            # Recipe manager
mas "Tripsy", id: 1429967544          # Trip planning

# Reading & Media
mas "KakaoTalk", id: 869223134        # Messaging
mas "Kindle", id: 302584613           # E-book reader
mas "Pixea", id: 1507782672           # Image viewer

# Utilities
mas "Bitwarden", id: 1352778147      # Already have cask
mas "LanScan", id: 472226235          # Network scanner

# Commented out less frequently used Mac App Store apps

# mas "Aiko", id: 1672085276
# mas "CleanMyMac", id: 1339170533     # Already have cask
# mas "Cleaner One Pro", id: 1133028347 # Already have cask
# mas "DaisyDisk", id: 411643860       # Already have cask
# mas "ExcalidrawZ", id: 6636493997    # Already have cask
# mas "Keynote", id: 409183694         # Apple productivity suite
# mas "Numbers", id: 409203825         # Apple productivity suite
# mas "One Thing", id: 1604176982      # Simple todo app
# mas "Pages", id: 409201541           # Apple productivity suite
# mas "Session", id: 1521432881        # Already have cask

###############################################################################
# VSCode Extensions
###############################################################################
# Essential Extensions

# Core Functionality
vscode "dbaeumer.vscode-eslint"             # ESLint integration
vscode "esbenp.prettier-vscode"             # Code formatting
vscode "editorconfig.editorconfig"          # EditorConfig support
vscode "formulahendry.auto-close-tag"       # Automatically close HTML/XML tags
vscode "formulahendry.auto-rename-tag"      # Automatically rename paired HTML/XML tags
vscode "github.copilot"                     # AI code completion
vscode "github.copilot-chat"                # AI chat interface
vscode "gruntfuggly.todo-tree"              # Find and highlight TODOs
vscode "oderwat.indent-rainbow"             # Makes indentation more readable
vscode "usernamehw.errorlens"               # Inline error messages
vscode "vscode-icons-team.vscode-icons"     # File and folder icons

# Utility & Navigation  
vscode "alefragnani.project-manager"        # Project management
vscode "christian-kohler.path-intellisense" # Autocomplete filenames
vscode "patbenatar.advanced-new-file"       # Advanced file creation
vscode "sleistner.vscode-fileutils"         # File operations in VSCode
vscode "tyriar.sort-lines"                  # Sort lines of text
vscode "vspacecode.whichkey"                # Keybinding menu

# Git & Collaboration
vscode "github.vscode-github-actions"       # GitHub Actions
vscode "vivaxy.vscode-conventional-commits" # Conventional commit support

# Languages & Frameworks

# JavaScript/TypeScript
vscode "biomejs.biome"                      # JavaScript/TypeScript formatting
vscode "bradlc.vscode-tailwindcss"          # Tailwind CSS support
vscode "christian-kohler.npm-intellisense"  # Auto-completes npm modules
vscode "wix.vscode-import-cost"             # Display import size
vscode "mgmcdermott.vscode-language-babel"  # Babel syntax highlighting
vscode "prisma.prisma"                      # Prisma ORM support
vscode "golang.go"                          # Go support
vscode "rust-lang.rust-analyzer"            # Rust support
vscode "ms-python.python"                   # Python support
vscode "ms-python.black-formatter"          # Python formatter
vscode "charliermarsh.ruff"                 # Python linter
vscode "bierner.markdown-mermaid"           # Mermaid diagram support in markdown
vscode "redhat.vscode-yaml"                 # YAML support
vscode "hashicorp.terraform"                # Terraform support
vscode "ms-azuretools.vscode-docker"        # Docker support
vscode "ms-kubernetes-tools.vscode-kubernetes-tools" # Kubernetes support
vscode "mtxr.sqltools"                      # SQL tools
vscode "ckolkman.vscode-postgres"           # PostgreSQL support

# Remote Development & APIs
vscode "ms-vscode-remote.vscode-remote-extensionpack" # Remote development
vscode "rangav.vscode-thunder-client"       # HTTP client
vscode "humao.rest-client"                  # REST client
vscode "ms-vscode.remote-explorer"          # Remote Explorer
vscode "redocly.openapi-vs-code"            # OpenAPI support

# Themes & UI
vscode "sdras.night-owl"                    # Night Owl theme
vscode "catppuccin.catppuccin-vsc"          # Catppuccin theme
vscode "zhuangtongfa.material-theme"        # One Dark Pro theme

# VSCode Neovim & Vim
vscode "asvetliakov.vscode-neovim"          # Neovim integration
vscode "vscodevim.vim"                      # Vim emulation
vscode "vspacecode.vspacecode"              # Spacemacs-like bindings

# AI & Documentation
vscode "saoudrizwan.claude-dev"             # Claude AI integration
vscode "mintlify.document"                  # Documentation generator

# Markdown & Documentation
vscode "yzhang.markdown-all-in-one"         # Markdown tools
vscode "davidanson.vscode-markdownlint"     # Markdown linting

# Commented out extensions (less essential or redundant)
# vscode "42crunch.vscode-openapi"            # Already have redocly.openapi-vs-code
# vscode "4ops.terraform"                     # Already have hashicorp.terraform
# vscode "aaron-bond.better-comments"         # Not essential
# vscode "actboy168.lua-debug"                # Specialized
# vscode "akamud.vscode-javascript-snippet-pack" # Snippet packs can be redundant
# vscode "alefragnani.bookmarks"              # Not essential for most workflows
# vscode "alefragnani.rtf"                    # Very specialized
# vscode "amazonemr.emr-tools"                # Specialized AWS service
# vscode "amazonwebservices.aws-toolkit-vscode" # Specialized cloud service
# vscode "antfu.browse-lite"                  # Not essential
# vscode "antfu.file-nesting"                 # Nice to have but not essential
# vscode "antfu.icons-carbon"                 # UI enhancement, not essential
# vscode "antfu.vite"                         # Specialized for Vite users
# vscode "anysphere.pyright"                  # Redundant with ms-python
# vscode "arcticicestudio.nord-visual-studio-code" # Additional theme
# vscode "arianjamasb.protein-viewer"         # Very specialized
# vscode "arrterian.nix-env-selector"         # Specialized for Nix users
# vscode "atishay-jain.all-autocomplete"      # Can conflict with other completions
# vscode "atlassian.atlascode"                # Specialized for Atlassian users
# vscode "aykutsarac.jsoncrack-vscode"        # Nice to have but not essential
# vscode "batisteo.vscode-django"             # Specialized for Django users
# vscode "bbenoist.nix"                       # Specialized for Nix users
# vscode "bodil.file-browser"                 # Alternative file browser
# vscode "bpruitt-goddard.mermaid-markdown-syntax-highlighting" # Already have bierner.markdown-mermaid
# vscode "buenon.scratchpads"                 # Nice to have but not essential
# vscode "burkeholland.simple-react-snippets" # Specialized for React
# vscode "bysabi.prettier-vscode-standard"    # Redundant with prettier
# vscode "catppuccin.catppuccin-vsc-icons"    # UI enhancement
# vscode "chaitanyashahare.lazygit"           # Not essential if using Git extension
# vscode "chrmarti.regex"                     # Specialized
# vscode "clinyong.vscode-css-modules"        # Specialized for CSS modules
# vscode "codezombiech.gitignore"             # Nice to have but not essential
# vscode "cstrap.flask-snippets"              # Specialized for Flask
# vscode "cstrap.python-snippets"             # Specialized Python snippets
# vscode "dart-code.dart-code"                # Specialized for Dart
# vscode "dart-code.flutter"                  # Specialized for Flutter
# vscode "deerawan.vscode-dash"               # Integration with Dash app
# vscode "divyanshuagrawal.competitive-programming-helper" # Very specialized
# vscode "donjayamanne.python-environment-manager" # Specialized Python tool
# vscode "donjayamanne.python-extension-pack" # Includes multiple Python extensions
# vscode "dzhavat.bracket-pair-toggler"       # Not essential with newer VSCode
# vscode "ecmel.vscode-html-css"              # HTML/CSS support
# vscode "emmanuelbeziat.vscode-great-icons"  # Alternative icon theme
# vscode "enkia.tokyo-night"                  # Alternative theme
# vscode "equimper.react-native-react-redux"  # Specialized for React Native
# vscode "ericsia.pythonsnippets3"            # Python snippets
# vscode "eriklynd.json-tools"                # JSON tools
# vscode "evan-buss.font-switcher"            # Font management
# vscode "file-icons.file-icons"              # Alternative file icons
# vscode "firsttris.vscode-jest-runner"       # Jest test runner
# vscode "formulahendry.code-runner"          # Code runner
# vscode "foxundermoon.shell-format"          # Shell formatting
# vscode "frhtylcn.pythonsnippets"            # Python snippets
# vscode "george-alisson.html-preview-vscode" # HTML preview
# vscode "github.codespaces"                  # GitHub Codespaces
# vscode "github.remotehub"                   # GitHub remote
# vscode "gitpod.gitpod-theme"                # Gitpod theme
# vscode "graphql.vscode-graphql-syntax"      # GraphQL syntax
# vscode "honnamkuan.golang-snippets"         # Go snippets
# vscode "ibm.output-colorizer"               # Output colorizer
# vscode "idered.npm"                         # npm support
# vscode "infeng.vscode-react-typescript"     # React TypeScript
# vscode "infracost.infracost"                # Cost estimates for Terraform
# vscode "jacano.vscode-pnpm"                 # pnpm support
# vscode "jacobdufault.fuzzy-search"          # Fuzzy search
# vscode "jasonnutter.search-node-modules"    # Search node modules
# vscode "jawandarajbir.react-vscode-extension-pack" # React extension pack
# vscode "jebbs.plantuml"                     # PlantUML support
# vscode "jithurjacob.nbpreviewer"            # Jupyter notebook previewer
# vscode "jnoortheen.nix-ide"                 # Nix IDE
# vscode "kahole.magit"                       # Magit-like Git interface
# vscode "kamadorueda.alejandra"              # Nix formatter
# vscode "kamikillerto.vscode-colorize"       # Colorize CSS
# vscode
