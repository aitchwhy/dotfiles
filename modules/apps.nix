{ config, pkgs, ... }:

{
  # GUI Applications
  homebrew.casks = [
    # Browsers
    "firefox"
    "google-chrome"
    
    # Development
    "visual-studio-code"
    "iterm2"
    "ghostty"
    "docker"
    
    # Utilities
    "rectangle"
    "karabiner-elements"
    "1password"
    
    # Communication
    "slack"
    "discord"
    
    # Media
    "spotify"
  ];

  # Terminal Applications
  environment.systemPackages = with pkgs; [
    # Development Tools
    neovim
    vscode
    ghostty
    
    # Version Control
    git
    lazygit
    
    # Shell Tools
    zsh
    starship
    zellij
    
    # System Monitoring
    htop
    bottom
    
    # File Management
    fd
    ripgrep
    eza
    bat
    
    # Development Environment
    direnv
    
    # Shell History
    atuin
    
    # Other CLI Tools
    jq
    yq-go
    fzf
    tmux
  ];

  # Application specific configurations
  programs = {
    # Terminal Emulator
    alacritty.enable = true;

    # Neovim
    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      defaultEditor = true;
    };

    # Zellij Terminal Multiplexer
    zellij = {
      enable = true;
    };

    # VSCode
    vscode = {
      enable = true;
      package = pkgs.vscode;
    };
  };

  # Hammerspoon configuration
  services.hammerspoon = {
    enable = true;
    package = pkgs.hammerspoon;
  };

  # Application specific settings
  system.defaults.CustomSystemPreferences = {
    # VSCode settings
    "com.microsoft.VSCode" = {
      ApplePressAndHoldEnabled = false;
    };

    # Terminal settings
    "com.apple.Terminal" = {
      DefaultProfileName = "Pro";
      StringEncodings = [4];
    };

    # iTerm2 settings
    "com.googlecode.iterm2" = {
      PromptOnQuit = false;
    };
  };
}
