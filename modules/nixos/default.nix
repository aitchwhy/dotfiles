# NixOS module aggregator
# Provides system configuration for cloud/remote Linux hosts
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkDefault;
in
{
  imports = [
    ./system.nix
    ./security.nix
    ./users.nix
    ./services/sshd.nix
    ./services/tailscale.nix
    ./services/docker.nix
  ];

  config = {
    # System identification
    system.stateVersion = mkDefault "24.11";

    # Enable Nix flakes
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
    };

    # Timezone (US East for cloud-dev)
    time.timeZone = mkDefault "America/New_York";

    # Locale
    i18n.defaultLocale = mkDefault "en_US.UTF-8";

    # Console configuration
    console = {
      font = "Lat2-Terminus16";
      keyMap = mkDefault "us";
    };

    # Essential packages for remote development
    environment.systemPackages = with pkgs; [
      # Editors
      neovim
      helix

      # Shell utilities
      git
      curl
      wget
      htop
      btop
      tree
      fd
      ripgrep
      jq
      yq-go

      # Networking
      mtr
      dnsutils
      inetutils

      # System
      pciutils
      usbutils
      lsof

      # Compression
      gzip
      unzip
      zstd

      # Development
      gnumake
      gcc

      # Nix tools
      nix-tree
      nix-output-monitor
    ];

    # Programs
    programs = {
      zsh.enable = true;
      git.enable = true;
      mosh.enable = true;
      tmux.enable = true;
    };
  };
}
