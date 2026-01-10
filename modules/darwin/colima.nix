# Colima container runtime for macOS
# Uses launchd for automatic startup - no manual `colima start` needed
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  cfg = config.modules.darwin.colima;
in
{
  options.modules.darwin.colima = {
    enable = mkEnableOption "Colima container runtime with VZ";

    cpu = mkOption {
      type = types.int;
      default = 6;
      description = "Number of CPU cores for the VM";
    };

    memory = mkOption {
      type = types.int;
      default = 16;
      description = "Memory in GB for the VM";
    };

    disk = mkOption {
      type = types.int;
      default = 60;
      description = "Disk size in GB for the VM";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.cpu >= 1 && cfg.cpu <= 16;
        message = "Colima cpu must be between 1 and 16";
      }
      {
        assertion = cfg.memory >= 2 && cfg.memory <= 64;
        message = "Colima memory must be between 2GB and 64GB";
      }
      {
        assertion = cfg.disk >= 10 && cfg.disk <= 500;
        message = "Colima disk must be between 10GB and 500GB";
      }
    ];

    # Colima launchd user agent - starts on login
    launchd.user.agents.colima = {
      serviceConfig = {
        Label = "com.github.abiosoft.colima";
        ProgramArguments = [
          "/opt/homebrew/bin/colima"
          "start"
          "--foreground"
          "--vm-type"
          "vz"
          "--mount-type"
          "virtiofs"
          "--network-address"
          "--cpu"
          (toString cfg.cpu)
          "--memory"
          (toString cfg.memory)
          "--disk"
          (toString cfg.disk)
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/colima.stdout.log";
        StandardErrorPath = "/tmp/colima.stderr.log";
        EnvironmentVariables = {
          PATH = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };
      };
    };
  };
}
