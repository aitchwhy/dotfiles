{ config, pkgs, lib, ... }:

{
  system = {
    # System version
    stateVersion = 4;

    # Keyboard settings
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };

    # System preferences
    defaults = {
      # Dock settings
      dock = {
        autohide = true;
        show-recents = false;
        mineffect = "scale";
        mru-spaces = false;
        orientation = "bottom";
        tilesize = 48;

        # Hot corners
        wvous-tl-corner = 2;  # Mission Control
        wvous-tr-corner = 13; # Lock Screen
        wvous-bl-corner = 3;  # Application Windows
        wvous-br-corner = 4;  # Desktop
      };

      # Finder settings
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        CreateDesktop = true;
        FXDefaultSearchScope = "SCcf";
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "Nlsv";
        QuitMenuItem = true;
        ShowPathbar = true;
        ShowStatusBar = true;
        _FXShowPosixPathInTitle = true;
      };

      # Trackpad settings
      trackpad = {
        Clicking = true;
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = true;
        ActuationStrength = 1;
        FirstClickThreshold = 1;
        SecondClickThreshold = 1;
      };

      # Global system settings
      NSGlobalDomain = {
        # Keyboard settings
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
        ApplePressAndHoldEnabled = false;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;

        # UI settings
        AppleInterfaceStyle = "Dark";
        AppleShowScrollBars = "WhenScrolling";
        NSWindowResizeTime = 0.001;
        
        # Mouse/Trackpad
        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.swipescrolldirection" = true;
        "com.apple.trackpad.enableSecondaryClick" = true;
      };

      # Additional system settings
      CustomUserPreferences = {
        # Finder preferences
        "com.apple.finder" = {
          ShowExternalHardDrivesOnDesktop = true;
          ShowHardDrivesOnDesktop = true;
          ShowMountedServersOnDesktop = true;
          ShowRemovableMediaOnDesktop = true;
          _FXSortFoldersFirst = true;
          FXDefaultSearchScope = "SCcf";
        };

        # Desktop services
        "com.apple.desktopservices" = {
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };

        # Spaces settings
        "com.apple.spaces" = {
          spans-displays = false;
        };

        # Window manager
        "com.apple.WindowManager" = {
          EnableStandardClickToShowDesktop = false;
          StandardHideDesktopIcons = false;
          HideDesktop = false;
        };

        # Screenshot settings
        "com.apple.screencapture" = {
          location = "~/Desktop";
          type = "png";
        };

        # Security settings
        "com.apple.screensaver" = {
          askForPassword = 1;
          askForPasswordDelay = 0;
        };
      };
    };

    # Activation scripts
    activationScripts.postUserActivation.text = ''
      # Reload system settings
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';
  };

  # Time settings
  time.timeZone = "America/Los_Angeles";

  # System-wide environment settings
  environment = {
    # System packages
    systemPackages = with pkgs; [
      # Basic utilities
      coreutils
      gnused
      gnutar
      gzip
      wget
      curl
      git

      # System tools
      terminal-notifier
    ];

    # System variables
    variables = {
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    # Login shell
    loginShell = pkgs.zsh;
  };

  # Font configuration
  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; [
      (nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" "Hack" ]; })
    ];
  };

  # Services configuration
  services = {
    # Nix daemon service
    nix-daemon.enable = true;

    # Yabai window manager
    yabai = {
      enable = false; # Enable if needed
      package = pkgs.yabai;
      enableScriptingAddition = true;
    };

    # skhd hotkey daemon
    skhd = {
      enable = false; # Enable if needed
      package = pkgs.skhd;
    };
  };
}
