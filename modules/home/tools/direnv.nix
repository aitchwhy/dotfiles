# Direnv configuration
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.modules.home.tools.direnv = {
    enable = mkEnableOption "direnv";
  };

  config = mkIf config.modules.home.tools.direnv.enable {
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;

      stdlib = ''
        layout_uv() {
          if [[ -d ".venv" ]]; then
            VIRTUAL_ENV="$(pwd)/.venv"
          fi

          if [[ -z $VIRTUAL_ENV || ! -d $VIRTUAL_ENV ]]; then
            log_status "No virtual environment exists. Executing \`uv venv\` to create one."
            uv venv
            VIRTUAL_ENV="$(pwd)/.venv"
          fi

          PATH_add "$VIRTUAL_ENV/bin"
          export UV_ACTIVE=1
          export VIRTUAL_ENV
        }

        # Pulumi ESC integration
        use_esc() {
          local env="$1"

          if ! has esc; then
            log_status "esc CLI not found, skipping ESC integration"
            return 0
          fi

          log_status "Loading ESC environment: $env"
          local output
          output=$(esc open "$env" --format shell 2>&1)
          local exit_code=$?

          if [[ $exit_code -ne 0 ]]; then
            if [[ "$output" == *"unauthorized"* ]] || [[ "$output" == *"401"* ]]; then
              log_error "Not logged into Pulumi ESC. Run: esc login"
            else
              log_error "Failed to load ESC environment: $env"
              log_error "$output"
            fi
            return 1
          fi

          eval "$output"
        }
      '';
    };
  };
}
