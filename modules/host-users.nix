{ config, pkgs, username, hostname, ... }:

{
  # Create user account
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };

  # Host-specific user settings
  system.defaults.CustomUserPreferences = {
    # Common settings for all hosts
    "com.apple.dock" = {
      autohide = true;
      orientation = "bottom";
      tilesize = 48;
    };

    # Host-specific settings
    } // (if hostname == "hank-mbp" then {
      # MacBook Pro specific settings
      "com.apple.trackpad" = {
        TrackpadThreeFingerDrag = true;
        TrackpadRightClick = true;
      };
      
      "com.apple.AppleMultitouchTrackpad" = {
        TrackpadThreeFingerDrag = true;
        TrackpadRightClick = true;
      };

      "com.apple.driver.AppleBluetoothMultitouch.trackpad" = {
        TrackpadThreeFingerDrag = true;
        TrackpadRightClick = true;
      };
    } else if hostname == "hank-mstio" then {
      # Mac Studio specific settings
      "com.apple.mouse" = {
        scaling = 2.0;
        MouseButtonMode = "TwoButton";
      };
    } else {});

  # System-wide environment variables
  environment.variables = {
    # Common variables
    EDITOR = "nvim";
    VISUAL = "nvim";
    PAGER = "less -R";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";

    # Host-specific variables
    } // (if hostname == "hank-mbp" then {
      # MacBook Pro specific variables
      LAPTOP = "1";
    } else if hostname == "hank-mstio" then {
      # Mac Studio specific variables
      DESKTOP = "1";
    } else {});

  # System-wide shell aliases
  environment.shellAliases = {
    # Common aliases
    ls = "eza --icons";
    ll = "eza -l --icons";
    la = "eza -la --icons";
    cat = "bat";
    
    # Host-specific aliases
    } // (if hostname == "hank-mbp" then {
      # MacBook Pro specific aliases
      battery = "pmset -g batt";
      power = "system_profiler SPPowerDataType";
    } else if hostname == "hank-mstio" then {
      # Mac Studio specific aliases
      studio = "system_profiler SPHardwareDataType";
    } else {});
}
