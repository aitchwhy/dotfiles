{ config, lib, pkgs, ... }:

let
  # Common user configuration
  commonUserConfig = {
    name = "hank";
    home = "/Users/hank";
    shell = pkgs.zsh;
  };

  # Device-specific configurations
  deviceConfigs = {
    "hank-mbp" = {
      description = "Hank's MacBook Pro";
      # Add any MacBook Pro specific settings here
    };
    
    "hank-mstio" = {
      description = "Hank's Mac Studio";
      # Add any Mac Studio specific settings here
    };
  };

  # Get current hostname
  currentHostname = config.networking.hostName;

  # Get device-specific config or empty set if not found
  deviceConfig = deviceConfigs.${currentHostname} or {};

in {
  # Create the user with combined configuration
  users.users.hank = commonUserConfig // deviceConfig;

  # System-wide environment variables
  environment = {
    # Shell configuration
    shells = [ pkgs.zsh ];
    loginShell = pkgs.zsh;

    # System-wide variables
    systemPath = [ "/opt/homebrew/bin" ];
    pathsToLink = [ "/Applications" ];
  };

  # Host-specific networking configuration
  networking = {
    # Set computer name and hostname
    computerName = deviceConfig.description or "Hank's Mac";
    hostName = currentHostname;
    
    # DNS configuration
    dns = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };

  # System defaults that may vary by host
  system.defaults = {
    # Dock settings
    dock = {
      autohide = true;
      orientation = "bottom";
      showhidden = true;
      mineffect = "scale";
      launchanim = true;
      show-process-indicators = true;
      tilesize = 48;
    };

    # Finder settings
    finder = {
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
      _FXShowPosixPathInTitle = true;
    };

    # Global system settings
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      AppleShowScrollBars = "WhenScrolling";
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
    };

    # Login window settings
    loginwindow = {
      GuestEnabled = false;
      DisableConsoleAccess = true;
    };
  };

  # Security settings that may vary by device
  security.pam.enableSudoTouchIdAuth = true;
}
