# -*- mode: justfile -*-

# ==============================================================================
# User-Level Justfile
# ==============================================================================
# Purpose: Provides common development tasks, system management shortcuts,
#          and project-specific helpers accessible globally.
# Invocation: Typically run via an alias like `alias j='just -f ~/.user.justfile'`
#             or directly `just -f ~/.user.justfile <recipe> [args...]`
# Docs: https://just.systems/man/en/
# ==============================================================================

# --- Settings ---
# (https://just.systems/man/en/settings.html)

# Enable experimental features (required for `fmt`, `group` attribute etc.)
set unstable := true

# Allow passing arguments directly after recipe name: `just recipe arg1 arg2`
set positional-arguments := true

# Use zsh for executing recipes. -c: read commands from string, -u: treat unset variables as errors.
set shell := ["zsh", "-cu"]

# # Optional: Load environment variables from a .env file in the justfile's directory
# set dotenv-load := true
# set dotenv-filename := ".env"

# Optional: By default, recipes run in the justfile's directory.
# Set a different default working directory if desired (e.g., home directory).
# set working-directory := '~/'

# --- Global Variables & Constants ---

# !!! IMPORTANT: Set your actual hostname for Nix Darwin recipes !!!
# hostname            := "your-hostname-here"

# Common Project Paths (using ~ which `shell` setting should expand)
# platform_dir        := "~/src/platform"
# flonotes_fe_dir     := "~/src/flonotes-fe"
# vibes_dir           := "~/src/vibes"
# gpt_repo_dir        := "~/src/gpt-repository-loader"

# --- Default & Utility Recipes ---

# Default action
[group('global')]
[working-directory: '~/dotfiles/config/just']
default:
    @just --list --unsorted

# Interactively choose a recipe to run
[group('global')]
[working-directory: '~/dotfiles/config/just']
choose:
    @just --choose


# Format *this* user Justfile
[group('global')]
[working-directory: '~/dotfiles/config/just']
fmt:
    @echo "Formatting {{ justfile() }}..."
    @just --unstable --fmt

# Check formatting of *this* user Justfile
check-fmt: fmt-check
[group('global')]
[working-directory: '~/dotfiles/config/just']
fmt-check:
    @echo "Checking formatting of {{ justfile() }}..."
    @just --unstable --fmt --check
#
# --- Flonotes / Ant Project Specifics ---
# Recipes related to the Flonotes/Ant projects.
# Consider moving these to a project-local Justfile if they become too numerous
# or are only ever run from within those project directories.

# Run Noggin service (Platform)
[group('platform')]
[working-directory: '~/src/platform']
noggin-up:
    @echo "Building and starting Noggin service..."
    ant build noggin && ant up noggin

# Run core Platform services (Platform)
[group('platform')]
[working-directory: '~/src/platform']
platform-up:
    @echo "Building and starting Platform services..."
    ant build api user s3 prefect-worker prefect-agent prefect-server data-seeder && \
    ant up api user s3 prefect-worker prefect-agent prefect-server data-seeder

# Get OTP code from 'api' container logs
[group('platform')] # Doesnt need a specific working directory
[working-directory: '~/src/platform']
platform-otp:
    @echo "Fetching OTP code from container named 'api'..."
    @_container_id=$$(docker ps -qf name=api); \
    if [ -n "$$_container_id" ]; then \
        docker logs "$$_container_id" 2>&1 | rg "sent an otp code" | tail -n 1; \
    else \
        echo "Error: Container 'api' not found."; exit 1; \
    fi

# Run Noggin e2e tests using Docker Compose
[group('platform')] # Assumes docker compose files are accessible from invocation directory or uses absolute paths
[working-directory: '~/src/platform']
platform-noggin-test:
    @echo "Running Noggin e2e tests..."
    docker compose \
        --profile test-e2e \
        --file compose.integration.yaml \
        run \
        --build \
        --rm \
        --env $ANTHROPIC_API_KEY \
        noggin-test-e2e

# build Flonotes Frontend to static assets to S3 for Noggin
[group('flonotes')]
[working-directory: '~/src/flonotes-fe']
flonotes-fe-build:
    @echo "Deploying Flonotes Frontend locally..."
    make deploy-local # Assumes Makefile exists and `deploy-local` target is defined


# --- Nix Environment Management ---
# Recipes related to Nix package manager and Flakes

# # Update all Nix flake inputs in the current directory's flake.lock
# [group('Nix'), no-cd] # Run in the directory where `just` was invoked
# nix:update:all:
#     @echo "Updating all Nix flake inputs in $(pwd)..."
#     nix flake update
#
# # Update a specific Nix flake input in the current directory
# # Usage: just nix:update:input nixpkgs
# [group('Nix'), no-cd] # Run in the directory where `just` was invoked
# nix:update:input input:
#     @echo "Updating Nix flake input '{{input}}' in $(pwd)..."
#     nix flake update --update-input {{input}}
#
# # Show Nix system profile history
# [group('Nix')]
# nix:history:
#     @echo "Nix system profile history:"
#     nix profile history --profile /nix/var/nix/profiles/system
#
# # Open a Nix REPL using the flake's nixpkgs input (useful for debugging)
# [group('Nix'), no-cd] # Run in the directory where `just` was invoked
# nix:repl:
#     @echo "Opening Nix REPL for flake in $(pwd) (using nixpkgs input)..."
#     nix repl '.#nixpkgs' # Or just `nix repl` if context is enough
#
# # Clean old Nix system profile generations (older than 7 days)
# [group('Nix')]
# nix:clean:profile:
#     @echo "Cleaning Nix system profile generations older than 7 days (requires sudo)..."
#     sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 7d
#
# # Garbage collect Nix store (system and user)
# [group('Nix')]
# nix:gc:
#     @echo "Running Nix garbage collection (older than 7 days)..."
#     @echo "System GC (requires sudo)..."
#     sudo nix-collect-garbage --delete-older-than 7d
#     @echo "User GC..."
#     nix-collect-garbage --delete-older-than 7d
#
# # Format Nix files in the current directory
# [group('Nix'), no-cd] # Run in the directory where `just` was invoked
# nix:fmt:
#     @echo "Formatting Nix files in $(pwd)..."
#     nix fmt .
#
# # List Nix garbage collection roots
# [group('Nix')]
# nix:gcroot:
#     @echo "Nix auto GC roots:"
#     ls -al /nix/var/nix/gcroots/auto/
#
#
# # --- Darwin System Management (using Nix) ---
# # Recipes specific to managing a macOS system via nix-darwin
#
# # [private] Helper to set network proxy if needed for builds.
# # Prefixing with `_` makes it hidden from `just --list` by default.
# # You might need to adjust the script path.
# _darwin-set-proxy:
#     @echo "Setting Darwin network proxy (requires sudo)..."
#     sudo python3 {{ justfile_directory() }}/scripts/darwin_set_proxy.py # Assumes script relative to justfile
#
# # Build and switch Darwin configuration using the hostname variable
# [group('Darwin')]
# darwin:build: _darwin-set-proxy # This recipe depends on the proxy helper
#     @echo "Building Darwin configuration for '{{hostname}}'..."
#     nix build ".#darwinConfigurations.{{hostname}}.system" \
#         --extra-experimental-features 'nix-command flakes'
#     @echo "Switching to new Darwin configuration..."
#     ./result/sw/bin/darwin-rebuild switch --flake ".#{{hostname}}"
#
# # Build and switch Darwin configuration with verbose debug output
# [group('Darwin')]
# darwin:build-debug: _darwin-set-proxy
#     @echo "Building Darwin configuration for '{{hostname}}' (DEBUG)..."
#     nix build ".#darwinConfigurations.{{hostname}}.system" --show-trace --verbose \
#         --extra-experimental-features 'nix-command flakes'
#     @echo "Switching to new Darwin configuration (DEBUG)..."
#     ./result/sw/bin/darwin-rebuild switch --flake ".#{{hostname}}" --show-trace --verbose
#
# # ==============================================================================
# # End of User Justfile
# # ==============================================================================
# # Remember to update the `hostname` variable!
# # Consider creating project-local Justfiles for recipes only relevant within
# # a specific project directory (e.g., `~/src/platform/justfile`).
# # ==============================================================================
#
#
# ##########3
# # Settings (https://just.systems/man/en/settings.html)
# set unstable := true
# # set cmd used for invoking recipes + eval backticks
# # zsh -c : exec command
# set shell := ["zsh", "-cu"]
#
# # Global Justfile
# # just --global-justfile, or just -g for short, searches the following paths, in-order, for a justfile:
# #
# #
# # $XDG_CONFIG_HOME/just/justfile
# # $HOME/.config/just/justfile
# # $HOME/justfile
# # $HOME/.justfile
#
#
# # By default, recipes run with the working directory set to the directory that contains the justfile.
# # The [no-cd] attribute can be used to make recipes run with the working directory set to directory in which just was invoked.
#
# # https://just.systems/man/en/global-and-user-justfiles.html?highlight=user#global-and-user-justfiles
# # for recipe in `just --justfile ~/.user.justfile --summary`; do
# #   alias $recipe="just --justfile ~/.user.justfile --working-directory . $recipe"
# # done
#
# # alias .j='just --justfile ~/.user.justfile --working-directory .'
# #
# #
# # You can override the working directory for all recipes with set working-directory := '…':
#
#
# # List available commands
# default:
#   @just --choose
#
#
# ls:
#   @just --list --unsorted
#
# fmt:
#   @just --unstable --fmt
#
# fmtcheck:
#   @just --unstable --fmt --check
#
#
# run-noggin:
#   cd ~/src/platform && \
#     ant build noggin && \
#     ant up noggin
#
# run-platform:
#   cd ~/src/platform && \
#     ant build api user s3 prefect-worker prefect-agent prefect-server data-seeder && \
#     ant up api user s3 prefect-worker prefect-agent prefect-server data-seeder
#
# ##################
# # TODO(hank): clone of existing Makefile targets. Migrate to this if possible after checking with team.
#
# # Run the development server with hot reloading
# run:
#   npm run dev --hot
#
# # Get OTP codes from Docker logs (outputs only the 4-digit code)
# get-otp:
#   docker logs "$(docker container ls | rg 'api' | awk '{print $1}')" | rg "sent an otp code"
#
# # Setup project
# setup:
#   npm install
#   npm run build
#
# # Deploy to local environment
# deploy-local:
#   ./deploy-local.sh http://localhost:59000
#
# # Deploy to AWS
# deploy-aws profile bucket noggin_url:
#   ./deploy-aws.sh {{ profile }} {{ bucket }} {{ noggin_url }}
#
# ##################
#
#
# # just is a command runner, Justfile is very similar to Makefile, but simpler.
# # TODO update hostname here!
#
# hostname := "your-hostname"
#
# # Flonotes Frontend variables and settings
#
# # List all the just commands
# default:
#     @just --list
#
# x:
#     @just --choose
#
# ############################################################################
# #
# #  Darwin related commands
# #
# ############################################################################
#
# # TODO Feel free to remove this target if you don't need a proxy to speed up the build process
# [group('desktop')]
# darwin-set-proxy:
#     sudo python3 scripts/darwin_set_proxy.py
#
# [group('desktop')]
# darwin: darwin-set-proxy
#     nix build .#darwinConfigurations.{{ hostname }}.system \
#       --extra-experimental-features 'nix-command flakes'
#
#     ./result/sw/bin/darwin-rebuild switch --flake .#{{ hostname }}
#
# [group('desktop')]
# darwin-debug: darwin-set-proxy
#     nix build .#darwinConfigurations.{{ hostname }}.system --show-trace --verbose \
#       --extra-experimental-features 'nix-command flakes'
#
#     ./result/sw/bin/darwin-rebuild switch --flake .#{{ hostname }} --show-trace --verbose
#
#
#
# ############################################################################
# # Flonotes Frontend commands
# ############################################################################
# # Path variables for Flonotes development
#
# ant-platform := "~/src/platform"
# ant-flonotes_fe := "~/src/flonotes-fe"
# ant-vibes := "~/src/vibes"
# gpt-repo := "~/src/gpt-repository-loader"
#
# # Setup project
# [group('ant')]
# [working-directory('~/src/flonotes-fe')]
# setup:
#     ant build
#     npm install && npm run build
#
# [group('ant')]
# [working-directory('~/src/platform')]
# run-noggin: deploy-local
#     ant build noggin && ant up noggin
#
# [group('ant')]
# [working-directory('~/src/platform')]
# run-platform:
#     ant build api user s3 prefect-worker prefect-agent prefect-server data-seeder && \
#     ant up api user s3 prefect-worker prefect-agent prefect-server data-seeder
#
# # Run the development server with hot reloading
# [group('ant')]
# [working-directory('~/src/platform')]
# run:
#     npm run dev --hot
#
# # Test e2e on localhost Docker
# [group('ant')]
# test-e2e:
#     docker compose \
#       --profile test-e2e \
#       --file compose.integration.yaml \
#       run \
#       --build \
#       --rm \
#       --env ANTHROPIC_API_KEY \
#       noggin-test-e2e
#
# # Get OTP codes from Docker logs (outputs only the 4-digit code)
# [group('ant')]
# get-otp:
#     docker logs "$(docker container ls | rg 'api' | awk '{print $1}')" | rg "sent an otp code"
#
# # Deploy to local environment
# [group('ant')]
# [working-directory('~/src/flonotes-fe')]
# deploy-local:
#     make deploy-local
#
# # Deploy to AWS
# [group('ant')]
# deploy-aws profile bucket noggin_url:
#     cd {{ flonotes_fe }} && \
#     $(pwd)/{{ justfile_directory() }}/scripts/anterior/deploy-aws.sh {{ profile }} {{ bucket }} {{ noggin_url }}


# ############################################################################
# #
# #  nix related commands
# #
# ############################################################################

# # Update all the flake inputs
# [group('nix')]
# up:
#     nix flake update

# # Update specific input

# # Usage: just upp nixpkgs
# [group('nix')]
# upp input:
#     nix flake update {{ input }}

# # List all generations of the system profile
# [group('nix')]
# history:
#     nix profile history --profile /nix/var/nix/profiles/system

# # Open a nix shell with the flake
# [group('nix')]
# repl:
#     nix repl -f flake:nixpkgs

# # remove all generations older than 7 days

# # on darwin, you may need to switch to root user to run this command
# [group('nix')]
# clean:
#     sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

# # Garbage collect all unused nix store entries
# [group('nix')]
# gc:
#     # garbage collect all unused nix store entries(system-wide)
#     sudo nix-collect-garbage --delete-older-than 7d
#     # garbage collect all unused nix store entries(for the user - home-manager)
#     # https://github.com/NixOS/nix/issues/8508
#     nix-collect-garbage --delete-older-than 7d

# [group('nix')]
# fmt:
#     # format the nix files in this repo
#     nix fmt

# # Show all the auto gc roots in the nix store
# [group('nix')]
# gcroot:
#     ls -al /nix/var/nix/gcroots/auto/

# # # TODO: parallel jobs 
# # parallel:
# #   #!/usr/bin/env -S parallel --shebang --ungroup --jobs {{ num_cpus() }}
# #   echo task 1 start; sleep 3; echo task 1 done
# #   echo task 2 start; sleep 3; echo task 2 done
# #   echo task 3 start; sleep 3; echo task 3 done
# #   echo task 4 start; sleep 3; echo task 4 done


# # # TODO: now just a soft symlink but .user.justfile should be real life in $HOME/.user.justfile
# #
# #
# # ############################################################
# # # Justfile docs - https://just.systems/man/en/
# # # Justfile tips - https://www.stuartellis.name/articles/just-task-runner/
# # # Justfile cheatsheet https://cheatography.com/linux-china/cheat-sheets/justfile/
# # ############################################################
# #
# # ############################################################
# # # Justfile settings (https://just.systems/man/en/chapter_26.html)
# # # TODO: [no-cd] recipe attribute -> if mod imported use parent cwd instead of child path (https://just.systems/man/en/chapter_32.html#disabling-changing-directory190)
# # ############################################################
# #
# # ############################################################
# # # Justfile exporter (https://just.systems/man/en/chapter_74.html)
# # ############################################################
# # # Justfile compat with NodeJS+package.json
# # export PATH := "./node_modules/.bin:" + env_var('PATH')
# #
# # ############################################################
# # # Justfile imports (other justfiles + modules)
# # # - modules : https://just.systems/man/en/chapter_54.html
# # ############################################################
# # # import 'asdf/justfile'
# # # mod 'modNameFolderName' 'module path'
# #
# # # set dotenv-filename := ".env.local"
# #
# # # use dotfiles/.export.sh to set these env vars (or use default)
# # # user_justfile_name := env_var('USER_JUSTFILE_NAME', ".user.justfile")
# # # user_justfile_path := "{{ home_directory() }}/" + user_justfile_name
# # dotfiles_root_dir := justfile_directory() / "dotfiles"
# # dotfiles_home_root_dir := dotfiles_root_dir / "home"
# # dotenvx_root_dir := dotfiles_root_dir / "dotenvx"
# # nvm_root_dir := dotfiles_root_dir / "nvm"
# #
# # # scripts_root_dir := dotfiles_root_dir / "scripts"
# # # chezmoi_root_dir := dotfiles_root_dir / "chezmoi"
# # # webi_root_dir := dotfiles_root_dir / "webi"
# #
# # # List available recipes
# # # (TODO: update to add 2nd user justfile command to run aliased HOME dir user justfile)
# # help:
# #     @echo "dotfiles root dir: {{dotfiles_root_dir}}"
# #     @echo "dotfiles home root dir: {{dotfiles_home_root_dir}}"
# #     @just --unstable --list --unsorted -f "{{dotfiles_home_root_dir}}/.user.justfile"
# #
# # # Display system information
# # system-info:
# #     @echo "CPU architecture: {{ arch() }}"
# #     @echo "Operating system type: {{ os_family() }}"
# #     @echo "Operating system: {{ os() }}"
# #     @echo "Home directory: {{ home_directory() }}"
# #
# #
# # ##################################
# # # global user recipes (cwd = dotfiles root dir)
# # ##################################
# # [no-cd]
# # run-recipe-user:
# #     @just --choose
# #
# # # formats user.justfile and fixed in place
# # [no-cd]
# # fmt-user-justfile:
# #     @just --unstable --fmt
# #
# # # checks user.justfile for syntax errors (return code 0 if no error)
# # [no-cd]
# # fmt-check-user-justfile:
# #     @just --unstable --fmt --check
# #
# # brew-bundle:
# #     @brew bundle --file={{dotfiles_root_dir}}/Brewfile
# #
# # ##################################
# # # Project specific recipes (cwd = project root dir)
# # ##################################
# # run-recipe-curr:
# #     @just --choose
# #
# # # formats user.justfile and fixed in place
# # fmt-curr-justfile:
# #     @just --unstable --fmt
# #
# # # checks curr project justfile for syntax errors (return code 0 if no error)
# # fmt-check-curr-justfile:
# #     @just --unstable --fmt --check
# #
# # init-justfile-current-dir:
# #     @just --init
# #
# #
# #
# #
