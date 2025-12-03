# Htop process viewer configuration
{ config, lib, ... }:

with lib;

{
  options.modules.home.tools.htop = {
    enable = mkEnableOption "htop process viewer";
  };

  config = mkIf config.modules.home.tools.htop.enable {
    programs.htop = {
      enable = true;
      settings = {
        show_program_path = false;
        tree_view = true;
        sort_key = 46; # PERCENT_CPU
        sort_direction = -1;
        hide_kernel_threads = true;
        hide_userland_threads = true;
        shadow_other_users = false;
        highlight_base_name = true;
        highlight_megabytes = true;
        highlight_threads = true;
        detailed_cpu_time = false;
        cpu_count_from_one = true;
        show_cpu_usage = true;
        show_cpu_frequency = false;
        update_process_names = false;
        account_guest_in_cpu_meter = false;
        color_scheme = 0;
        enable_mouse = true;
        delay = 15;
      };
    };
  };
}
