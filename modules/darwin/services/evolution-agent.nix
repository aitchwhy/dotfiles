# Evolution Agent - Background health monitoring for dotfiles
# Runs as a user agent (not system daemon) to access user files
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  cfg = config.modules.darwin.evolutionAgent;
in
{
  options.modules.darwin.evolutionAgent = {
    enable = mkEnableOption "Evolution health monitoring agent";

    interval = mkOption {
      type = types.int;
      default = 3600;
      description = "Health check interval in seconds (default: 1 hour)";
    };
  };

  config = mkIf cfg.enable {
    # User-level LaunchAgent (runs as the user, not root)
    launchd.user.agents.evolution-health = {
      serviceConfig = {
        Label = "com.dotfiles.evolution-health";
        ProgramArguments = [
          "${pkgs.bash}/bin/bash"
          "-c"
          ''
            export PATH="${pkgs.jq}/bin:${pkgs.coreutils}/bin:${pkgs.nix}/bin:$PATH"
            export DOTFILES="$HOME/dotfiles"
            export METRICS_DIR="$HOME/.claude-metrics"
            export HEALTH_MONITOR_INTERVAL="${toString cfg.interval}"
            exec "$DOTFILES/scripts/health-monitor.sh"
          ''
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/evolution-health.log";
        StandardErrorPath = "/tmp/evolution-health.err";
        EnvironmentVariables = {
          HOME = "/Users/hank";
          DOTFILES = "/Users/hank/dotfiles";
        };
      };
    };
  };
}
