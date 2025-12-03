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
      InitialKeyRepeat = 10;
      KeyRepeat = 1;

      # Text input
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      # NSAutomaticTextCompletionEnabled = false; # TODO: Find correct option name

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
      # WebKitDeveloperExtras = true; # TODO: Find correct option name
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

    # Screenshots
    system.defaults.CustomUserPreferences."com.apple.screencapture" = {
      location = "~/Desktop/Screenshots";
      type = "png";
      disable-shadow = true;
      include-date = true;
    };

    # Disable ads
    system.defaults.CustomUserPreferences."com.apple.AdLib" = {
      allowApplePersonalizedAdvertising = false;
    };

    # Spaces
    system.defaults.CustomUserPreferences."com.apple.spaces" = {
      "spans-displays" = 0;
      "mru-spaces" = false;
    };

    # Window Manager
    system.defaults.CustomUserPreferences."com.apple.WindowManager" = {
      EnableStandardClickToShowDesktop = 0;
      StandardHideDesktopIcons = 0;
      HideDesktop = 0;
      StageManagerHideWidgets = 0;
      StandardHideWidgets = 0;
      GloballyEnabled = false;
    };

    # Screensaver
    system.defaults.CustomUserPreferences."com.apple.screensaver" = {
      askForPassword = 1;
      askForPasswordDelay = 0;
    };

    # Disable image capture hotplug
    system.defaults.CustomUserPreferences."com.apple.ImageCapture".disableHotPlug = true;

    # Other defaults
    system.defaults.CustomUserPreferences.".GlobalPreferences" = {
      AppleSpacesSwitchOnActivate = true;
      WebAutomaticTextReplacementEnabled = false;
      WebContinuousSpellCheckingEnabled = false;
      WebAutomaticSpellingCorrectionEnabled = false;
    };

    # Disable quarantine
    system.defaults.LaunchServices.LSQuarantine = false;
  };
}
