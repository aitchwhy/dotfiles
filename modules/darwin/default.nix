{ pkgs, username, ... }:

{
  imports = [
    ./system.nix
    ./homebrew.nix
  ];

  # Enable nix-darwin system management
  services.nix-daemon.enable = true;

  # Create /etc/zshrc that loads the nix-darwin environment
  programs.zsh.enable = true;
  environment.shells = [ pkgs.zsh ];

  # System-wide packages
  environment = {
    systemPackages = with pkgs; [
      # Core utils
      coreutils
      curl
      wget
      git
      neovim

      # Development tools
      gnumake
      cmake
      ninja
      pkg-config

      # System tools
      htop
      tree
      ripgrep
      fd
      jq
      yq

      # Nix tools
      nixfmt
      nil # Nix language server
      
      # Build tools
      just # Justfile runner
    ];

    # Environment variables
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      PAGER = "less -R";
    };

    # Add paths to PATH
    pathsToLink = [ "/Applications" "/bin" ];
  };

  # Set up user
  users.users.${username} = {
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };

  # Fonts
  fonts = {
    # Enable fonts dir
    fontDir.enable = true;

    # Install fonts
    packages = with pkgs; [
      # Nerd fonts
      (nerdfonts.override {
        fonts = [
          "JetBrainsMono"
          "FiraCode"
          "Hack"
          "NerdFontsSymbolsOnly"
        ];
      })

      # Other fonts
      font-awesome
      material-design-icons
    ];
  };

  # System defaults
  system = {
    # Enable keyboard mapping
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };

    # Add ability to use TouchID for sudo
    security.pam.enableSudoTouchIdAuth = true;

    # Set default applications
    defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        AppleShowScrollBars = "Always";
        NSDocumentSaveNewDocumentsToCloud = false;
      };
    };
  };
}
