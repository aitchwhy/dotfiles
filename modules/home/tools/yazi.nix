# Yazi file manager configuration
# De-vendored: plugins fetched via flake inputs (December 2025)
{
  config,
  lib,
  inputs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  yaziConfig = ../../../config/yazi;
in {
  options.modules.home.tools.yazi = {
    enable = mkEnableOption "yazi file manager";
  };

  config = mkIf config.modules.home.tools.yazi.enable {
    programs.yazi = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
    };

    # Configuration files (TOML + Lua)
    xdg.configFile = {
      "yazi/yazi.toml".source = "${yaziConfig}/yazi.toml";
      "yazi/keymap.toml".source = "${yaziConfig}/keymap.toml";
      "yazi/theme.toml".source = "${yaziConfig}/theme.toml";
      "yazi/init.lua".source = "${yaziConfig}/init.lua";
      "yazi/package.toml".source = "${yaziConfig}/package.toml";

      # Official yazi-rs plugins (from single repo)
      "yazi/plugins/smart-enter.yazi".source = "${inputs.yazi-plugins}/smart-enter.yazi";
      "yazi/plugins/diff.yazi".source = "${inputs.yazi-plugins}/diff.yazi";
      "yazi/plugins/full-border.yazi".source = "${inputs.yazi-plugins}/full-border.yazi";
      "yazi/plugins/jump-to-char.yazi".source = "${inputs.yazi-plugins}/jump-to-char.yazi";
      "yazi/plugins/mactag.yazi".source = "${inputs.yazi-plugins}/mactag.yazi";
      "yazi/plugins/mime-ext.yazi".source = "${inputs.yazi-plugins}/mime-ext.yazi";
      "yazi/plugins/mount.yazi".source = "${inputs.yazi-plugins}/mount.yazi";
      "yazi/plugins/piper.yazi".source = "${inputs.yazi-plugins}/piper.yazi";
      "yazi/plugins/smart-filter.yazi".source = "${inputs.yazi-plugins}/smart-filter.yazi";
      "yazi/plugins/toggle-pane.yazi".source = "${inputs.yazi-plugins}/toggle-pane.yazi";
      "yazi/plugins/vcs-files.yazi".source = "${inputs.yazi-plugins}/vcs-files.yazi";

      # Third-party plugins (individual repos)
      "yazi/plugins/relative-motions.yazi".source = inputs.yazi-relative-motions;
      "yazi/plugins/bunny.yazi".source = inputs.yazi-bunny;
      "yazi/plugins/projects.yazi".source = inputs.yazi-projects;
      "yazi/plugins/ouch.yazi".source = inputs.yazi-ouch;
      "yazi/plugins/lazygit.yazi".source = inputs.yazi-lazygit;
      "yazi/plugins/what-size.yazi".source = inputs.yazi-what-size;
      "yazi/plugins/copy-file-contents.yazi".source = "${inputs.yazi-copy-file-contents}/copy-file-contents.yazi";
      "yazi/plugins/open-with-cmd.yazi".source = inputs.yazi-open-with-cmd;
      "yazi/plugins/starship.yazi".source = inputs.yazi-starship;
      "yazi/plugins/glow.yazi".source = inputs.yazi-glow;
      "yazi/plugins/rich-preview.yazi".source = inputs.yazi-rich-preview;

      # Custom plugins (no upstream, kept locally)
      "yazi/plugins/folder-rules.yazi".source = "${yaziConfig}/plugins/folder-rules.yazi";
      "yazi/plugins/smart-paste.yazi".source = "${yaziConfig}/plugins/smart-paste.yazi";

      # Flavors (themes)
      "yazi/flavors/ashen.yazi".source = "${inputs.yazi-flavor-ashen}/ashen.yazi";
      "yazi/flavors/tokyo-night.yazi".source = inputs.yazi-flavor-tokyo-night;
    };
  };
}
