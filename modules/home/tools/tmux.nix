# Tmux terminal multiplexer configuration
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
in {
  options.modules.home.tools.tmux = {
    enable = mkEnableOption "tmux configuration";

    prefix = mkOption {
      type = types.str;
      default = "C-a";
      description = "Tmux prefix key";
    };
  };

  config = mkIf config.modules.home.tools.tmux.enable {
    programs.tmux = {
      enable = true;
      baseIndex = 1;
      clock24 = true;
      escapeTime = 0;
      historyLimit = 50000;
      keyMode = "vi";
      mouse = true;
      terminal = "screen-256color";

      prefix = config.modules.home.tools.tmux.prefix;

      extraConfig = ''
        # Better colors
        set -ga terminal-overrides ",*256col*:Tc"

        # Faster key repetition
        set -sg repeat-time = 0

        # Focus events
        set -g focus-events on

        # Status bar
        set -g status-position top
        set -g status-style 'bg=#1e1e2e fg=#cdd6f4'
        set -g status-left-length 20

        # Easy split panes
        bind | split-window -h
        bind - split-window -v
      '';
    };
  };
}
