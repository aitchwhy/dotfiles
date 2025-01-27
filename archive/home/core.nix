{ config, pkgs, username, ... }:

{
  home = {
    username = username;
    homeDirectory = "/Users/${username}";
    stateVersion = "24.05";

    # Environment variables
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      PAGER = "less -R";
      CLICOLOR = 1;
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      TERM = "xterm-256color";
    };

    # User packages
    packages = with pkgs; [
      # Development
      nodejs_20
      python311
      go
      rustup
      docker
      docker-compose

      # Build tools
      cmake
      gnumake
      ninja
      pkg-config

      # Archives
      zip
      xz
      unzip
      p7zip

      # CLI tools
      ripgrep
      fd
      jq
      yq-go
      fzf
      bat
      eza
      zoxide
      htop
      tree
      wget
      curl
      git
      gh
      socat
      nmap
      aria2
      caddy
      gnupg

      # System tools
      file
      which
      gnused
      gnutar
      gawk
      zstd

      # Fun
      cowsay
      glow # markdown previewer in terminal

      # Languages & Language Servers
      nil # Nix
      rust-analyzer
      gopls
      nodePackages.typescript-language-server
      nodePackages.vscode-langservers-extracted
      python311Packages.python-lsp-server
      
      # Formatters & Linters
      nixfmt
      alejandra
      stylua
      shfmt
      shellcheck
      prettier
      black
      ruff

      # Other tools
      _1password
      awscli2
      terraform
      kubectl
      k9s
    ];
  };

  # XDG Base Directory specification
  xdg = {
    enable = true;
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    cacheHome = "${config.home.homeDirectory}/.cache";
  };

  # Basic program configurations
  programs = {
    home-manager.enable = true;
    bat.enable = true;
    fzf.enable = true;
    zoxide.enable = true;
    direnv.enable = true;
    eza = {
      enable = true;
      git = true;
      icons = true;
      enableZshIntegration = true;
    };
    yazi = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        manager = {
          show_hidden = true;
          sort_dir_first = true;
        };
      };
    };
    skim = {
      enable = true;
      enableBashIntegration = true;
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable fonts
  fonts.fontconfig.enable = true;
}
