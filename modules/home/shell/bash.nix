# Bash shell configuration
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.modules.home.shell.bash = {
    enable = mkEnableOption "Bash shell configuration";
  };

  config = mkIf config.modules.home.shell.bash.enable {
    programs.bash = {
      enable = true;
      enableCompletion = true;
    };
  };
}
