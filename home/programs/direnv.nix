{ config, pkgs, ... }:

{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;

    stdlib = ''
      # Uncomment to debug direnv
      # export DIRENV_LOG_FORMAT=""

      # Layout for Python
      layout_python() {
        local python=''${1:-python3}
        local venvPath="''${2:-$PWD/.direnv/python-venv}"

        if [[ ! -d "$venvPath" ]]; then
          log_status "Creating virtual environment..."
          $python -m venv "$venvPath"
        fi

        source "$venvPath/bin/activate"
        export VIRTUAL_ENV="$venvPath"
      }

      # Layout for Node.js
      layout_node() {
        local node_version=''${1:-18}
        local node_modules="$PWD/node_modules"
        local bin="$node_modules/.bin"

        PATH_add "$bin"
        export NODE_PATH="$node_modules:$NODE_PATH"
      }

      # Layout for Go
      layout_go() {
        local gopath="$PWD/.direnv/go"
        export GOPATH="$gopath"
        PATH_add "$gopath/bin"
      }

      # Layout for Rust
      layout_rust() {
        local cargo_home="$PWD/.direnv/cargo"
        local rustup_home="$PWD/.direnv/rustup"

        export CARGO_HOME="$cargo_home"
        export RUSTUP_HOME="$rustup_home"
        PATH_add "$cargo_home/bin"
      }

      # Safer handling of temporary files
      : ''${XDG_CACHE_HOME:=$HOME/.cache}
      declare -A direnv_layout_dirs
      direnv_layout_dir() {
        local hash="$(sha1sum - <<< "$PWD" | cut -c-7)"
        local path="''${direnv_layout_dirs[$hash]:=$XDG_CACHE_HOME/direnv/layouts/$hash}"
        mkdir -p "$path"
        echo "$path"
      }

      # Enhanced use_nix with flakes support
      use_flake() {
        watch_file flake.nix
        watch_file flake.lock
        eval "$(nix print-dev-env --profile "$(direnv_layout_dir)/flake-profile")"
      }

      # Load .env files
      dotenv() {
        local envfile="$1"
        if [[ ! -f "$envfile" ]]; then
          log_error ".env file '$envfile' not found"
          return 1
        fi
        eval "$(
          set -o allexport
          source "$envfile"
          set +o allexport
          declare -x |
            sed -n "s/^declare -x \\([^=]\\+\\)=\\(.\\+\\)\$/export \\1=\\2/p" |
            sed "s/'\\\\''/'/g"
        )"
      }

      # Load environment variables from .env file if it exists
      if [[ -f .env ]]; then
        dotenv .env
      fi

      # Automatically use flake.nix if it exists
      if [[ -f flake.nix ]]; then
        use flake
      fi
    '';

    config = {
      global = {
        strict_env = true;
        warn_timeout = "1m";
      };
      whitelist = {
        prefix = [
          "$HOME/Projects"
          "$HOME/Work"
          "$HOME/Documents"
        ];
        exact = [ "$HOME/.config/nix" ];
      };
    };
  };

  # Install additional tools that might be useful with direnv
  home.packages = with pkgs; [
    # For Python virtual environments
    python311
    virtualenv

    # For Node.js development
    nodejs_20
    yarn

    # For Go development
    go

    # For Rust development
    rustup

    # Additional tools
    envsubst # For environment variable substitution
    shellcheck # For shell script linting
  ];
}
