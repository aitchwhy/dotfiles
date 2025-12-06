# macOS system-wide defaults
{ config, lib, ... }:

with lib;

{
  options.modules.darwin.system = {
    enable = mkEnableOption "macOS system defaults";

    interfaceStyle = mkOption {
      type = types.enum [ "Light" "Dark" "Auto" ];
      default = "Dark";
      description = "macOS interface style";
    };
  };

  config = mkIf config.modules.darwin.system.enable {
    # Security
    security.pam.services.sudo_local.touchIdAuth = true;

    # System behavior
    system.startup.chime = false;

    # Login window
    system.defaults.loginwindow = {
      GuestEnabled = false;
      SHOWFULLNAME = true;
      LoginwindowText = "";
      DisableConsoleAccess = true;
    };

    # Global defaults
    system.defaults.NSGlobalDomain = {
      # UI/UX
      AppleInterfaceStyle = config.modules.darwin.system.interfaceStyle;
      AppleKeyboardUIMode = 3;
      AppleShowAllExtensions = true;
      AppleShowScrollBars = "Always";
      "com.apple.swipescrolldirection" = true;
      "com.apple.sound.beep.feedback" = 0;

      # Keyboard behavior
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 15;  # was 10 (fastest) - more reasonable delay
      KeyRepeat = 2;          # was 1 (fastest) - still fast but less aggressive

      # Text input
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;

      # Performance
      NSAutomaticWindowAnimationsEnabled = false;
      NSWindowResizeTime = 0.001;
      NSWindowShouldDragOnGesture = true;

      # Save panels
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;
      NSDocumentSaveNewDocumentsToCloud = false;

      # Developer
      NSTextShowsControlCharacters = true;
    };

    # Menu bar clock
    system.defaults.menuExtraClock = {
      IsAnalog = false;
      Show24Hour = true;
      ShowAMPM = false;
      ShowDate = 1;
      ShowDayOfMonth = true;
      ShowDayOfWeek = true;
    };

    # NOTE: Screenshots moved to screenshots.nix
    # NOTE: Spaces moved to spaces.nix
    # NOTE: Window Manager moved to window-manager.nix

    # Disable ads
    system.defaults.CustomUserPreferences."com.apple.AdLib" = {
      allowApplePersonalizedAdvertising = false;
    };

    # macOS Tahoe 26 - Spotlight clipboard history
    system.defaults.CustomUserPreferences."com.apple.Spotlight" = {
      ClipboardHistoryEnabled = true;
    };

    # Screensaver
    system.defaults.CustomUserPreferences."com.apple.screensaver" = {
      askForPassword = 1;
      askForPasswordDelay = 0;
    };

    # Disable image capture hotplug
    system.defaults.CustomUserPreferences."com.apple.ImageCapture".disableHotPlug = true;

    # Other defaults
    # NOTE: AppleSpacesSwitchOnActivate moved to spaces.nix
    system.defaults.CustomUserPreferences.".GlobalPreferences" = {
      WebAutomaticTextReplacementEnabled = false;
      WebContinuousSpellCheckingEnabled = false;
      WebAutomaticSpellingCorrectionEnabled = false;
    };

    # Disable quarantine
    system.defaults.LaunchServices.LSQuarantine = false;
  };
}
